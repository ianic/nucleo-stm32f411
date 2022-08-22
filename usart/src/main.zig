const std = @import("std");
const micro = @import("microzig");
const chip = micro.chip;
const board = micro.board;
const uart = chip.uart;
const gpio = chip.gpio;
const regs = chip.registers;

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

    pub fn DMA2_Stream7() void {
        if (regs.DMA2.HISR.read().TCIF7 == 1) { // if transfer complete flag is set
            regs.DMA2.HIFCR.modify(.{ .CTCIF7 = 1 }); // clear transfer complete interrupt flag
        }

        if (regs.DMA2.HISR.read().HTIF7 == 1) { // half stream interrup flag
            regs.DMA2.HIFCR.modify(.{ .CHTIF7 = 1 });
        }

        if (regs.DMA2.HISR.read().TEIF7 == 1) { // transfer error
            regs.DMA2.HIFCR.modify(.{ .CTEIF7 = 1 });
        }

        if (regs.DMA2.HISR.read().DMEIF7 == 1) { // direct mode error
            regs.DMA2.HIFCR.modify(.{ .CDMEIF7 = 1 });
        }

        if (regs.DMA2.HISR.read().FEIF7 == 1) { // fifo error
            regs.DMA2.HIFCR.modify(.{ .CFEIF7 = 1 });
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

var buf: [128]u8 = undefined;

pub fn main() !void {
    var itv = ticker.interval(blink_speed);

    var sendTime: u32 = 0;
    while (true) {
        if (itv.ready(blink_speed)) {
            board.led.toggle();
            const sendStart = ticker.ticks;
            const msg = try std.fmt.bufPrint(buf[0..], "ticks {d}, sendTime: {d} iso medo u ducan\n", .{
                ticker.ticks,
                sendTime,
            });
            dma(@intCast(u16, msg.len));
            // for (msg) |ch| {
            //     uart1.tx(ch);
            // }
            sendTime = ticker.ticks - sendStart;
        }
        asm volatile ("nop");
    }
}

fn dma(number_of_data_items: u16) void {
    const peripheral_address = @ptrToInt(regs.USART1.DR);
    const memory_address = @ptrToInt(&buf);

    const cr_reg = regs.DMA2.S7CR; // control register
    const ndtr_reg = regs.DMA2.S7NDTR; // number of data register
    const pa_reg = regs.DMA2.S7PAR; // peripheral address register
    const ma_reg = regs.DMA2.S7M0AR; // memory address register

    regs.RCC.AHB1ENR.modify(.{ .DMA2EN = 1 }); // enable dma2 clock

    cr_reg.modify(.{ .EN = 0 }); // disable stream
    while (cr_reg.read().EN == 1) {} // wait for disable
    regs.DMA2.HIFCR.modify(.{ // clear status flags
        .CTCIF7 = 1,
        .CHTIF7 = 1,
        .CTEIF7 = 1,
        .CDMEIF7 = 1,
        .CFEIF7 = 1,
    }); //

    cr_reg.modify(.{
        .CHSEL = 4, // channel
        .DIR = 0b01, // direction: memory to periperal
        .CIRC = 0, // circular mode disabled
        .PINC = 0, // periperal increment mode: fixed
        .MINC = 1, // memory address pointer is incremented after each data transfer
        .PSIZE = 0b00, // peripheral data size: byte
        .MSIZE = 0b00, // memory data size: byte
        .TCIE = 1, // transfer complete interrupt enable
        //.PL = 11, // priority level: very high
    });

    pa_reg.modify(.{ .PA = peripheral_address });
    ma_reg.modify(.{ .M0A = memory_address });
    ndtr_reg.modify(.{ .NDT = number_of_data_items });

    cr_reg.modify(.{ .EN = 1 }); // enable stream
}

// usart1 tx is:
//   dma 2
//   stream 7
//   channel 4

// void UARTl_DMA_Transmit (uint8_t *pBuffer, uint32_t size) {
// }
//     RCC->AHB1ENR |= RCC_AHB1ENR_DMA2EN; // Enable DMA2 clock
//     DMA2_Channel6->CCR &= NDMA_CCR_EN; // Disable DMA channel
//
//     DMA2_Channel6->CCR &= -DMA_CCR_MEM2MEM; // Disable memory to memory mode
//     DMA2_Channel6->CCR &= -DMA_CCR_PL; // Channel priority Level
//     DMA2 Channel6->CCR |= DMA_CCR_PL_l; // Set DMA priority to high
//
//     DMA2_Channel6->CCR &= -DMA_CCR_PSIZE; // Peripheral data size ee = 8 bits
//     DMA2_Channel6->CCR &= -DMA_CCR_MSIZE; // Memory data size: ee =8 bits
//     DMA2_Channel6->CCR &= -DMA_CCR_PINC; // Disable peripheral increment mode
//     DMA2_Channel6->CCR |= DMA_CCR_MINC; // Enable memory increment mode
//     DMA2_Channel6->CCR &= -DMA_CCR_CIRC; // Disable circular mode
//     DMA2_Channel6->CCR |= DMA_CCR_DIR; // Transfer direction: to peripheral
//
//     DMA2_Channel6- >CCR |= DMA_CCR_TCIE; // Transfer complete interrupt enable
//     DMA2_Channel6->CCR &= -DMA_CCR_HTIE; // Disable Half transfer interrupt
//
//     DMA2_Channel6->CNDTR size; // Number of data to transfer
//     DMA2_Channel6->CPAR = (uint32_t)&(USART1->TDR); // Peripheral address
//     DMA2_Channel6->CMAR = (uint32_t) pBuffer; // Transmit buffer address
//
//     DMA2_CSELR->CSELR &= -DMA_CSELR_C6S; // See Table 19-2
//     DMA2_CSELR->CSELR |= 2«20; // Map channel 6 to USART1_TX I I Enable OMA channel
//
//     DMA2_Channel6->CCR |= DMA_CCR_EN;  // Enable DMA channel
// }
