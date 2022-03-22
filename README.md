# E32E

This system contains eight RISC-V (rv32im) harts with the following features:

What's available
- Each HART conforms to minimal feature set of rv32im (DIV/MUL and base integer instructions)
- Each HART has its own 32Kbyte caches (16KBytes I$, 16KBytes D$)
- HARTs are currently clocked at 100MHz (TBD)
- A few of the CSRs are implemented (time/cycle/retired instruction counters, exception trap vectors, trap cause and a few more)
- Hardware interrupts, timer interrupts and illegal instruction exceptions supported
- Cache lines are 512bit wide, 512 lines long. R/W from/to memory completes in very few clocks. Cache hits bring data in 3 clocks.
- Two very simple arbiters; one for cached, one for uncached bus
- A very simple device chain; one UART (with built-in FIFOs) and one shared mailbox memory (4KBytes)
- Video output provided via HDMI port (DVI signal), with a single (uncached) framebuffer
- A sample ROM image (source here: https://github.com/ecilasun/riscvtool/tree/main/e32e) which shows dual core operation and mailbox synchronization
- Onboard 512Mbyte DDR3 memory is accessible (cached per-hart)
- There is a PS/2 keyboard interface enabled (memory mapped) which is not in use by the current ROM
- FENCE.I, CFLUSH.D.L1 and CDISCARD.D.L1 instructions supported
- SDCard file access available via SPIMaster and SDK helpers (ROM has a small commandline to help load ELF executables)

Work in progress
- Make cost of cache hit less than 3 clocks (2 clocks experimented with, works properly)
- Add an FPU if/when required
- Need to move framebuffer to cached memory region, but reads can be only 32 bits when writes are 128 bits, fix scan-out hardware for this
- Start looking at BVH8 tracing, and tools to generate BVH8 data offline
- Experiment with _even more_ cores
- Need terminal output over DVI on top of TTY at one point
- Perhaps retire TTY to utilize it as a debug port instead
- Get rid of 'GPU' and move everything over to software using all other cores instead
