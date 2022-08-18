#!/usr/bin/env bash -ex

git_root=$(git rev-parse --show-toplevel)
dir=$(pwd)

#pkill arm-none-eabi-gdb openocd || true
# zig build flash

cd $git_root/script
#openocd &> openocd.log &
#sleep 1

#arm-none-eabi-gdb -x openocd.gdb $dir/zig-out/bin/board.elf --tui
/Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin/aarch64-none-elf-gdb \
    -x blackmagic.gdb \
    $dir/zig-out/bin/board.elf --tui
