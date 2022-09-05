const std = @import("std");
const micro = @import("microzig");
const chip = micro.chip;
const board = micro.board;
const uart = chip.uart;
const gpio = chip.gpio;

pub const interrupts = struct {
    pub fn SysTick() void {
        ticker.inc();
    }

    pub fn EXTI15_10() void {
        if (button.extiPending()) {
            changeBlinkSpeed();
        }
    }

    pub fn USART1() void {
        if (uart1.rx.ready()) { // read data register is not empty
            rb.push(uart1.rx.read()); // read clears RXNE flag
        }
        if (uart1.tx.ready()) { // transmit data register is empty
            if (rb.pop()) |b| {
                uart1.tx.write(b); // write clars TXE flag
            } else {
                uart1.tx.irq.disable(); // disable interrupt because TXE is set and will raise another interrupt if not disabled
            }
        }
    }
};

fn changeBlinkSpeed() void {
    blink_speed = switch (blink_speed) {
        500 => 100,
        100 => 50,
        else => 500,
    };
}

var button: board.Button = undefined;
var blink_speed: u32 = 500;
var ticker = chip.ticker();

const uart1 = uart.Uart1(.{}).interrupt();

pub fn init() void {
    const clock = chip.hsi_100;
    chip.init(.{ .clock = clock });
    button = board.Button.init(.{ .exti = .{ .enable = true } });

    uart1.init(clock.frequencies);
    gpio.usart1.tx.Pa15().init(.{});
    gpio.usart1.rx.Pb7().init(.{});
}

var rb = @import("ring_buffer.zig").RingBuffer(1024).init();

pub fn main() !void {
    var led = board.Led.init(.{});
    var itv = ticker.interval(blink_speed);

    while (true) {
        if (itv.ready(blink_speed)) {
            led.toggle();
        }
        asm volatile ("nop");
    }
}
