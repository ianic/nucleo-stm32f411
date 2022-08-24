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
    //.rx = gpio.PB7,
    .dma_enable = true,
    .clock_frequencies = clock.frequencies,
});
var uart1: Uart1 = undefined;

pub fn init() void {
    chip.init(.{ .clock = clock });
    board.init(.{});
    uart1 = Uart1.init();
}
//------ init

var buf: [128]u8 = undefined;

pub fn main() !void {
    var itv = ticker.interval(blink_speed);

    var lastTicks: u32 = 0;
    while (true) {
        if (itv.ready(blink_speed)) {
            board.led.toggle();

            if (uart1.txReady()) {
                const ticks = ticker.ticks;
                const msg = try std.fmt.bufPrint(buf[0..], "ticks {d}, diff: {d}\n", .{
                    ticks,
                    ticks - lastTicks,
                });
                _ = uart1.tx(msg);
                lastTicks = ticks;
            }
        }
        asm volatile ("nop");
    }
}
