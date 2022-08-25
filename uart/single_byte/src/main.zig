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
        if (board.button.irq_pending()) {
            blink_speed = switch (blink_speed) {
                500 => 100,
                100 => 50,
                else => 500,
            };
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

var ticker = chip.ticker();
var blink_speed: u32 = 500;

//------ init
const clock = chip.hsi_100;

const uart1 = uart.Uart1(.{
    .tx = gpio.PA15,
    .rx = gpio.PB7,
    .clock_frequencies = clock.frequencies,
}).Interrupt();

pub fn init() void {
    chip.init(.{ .clock = clock });
    board.init(.{});
    uart1.init();
}
//------ init

var rb = @import("ring_buffer.zig").RingBuffer(1024).init();

pub fn main() !void {
    var itv = ticker.interval(blink_speed);

    while (true) {
        if (itv.ready(blink_speed)) {
            board.led.toggle();
        }
        asm volatile ("nop");
    }
}
