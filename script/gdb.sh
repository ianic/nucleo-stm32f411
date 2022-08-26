#!/usr/bin/env bash -ex

git_root=$(git rev-parse --show-toplevel)
dir=$(pwd)

# #pkill arm-none-eabi-gdb || true
# pkill aarch64-none-elf-gdb  || true
# pkill blackmagic || true
# zig build flash

cd $git_root/script
# /Users/ianic/code/blackmagic/src/blackmagic &> blackmagic.log &


#arm-none-eabi-gdb -x openocd.gdb $dir/zig-out/bin/board.elf --tui
/Applications/ArmGNUToolchain/11.3.rel1/aarch64-none-elf/bin/aarch64-none-elf-gdb \
    -x blackmagic.gdb \
    $dir/zig-out/bin/board.elf --tui
