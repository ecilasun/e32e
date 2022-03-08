# E32E

This system contains four RISC-V (rv32im) harts with the following features:

What's available
- Each HART conforms to minimal feature set of rv32im (DIV/MUL and base integer instructions)
- Each HART has its own 32Kbyte caches (16KBytes I$, 16KBytes D$)
- HARTs are currently clocked at 100MHz (TBD)
- Cache lines are 512bit wide, 512 lines long. R/W from/to memory completes in very few clocks. Cache hits bring data in 3 clocks.
- Two very simple arbiters; one for cached, one for uncached bus
- A very simple device chain; one UART (with built-in FIFOs) and one shared mailbox memory (4KBytes)
- Video output provided via HDMI port (DVI signal), with a single (uncached) framebuffer
- A sample ROM image (source here: https://github.com/ecilasun/riscvtool/tree/main/e32e) which shows dual core operation and mailbox synchronization

Work in progress
- Make cost of cache hit less than 3 clocks (2 clocks experimented with, works properly)
- Very few CSR registers working (only the MHARTID is used at the moment)
- Enable other CSR registers (timer/interrupt vectors etc)
- Add DDR3 memory module
- Experiment with _even more_ cores
