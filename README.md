# E32E

## Features
This system contains three RISC-V (2*RV32IMZicsr + 1*RV32IMFZicsr) hardware threads clocked at 100MHz.
It is designed to work on Digilent's Nexys Video FPGA board, and has the following features:

- Each core tries to conform to minimal feature set of rv32imzicsr (DIV/MUL, base integer, CSR registers)
  - The first core has an FPU which is currently not shared with other cores
  - FENCE.I, CFLUSH.D.L1 and CDISCARD.D.L1 instructions are implemented
- Onboard 512Mbyte DDR3 memory is accessible from all HARTs (through individual caches)
  - Each core has its own 32Kbyte cache (16KBytes I$, 16KBytes D$)
  - Cache lines are 512bit wide, 512 lines long. R/W from/to memory completes in very few clocks. Cache hits bring data in 3 clocks.
- Only a few of the CSRs are implemented (time/cycle/retired instruction counters, exception trap vectors, trap cause and a few more)
- Hardware interrupts, timer interrupts and illegal instruction exceptions supported, in addition to a memory mapped hardware interrupt trigger bit per core
  - Each hart can get a hardware interrupt triggered by writes to a special HARTIRQ memory mapped device
- Two very simple round-robin arbiters exist on the system
  - One for cached (4x1), one for uncached (3x1) device access
  - A very simple device chain; one UART (with built-in FIFOs) and one shared MAILBOX memory (4KBytes)
  - A PS/2 keyboard interface for keyboard entry is also provided
  - SDCard file access available via SPIMaster and SDK helpers (ROM has a small commandline to help load/run ELF executables)
- A sample ROM image (source here: https://github.com/ecilasun/riscvtool/tree/main/e32e) which shows how to set up a basic environment to load and run user programs from micro-SD card
  - Current ROM image supports a user timer interrupt handler to be installed via MAILBOX/HARTIRQ memory mapped writes
- A Doom port is available at https://github.com/ecilasun/riscvtool/tree/main/doom
  - Build the project at https://github.com/ecilasun/riscvtool/tree/main/doom/src/riscv via the Makefile to generate a doom.elf executable (you'll need a shareware doom wad file on the sdcard alongside doom.elf and a PS2 keyboard attached to the board to run it)
- A simple GPU and a dynamic framebuffer pointer to anywhere in addressible memory
  - Video output is set to 8bit paletted 320x240 or 640x480 resolution
  - Video scanout hardware burst reads from memory at end of each scanline and outputs DVI signal over HDMI
  - Each scanline consists of either 20 (320x240) or 40 (640x480) bursts, read into a scanline cache for output

## Work in progress
- Investigate overlapped AXI4 transactions
  - Already have some reads & writes overlap
  - Check write-write and read-read overlaps and how to handle out-of-order transactions using IDs
- Need to work on the OS a bit, task system and debugging still very experimental
  - Will have to improve upon the mailbox idea
- Might be interesting to check legacy rasterization or sprite support on the GPU
  - GPU can burst read, trivial to do masked burst writes for sprites
  - Rasterization is pretty straightforward, texturing complicates it a little but still not that hard
- Start looking at BVH8 tracing now that the GPU has independent access to RAM
  - Some tools to generate BVH8 data offline already done, alongside with a previewer, available at https://github.com/ecilasun/lbvh-tool
- Implement a bi-directional PS/2 keyboard interface
  - Would be nice to be able to turn the caps lock light on and off
- Work on non-indexed color video output modes
- Eventually need to pipeline the CPUs, try the register busy bit list idea
