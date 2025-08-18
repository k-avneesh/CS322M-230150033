# Problem 2 — Moore Two-Road Traffic Light

- Phases per 1 Hz tick: NS_G 5 → NS_Y 2 → EW_G 5 → EW_Y 2 → repeat.

- Output : At each tick, durations are 5/2/5/2 (ticks). One of {g,y,r} is high per road.

## Simulation timing
- clk frequency: 100 MHz (10 ns period)
- Chosen TICK_HZ (sim): 10 MHz / 10 = 1 MHz (tick every 10 clk cycles)  
  Real hardware: 1 Hz requires divider = 100 000 000
- Verification: Logged NS/EW state at each tick; counted tick pulses in each phase:
  NS_G = 5 ticks, NS_Y = 2 ticks, EW_G = 5 ticks, EW_Y = 2 ticks → matches spec.

## How to run (Icarus Verilog)
```sh
iverilog -o sim.out traffic_light.v tb_traffic_light.v
vvp sim.out
gtkwave .\waves\dump.vcd