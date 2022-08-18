target extended-remote :3333

# print demangled symbols
set print asm-demangle on

# detect unhandled exceptions, hard faults and panics
# break DefaultHandler
# break HardFault
# break rust_begin_unwind

monitor arm semihosting enable

# kill openocd on exit
# ref: https://github.com/Marus/cortex-debug/issues/371
monitor [target current] configure -event gdb-detach {shutdown}

load

# start the process but immediately halt the processor
# stepi
