# Problem 1 — Mealy Overlapping Sequence Detector (1101)

- Pattern: `1101` with overlap.
- Reset: synchronous, active-high.
- Output `y`: 1-cycle pulse when final `1` of `1101` arrives.

## Streams Tested

- Fixed stream: 11011011101 → indices [3, 6, 10]
- Randomized tail: 10 bits → detections vary

## How to run (Icarus Verilog)
```sh
iverilog -o sim.out seq_detect_mealy.v tb_seq_detect_mealy.v
vvp sim.out
gtkwave .\waves\dump.vcd