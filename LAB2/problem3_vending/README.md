# Problem 3 — Mealy Vending Machine

- Coins: 01=5, 10=10, 00=idle (11 ignored).

- Vend when total ≥ 20. Change (chg5) when total == 25. Reset after vend.

## Test cases:
- 10 + 10 → DISPENSE at the cycle of the 2nd 10
- 5 + 5 + 10 → DISPENSE at the cycle of the 10
- 10 + 5 + 10 → DISPENSE and CHG5 at the cycle of the last 10

## Justification for Mealy
A Mealy FSM allows outputs (dispense, chg5) to depend on both the current state (total so far) and the coin input in the same cycle. This lets the vending machine vend immediately upon receiving the final coin without waiting an extra clock cycle, reducing latency compared to Moore.

## How to run (Icarus Verilog)
```sh
iverilog -o sim.out vending_mealy.v tb_vending_mealy.v
vvp sim.out
gtkwave .\waves\dump.vcd