# Premium Vending Machine Controller

A SystemVerilog RTL implementation of a vending machine controller featuring automatic change-return, real-time inventory tracking, and idle-timeout refund handling — designed to model realistic real-world vending machine behavior.

## 📌 Overview
This project was developed as part of a VLSI/RTL design internship. It goes beyond a basic vending machine FSM by implementing a **greedy change-return algorithm**, per-item **inventory management**, and an **idle-timeout auto-refund** mechanism, along with a documented engineering case study of two real bugs found and fixed during simulation.

## 🛠️ Tools & Technologies
- **HDL:** Verilog
- **Simulation & Synthesis:** Xilinx Vivado
- **Verification:** Testbench with directed test cases

## ⚙️ Design Details

### Core Features
- **Coin input handling:** Accepts multiple coin/note denominations
- **Inventory tracking:** Tracks stock count per item; prevents selection of out-of-stock items
- **Greedy change-return algorithm:** Calculates and dispenses change using the fewest denominations possible
- **Idle-timeout refund:** If no item is selected within a set time after coin insertion, the machine automatically refunds the inserted amount
- **FSM-based control:** States for Idle, Coin Collection, Item Selection, Dispense, and Refund

## 🐛 Engineering Case Study — Bugs Found & Fixed
During simulation and waveform analysis, two real bugs were identified and debugged as part of the design process. Root causes were traced using Vivado waveform analysis, and fixes were verified through re-simulation.

Full details of both bugs — including root-cause analysis and the corresponding fixes — are documented in `report.pdf`.


## ✅ Verification
Verified using a Verilog testbench covering:
- Multiple coin denomination combinations
- Insufficient balance and exact-change scenarios
- Inventory depletion (out-of-stock handling)
- Idle-timeout refund triggering

## 📄 Report
`report.pdf` includes the FSM state diagram, RTL walkthrough, simulation waveforms, and the detailed bug case study.

## 🎯 Key Learnings
- Implementing greedy algorithms in hardware description language
- Debugging real RTL bugs using waveform analysis in Vivado
- Designing FSMs with timeout-based behavior
- Practical inventory and transaction-state management in digital design
