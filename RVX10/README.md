# RVX10 single-cycle bring-up tests

## Files
- `docs/ENCODINGS.md` — funct7/funct3 map for CUSTOM-0
- `docs/TESTPLAN.md` — chosen operands, per-op expected values, checksum
- `tests/rvx10.hex` — memory image for `$readmemh`

## How to run
1. Build and run with Icarus:
   ```
   iverilog -g2012 -o cpu_tb src/riscvsingle.sv
   vvp cpu_tb
   ```
2. Expected console:
   All the RVX10 operations log and below message.
   ```
   Simulation succeeded
   ```

Notes:
- The program computes all 10 RVX10 ops, accumulates into `x28`, but performs only the two allowed stores for the supplied testbench.
- Rotate-by-zero is handled; `ABS(0x80000000)=0x80000000` by ALU semantics.
