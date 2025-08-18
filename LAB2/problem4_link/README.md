# Problem 4 — Two FSMs (Master–Slave Handshake)

- 4-phase req/ack for 4 bytes A0..A3.

- Slave holds ack high for 2 cycles minimum and drops after req low.

For each byte (A0..A3), one 4-phase handshake:

- Cycle t: req↑ with data=Ax
- t+1..: ack↑ (held ≥2 cycles)
- after req↓ and ≥2 cycles of ack=1 → ack↓ → next byte
- After 4th handshake completes: done pulses for 1 cycle.

## How to run (Icarus Verilog)
```sh
iverilog -o sim.out master_fsm.v slave_fsm.v link_top.v tb_link_top.v
vvp sim.out
gtkwave .\waves\dump.vcd