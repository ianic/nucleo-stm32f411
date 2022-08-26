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
};

var ticker = chip.ticker();
var blink_speed: u32 = 500;

//------ init
const clock = chip.hsi_100;

const uart1 = uart.Uart1(.{
    .tx = gpio.PA15,
    .rx = gpio.PB7,
    .clock_frequencies = clock.frequencies,
}).Pooling();

pub fn init() void {
    chip.init(.{ .clock = clock });
    board.init(.{});
    uart1.init();
}
//------ init

pub fn main() !void {
    var itv = ticker.interval(blink_speed);

    while (true) {
        if (itv.ready(blink_speed)) {
            board.led.toggle();
        }

        if (uart1.rx.ready()) { // pool receive part for not empty buffer
            const b = uart1.rx.read(); // receive
            uart1.tx.write(b); // transmit (this will block until tx is ready)
        }

        asm volatile ("nop");
    }
}
