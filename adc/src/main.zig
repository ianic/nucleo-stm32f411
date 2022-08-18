const std = @import("std");
const micro = @import("microzig");
const chip = micro.chip;
const board = micro.board;
const adc = chip.adc;

pub const interrupts = struct {
    pub fn SysTick() void {
        ticker.inc();
    }

    pub fn EXTI15_10() void {
        if (board.button.irq_pending()) {
            //
        }
    }

    pub fn ADC() void {
        conversions += 1;
    }
};

var ticker = chip.ticker();

// this const is required by microzig
pub var clock_frequencies: chip.Frequencies = undefined;

pub fn init() void {
    // const ccfg: chip.Config = .{ .clock = board.hse_96 }; // using hse
    const ccfg: chip.Config = .{};
    chip.init(ccfg);
    clock_frequencies = ccfg.clock.frequencies;

    board.init(.{});
}

//var temp: f32 = 0;
var conversions: u32 = 0;

pub fn main() void {
    adcInit();

    var itv = ticker.interval(200);
    var testTicker = ticker.interval(2000);
    var testOk: bool = true;

    while (true) {
        if (itv.ready(200)) {
            if (testOk) {
                board.led.toggle();
            } else {
                board.led.on();
            }
        }
        if (testTicker.ready(2000)) {
            testOk = adcTests();
        }
        asm volatile ("nop");
    }
}

const regs = chip.registers;

var data: [16]u16 = .{0xaaaa} ** 16;

fn adcInit() void {
    const inputs = [_]adc.Input{ .temp, .vref, .pa0, .pa1, .pc4 };
    if (inputs[1] == .vref) {
        asm volatile ("nop");
    }
    const cfg: adc.Config = .{
        .irq_enable = true,
        .data = &data,
        .inputs = &inputs,
        .channels = &.{ 18, 17, 0, 1, 14 },
    };
    config(cfg);
    chip.adc.init(cfg);
}

fn config(cfg: adc.Config) void {
    data[0] = @intCast(u16, cfg.channels[0]);
    data[1] = @intCast(u16, cfg.channels[1]);
    data[2] = @intCast(u16, cfg.channels[2]);
    data[3] = @intCast(u16, cfg.channels[3]);
    data[4] = @intCast(u16, cfg.channels[4]);

    data[5] = @intCast(u16, @enumToInt(cfg.inputs[0]));
    data[6] = @intCast(u16, @enumToInt(cfg.inputs[1]));
    data[7] = @intCast(u16, @enumToInt(cfg.inputs[2]));
    data[8] = @intCast(u16, @enumToInt(cfg.inputs[3]));
    data[9] = @intCast(u16, @enumToInt(cfg.inputs[4]));
    //@breakpoint();
}

fn adcTests() bool {
    var tr = TestResults(32).init();

    // test adc register values
    tr.add(regs.ADC1.SQR1.read().L == 4);
    tr.add(regs.ADC1.SQR3.read().SQ1 == 18);
    tr.add(regs.ADC1.SQR3.read().SQ2 == 17);
    tr.add(regs.ADC1.SQR3.read().SQ3 == 0);
    tr.add(regs.ADC1.SQR3.read().SQ4 == 1);
    tr.add(regs.ADC1.SQR3.read().SQ5 == 14);

    tr.add(regs.ADC1.SMPR1.read().SMP18 == 0b101);
    tr.add(regs.ADC1.SMPR1.read().SMP17 == 0b101);

    // gpio pins are in analog mode
    tr.add(regs.GPIOA.MODER.read().MODER0 == 3);
    tr.add(regs.GPIOA.MODER.read().MODER1 == 3);

    // temerature sensor is reading value
    var temp = adc.tempValueToC(data[0]);
    tr.add(temp > 20 and temp < 40);

    var vref = data[1];
    tr.add(vref > 1480 and vref < 1490);

    var results = tr.get();
    if (!tr.ok()) {
        // trying to prevent optimization
        if (temp > 30 and vref < 1000 and results[0]) {
            asm volatile ("nop");
        }
        //@breakpoint();
        //gdb commands:
        // info locals
        // print (f32)temp
        // x/32b results.ptr
        // x/32b &tr
        // x/16hx &data
        // x/16hd &data
    }
    return tr.ok();
}

fn TestResults(comptime no: u8) type {
    return struct {
        results: [no]bool = [_]bool{false} ** no,
        current: u8 = 0,

        const Self = @This();

        pub fn init() Self {
            return Self{ .current = 0 };
        }

        pub fn add(self: *Self, r: bool) void {
            self.results[self.current] = r;
            self.current += 1;
        }

        pub fn ok(self: *Self) bool {
            var i: u8 = 0;
            while (i < self.current) : (i += 1) {
                if (!self.results[i]) {
                    return false;
                }
            }
            return true;
        }
        pub fn get(self: *Self) []bool {
            return self.results[0..self.current];
        }
    };
}
