const std = @import("std");
const micro = @import("microzig");
const chip = micro.chip;
const board = micro.board;

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

// this const is required by microzig
pub var clock_frequencies: chip.Frequencies = undefined;

pub fn init() void {
    // const ccfg: chip.Config = .{ .clock = board.hse_96 }; // using hse
    const ccfg: chip.Config = .{};
    chip.init(ccfg);
    clock_frequencies = ccfg.clock.frequencies;

    board.init(.{});
}

pub fn main() void {
    var itv = ticker.interval(blink_speed);
    while (true) {
        if (itv.ready(blink_speed)) {
            board.led.toggle();
        }
        asm volatile ("nop");
    }
}
