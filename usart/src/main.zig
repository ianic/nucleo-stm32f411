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

const Uart1 = uart.Uart1(.{
    .tx = gpio.PA15,
    .clock_frequencies = clock.frequencies,
});
var uart1: Uart1 = undefined;

pub fn init() void {
    chip.init(.{ .clock = clock });
    board.init(.{});
    uart1 = Uart1.init();
}
//------ init

pub fn main() !void {
    var itv = ticker.interval(blink_speed);
    var buf: [128]u8 = undefined;

    var sendTime: u32 = 0;
    while (true) {
        if (itv.ready(blink_speed)) {
            board.led.toggle();
            const sendStart = ticker.ticks;
            const msg = try std.fmt.bufPrint(buf[0..], "ticks {d}, sendTime: {d} iso medo u ducan\n", .{
                ticker.ticks,
                sendTime,
            });
            for (msg) |ch| {
                uart1.tx(ch);
            }
            sendTime = ticker.ticks - sendStart;
        }
        asm volatile ("nop");
    }
}
