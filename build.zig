const std = @import("std");
const micro = @import("lib/microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    try std.os.chdir(srcDir());

    const backing = .{
        .board = micro.boards.nucleo_stm32f411,
    };

    const Example = struct {
        name: []const u8,
        source: []const u8,
    };

    const examples = [_]Example{
        .{ .name = "blink", .source = "blink/src/main.zig" },
        .{ .name = "uart-pooling", .source = "uart/pooling/src/main.zig" },
        .{ .name = "uart-interrupt", .source = "uart/interrupt/src/main.zig" },
        .{ .name = "uart-dma", .source = "uart/dma_buffered/src/main.zig" },
    };

    for (examples) |e| {
        const elf = try micro.addEmbeddedExecutable(
            b,
            b.fmt("{s}.elf", .{e.name}),
            e.source,
            backing,
            .{},
        );
        elf.setBuildMode(.ReleaseSmall);
        const bin = b.addInstallRaw(
            elf,
            b.fmt("{s}.bin", .{e.name}),
            .{},
        );
        b.getInstallStep().dependOn(&bin.step);
        elf.install();
    }
}

pub fn srcDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
