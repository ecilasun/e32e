# E32E - Experimental 32 bit RISC-V processor for Educational purposes

## Features
This system contains two RISC-V (1*RV32IMZicsr + 1*RV32IMFZicsr) hardware threads clocked at 100MHz each.
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
  - A very simple device chain; one UART (with FIFOs added to the fpag4fun example) and one shared MAILBOX memory (4KBytes)
  - A PS/2 keyboard interface for keyboard entry is also provided (it is a placeholder from 'Computer Principles and Design in Verilog HDL' by Yamin Li, will replace with a bi-directional one later)
  - SDCard file access available via SPIMaster and SDK helpers (ROM has a small commandline to help load/run ELF executables)
- A sample ROM image (source here: https://github.com/ecilasun/riscvtool/tree/main/e32e) which shows how to set up a basic environment to load and run user programs from micro-SD card
  - Current ROM image supports a user timer interrupt handler to be installed via MAILBOX/HARTIRQ memory mapped writes
- A Doom port is available at https://github.com/ecilasun/riscvtool/tree/main/doom
  - Build the project at https://github.com/ecilasun/riscvtool/tree/main/doom/src/riscv via the Makefile to generate a doom.elf executable (you'll need a shareware doom wad file on the sdcard alongside doom.elf and a PS2 keyboard attached to the board to run it)
- A simple GPU and a dynamic framebuffer pointer to anywhere in addressible memory
  - Video output is set to 8bit paletted 320x240 or 640x480 resolution (user can control this via a GPU command)
  - Video scanout hardware burst reads from memory at end of each scanline and outputs DVI signal over HDMI
  - Each scanline consists of either 20 (320x240) or 40 (640x480) bursts, read into a scanline cache for output
- On startup, the ROM will transfer control to a 'boot.elf' executable at the root of the sdcard (sd:boot.elf) if one is found, before installing any interrupt handlers. Otherwise execution falls back to the default ROM image. This allows for swapping ROM software without having to rebuild the device

## Work in progress
- Investigate overlapped AXI4 transactions
  - Already have some reads & writes overlap
  - Check write-write and read-read overlaps and how to handle out-of-order transactions using IDs
- Need to work on the OS a bit, task system and debugging still very experimental
  - Will have to improve upon the mailbox idea
- Might be interesting to check legacy rasterization or sprite support on the GPU
  - GPU can burst read, trivial to do masked burst accumulation for sprite into a second scanline buffer and compositing those on top of the actual scanline buffer
  - Rasterization is pretty straightforward, texturing complicates it a little but still not that hard (raster unit(s) need their own 16xN pixel tiles to output to, then DMA onto framebuffer via burst writes)
- Start looking at BVH8 tracing now that the GPU has independent access to RAM
  - Some tools to generate BVH8 data offline already done, alongside with a previewer, available at https://github.com/ecilasun/lbvh-tool
  - Might want to fit as much as possible into a single cache line sized burst read (128bits)
- Implement a bi-directional PS/2 keyboard interface
  - Would be nice to be able to turn the caps lock light on and off from software side
  - Most multiple key presses ignored by software (modifier + key combos except shift)
- Work on non-indexed color video output modes
  - A 16bpp 320x200 (or 240) mode would be really nice for games
  - Complicated rasterizer work; it would need to support output for many color widths
- Eventually need to pipeline the CPUs
  - This generated unnecessary complication and a lot more hardware before
  - Must have made a mistake somewhere, try splitting into two units first
  - Floating point complicates things since it is arbitrary clock cycles at some points
- Try to have an arbiter for the FPU so we can share it between CPUs
  - Seems excessive to include many on one chip
  - What is the likelyhood that both CPUs need to use it exactly at the same time?
- Linux 5.* port
  - Might be a big undertaking or trivial, try and see
  - Look at the no-MMU implementations available
  - If linux runs, we will immediately need network support
  - Look at interfacing to the onboard ethernet chip
- Move everything to a custom board
  - This is probably a year (or more) long project
  - Or perhaps it's worth trying for a VLSI tapeout on a pre-fabricated board instead?

