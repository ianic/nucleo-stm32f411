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
            blink_enabled = !blink_enabled;
        }
        // if (blink_speed == 500) {
        //     blink_speed = 150;
        //     return;
        // }
        // if (blink_speed == 300) {
        //     blink_speed = 150;
        //     return;
        // }
        // if (blink_speed == 150) {
        //     blink_speed = 500;
        //     return;
        // }

    }
};

var ticks: u32 = 0;
var blink_enabled = true;
var blink_speed: u32 = 150;

pub fn main() void {
    board.init(.{ .key_enabled = true });

    while (true) {
        //if (ticks % 500 == 0 and blink_enabled) {
        if (ticks % blink_speed == 0 and blink_enabled) {
            board.led.toggle();
        }
        asm volatile ("nop");
    }
}
