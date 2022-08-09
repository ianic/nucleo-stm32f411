const std = @import("std");
const micro = @import("microzig");
const chip = micro.chip;
const board = micro.board;
const regs = chip.registers;

pub const interrupts = struct {
    pub fn SysTick() void {
        ticks += 1;
    }

    pub fn EXTI15_10() void {
        if (chip.irq.pending(.exti13)) {
            blink_speed = switch (blink_speed) {
                500 => 100,
                100 => 50,
                else => 500,
            };
        }
    }
};

var ticks: u32 = 0;
var blink_speed: u32 = 500;

pub fn main() void {
    board.init(.{});

    while (true) {
        if (ticks % blink_speed == 0) {
            board.led.toggle();
        }
        asm volatile ("nop");
    }
}
