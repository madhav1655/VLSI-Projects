# Sequence Detector (1101) – Mealy & Moore FSM

A SystemVerilog RTL implementation of a sequence detector that identifies the bit pattern **"1101"** in a serial input stream, designed using both **Mealy** and **Moore** finite state machine architectures for comparison.

## 📌 Overview
This project was developed as part of a VLSI/RTL design internship. It covers the complete design flow — from RTL coding to functional verification — for a classic digital design problem frequently asked in VLSI interviews.

## 🛠️ Tools & Technologies
- **HDL:** SystemVerilog
- **Simulation & Synthesis:** Xilinx Vivado
- **Verification:** Self-checking testbench

## 📂 Repository Structure
sequence-detector-1101/
├── mealy_fsm.sv          # Mealy FSM implementation
├── moore_fsm.sv          # Moore FSM implementation
├── tb_sequence_detector.sv  # Testbench
├── waveform.png          # Simulation result screenshot
└── report.docx           # Detailed project report

## ⚙️ Design Details
- **Input:** Serial bit stream (1 bit per clock cycle)
- **Output:** Detection flag, asserted when "1101" pattern is found
- **Overlap handling:** Supports overlapping sequence detection
- **States:** 5-state FSM (S0–S4) tracking partial matches of the sequence

### Mealy vs Moore
| Aspect | Mealy FSM | Moore FSM |
|---|---|---|
| Output depends on | Present state + input | Present state only |
| Output timing | Faster (combinational) | One cycle delayed |
| Hardware | Fewer states, more logic | More states, simpler logic |

## ✅ Verification
The design was verified using a self-checking testbench in Vivado, covering:
- Random and directed input sequences
- Edge cases (overlapping patterns, back-to-back detections)
- Waveform-level validation of output timing for both FSM types

## 📄 Report
A detailed report (`report.docx`) is included, covering the design approach, state diagrams, RTL code walkthrough, and simulation results.

## 🎯 Key Learnings
- Practical difference between Mealy and Moore architectures in real hardware
- Testbench design for sequence detection problems
- Timing analysis of FSM outputs in simulation
