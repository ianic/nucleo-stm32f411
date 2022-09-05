const micro = @import("microzig");
const chip = micro.chip;
const board = micro.board;

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

var ticker = chip.ticker();
var blink_speed: u32 = 500;

fn changeBlinkSpeed() void {
    blink_speed = switch (blink_speed) {
        500 => 100,
        100 => 50,
        else => 500,
    };
}

var button: board.Button = undefined;

pub fn init() void {
    chip.init(.{});
    button = board.Button.init(.{ .exti = .{ .enable = true } });
}

pub fn main() void {
    _ = button;
    var led = board.Led.init(.{});

    var itv = ticker.interval(blink_speed);
    while (true) {
        if (itv.ready(blink_speed)) {
            led.toggle();
        }
        asm volatile ("nop");
    }
}
