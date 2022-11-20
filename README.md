# E32E

This system contains four RISC-V (3*RV32IMZicsr + 1*RV32IMFZicsr) hardware threads clocked at 100MHz with the following features:

- Each core tries to conform to minimal feature set of rv32imzicsr (DIV/MUL, base integer, CSR registers)
  - The first core has an FPU which is currently not shared with other cores
  - FENCE.I, CFLUSH.D.L1 and CDISCARD.D.L1 instructions are implemented
- Onboard 512Mbyte DDR3 memory is accessible from all HARTs (through individual caches)
  - Each core has its own 32Kbyte cache (16KBytes I$, 16KBytes D$)
  - Cache lines are 512bit wide, 512 lines long. R/W from/to memory completes in very few clocks. Cache hits bring data in 3 clocks.
- Only a few of the CSRs are implemented (time/cycle/retired instruction counters, exception trap vectors, trap cause and a few more)
- Hardware interrupts, timer interrupts and illegal instruction exceptions supported, in addition to a memory mapped hardware interrupt trigger bit per core
  - Each hart can get a hardware interrupt triggered by writes to a special HARTIRQ memory mapped device
- Two very simple arbiters exist on the system
  - One for cached, one for uncached device access
  - A very simple device chain; one UART (with built-in FIFOs) and one shared MAILBOX memory (4KBytes)
  - A PS/2 keyboard interface for keyboard entry is also provided
  - SDCard file access available via SPIMaster and SDK helpers (ROM has a small commandline to help load/run ELF executables)
- Video output provided via DVI over HDMI, with a single uncached framebuffer
- A sample ROM image (source here: https://github.com/ecilasun/riscvtool/tree/main/e32e) which shows how to set up a basic environment to load and run user programs from micro-SD card
  - Current ROM image supports a user timer interrupt handler to be installed via MAILBOX/HARTIRQ memory mapped writes

Work in progress
- Make cost of cache hit less than 3 clocks (2 clocks experimented with, works properly)
- Need to move framebuffer to cached memory region, but reads can be only 32 bits when writes are 128 bits, fix scan-out hardware to accept 32bits for this
- Start looking at BVH8 tracing, and tools to generate BVH8 data offline
- Experiment with _even more_ cores
- Need terminal output over DVI to be able to retire TTY at one point (i.e. fonts)
- Perhaps retire TTY to utilize it as a debug port instead
- Get rid of 'GPU' and move everything over to software using all other cores instead
