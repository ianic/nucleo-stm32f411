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

//------ init
const clock = chip.hsi_100;

const uart1 = uart.Uart1(.{}, clock.frequencies).Pooling();

pub fn init() void {
    chip.init(.{ .clock = clock });
    button = board.Button.init(.{ .exti = .{ .enable = true } });

    uart1.init();
    gpio.usart1.tx.Pa15().init(.{});
    gpio.usart1.rx.Pb7().init(.{});
}
//------ init

pub fn main() !void {
    var led = board.Led.init(.{});
    var itv = ticker.interval(blink_speed);

    while (true) {
        if (itv.ready(blink_speed)) {
            led.toggle();
        }

        if (uart1.rx.ready()) { // read RXNE flag
            const b = uart1.rx.read(); // read rx byte
            uart1.tx.write(b); // transmit (this will block until tx is ready)
        }

        asm volatile ("nop");
    }
}
