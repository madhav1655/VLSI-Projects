# Vending Machine Controller

An FSM-based vending machine controller handling coin input, item dispensing, change return, and an added card-payment path.

## Design

- **Core logic**: Finite State Machine controlling coin acceptance, item selection, dispensing, and change calculation
- **Debouncing**: Coin input is debounced using a **2-flip-flop synchronizer** to filter mechanical/electrical noise before it reaches the FSM
- **Extension**: Added a card-payment input path alongside the base coin-payment flow

## Files

| File | Description |
|---|---|
| `*.v` | FSM controller RTL, coin debouncer |
| `*_tb.v` | Self-checking testbench |

## Simulation

Verified in **Xilinx Vivado** — testbench simulates coin insertion sequences, item selection, and validates correct dispensing/change output.

**Waveform:**

![Waveform](./Waveform.png)

## How to Run

1. Open the project in Xilinx Vivado
2. Add the controller RTL and testbench files
3. Set the testbench as the top module
4. Run behavioral simulation and inspect the waveform

## Key Learning

Implementing the 2-FF synchronizer for coin debouncing reinforced how to handle asynchronous, noisy real-world inputs safely in a synchronous digital design, and extending the design with card payment showed how to scale an FSM without breaking existing states.
