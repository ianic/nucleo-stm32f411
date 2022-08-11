
### debugging notes 

install

``` sh
brew install armmbed/formulae/arm-none-eabi-gcc openocd qemu
```

create openocd.cfg and openocd.gdb files in bin folder

``` sh
openocd

arm-none-eabi-gdb -x openocd.gdb board.elf
```

