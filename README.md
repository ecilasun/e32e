# E32E

This system contains two RISC-V (rv32i) harts with the following features:

What's available
- Two rv32i HARTs with individual 32Kbyte caches (16KBytes I$, 16KBytes D$)
- Each rv32i is currently clocked at 120MHz
- Cache lines are 512bit wide, 512 lines long. R/W from/to memory completes in very few clocks. Cache hits bring data in 3 clocks.
- Two very simple arbiters; one for cached one for uncached bus
- A very simple device chain; one UART (with built-in FIFOs) and one shared mailbox memory (4KBytes)
- A sample ROM image (source here: https://github.com/ecilasun/riscvtool/tree/main/e32e) which shows dual core operation and mailbox synchronization

Work in progress
- Very few CSR registers working (namely the MHARTID)
- Support more CSR registers (timer/interrupt vectors etc)
- Add DDR3 memory module
- Add video unit
- Experiment with more cores
- Make cost of cache hit less than 3 clocks (2 clocks experimented with, works properly)