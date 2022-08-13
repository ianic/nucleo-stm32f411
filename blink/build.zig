const std = @import("std");
const micro = @import("lib/microzig/src/main.zig");

pub fn build(b: *std.build.Builder) !void {
    try std.os.chdir(srcDir());

    const backing = .{
        .board = micro.boards.nucleo_stm32f411,
    };

    const exe = try micro.addEmbeddedExecutable(
        b,
        "board.elf",
        "src/main.zig",
        backing,
        .{
            // optional slice of packages that can be imported into your app:
            // .packages = &my_packages,
        },
    );
    exe.setBuildMode(.ReleaseSmall);
    //exe.setBuildMode(.Debug);

    const bin = b.addInstallRaw(
        exe,
        "board.bin",
        .{},
    );
    b.getInstallStep().dependOn(&bin.step);

    const bin_path = b.getInstallPath(.{ .bin = .{} }, exe.out_filename);
    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        "/Applications/STMicroelectronics/STM32Cube/STM32CubeProgrammer/STM32CubeProgrammer.app/Contents/MacOs/bin/STM32_Programmer_CLI",
        "-c",
        "port=SWD",
        "-d",
        bin_path,
        "--go",
    });
    flash_cmd.step.dependOn(b.getInstallStep());
    const flash_step = b.step("flash", "Flash and run the app on your STM32F411");
    flash_step.dependOn(&flash_cmd.step);

    b.default_step.dependOn(&exe.step);
    exe.install();
}

pub fn srcDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
