# 8-bit Timer Peripheral with 5-Stage RISC-8 CPU

## 1. Project Overview

This project focuses on the design, verification, and integration of an 8-bit Timer peripheral into an existing 8-bit RISC processor with a 5-stage pipeline.

The Timer peripheral is designed using Verilog and verified using SystemVerilog and Universal Verification Methodology (UVM). The integrated system is tested through simulation and FPGA implementation.

## 2. Key Features

### Timer Peripheral
- 8-bit programmable timer and prescaler.
- Configurable counter and compare registers.
- Periodic and One-Shot operating modes.
- PWM output generation.
- Overflow and Compare interrupt flags.
- Write-One-to-Clear (W1C) interrupt mechanism.
- Memory-mapped I/O interface.

### UVM Verification
- UVM-based verification environment.
- Cycle-accurate reference model and scoreboard.
- Seven SystemVerilog Assertions (SVA).
- Functional coverage analysis.
- Directed and constrained-random testing.
- Mutation testing to evaluate verification effectiveness.

### CPU Integration
- Integration with a 5-stage RISC-8 pipeline.
- Memory-mapped peripheral address space (0xF0–0xFF).
- Single-cycle bus interface.
- Firmware-based system verification.
- Original CPU functionality preserved.

## 3. Technologies Used

- Verilog HDL
- SystemVerilog
- Universal Verification Methodology (UVM)
- AMD Xilinx Vivado 2026.1
- Icarus Verilog
- Python
- GTKWave

## 4. Project Architecture

The system consists of three main components:

1. **RISC-8 CPU Core:** An 8-bit processor with a 5-stage pipeline (IF, ID, EX, MEM, WB).
2. **Timer Peripheral:** An 8-bit programmable timer with PWM and interrupt functionality.
3. **Verification Environment:** A UVM testbench with assertions, scoreboard, reference model, and functional coverage.

## 5. Verification Results

| Verification Metric | Result |
|---|---|
| UVM Test | PASSED |
| UVM Errors / Fatal | 0 / 0 |
| Per-clock Timer Checks | 8,433 |
| Reference Model Mismatches | 0 |
| Register Coverage | 100% |
| Start Configuration Coverage | 96.4% |
| Planted Bugs Detected | 10 / 10 |
| CPU Random Regression | 500 / 500 Passed |
| System Test | PASSED |

## 6. FPGA Implementation Results

Target FPGA: Xilinx Virtex-7 (xc7vx485tffg1157-1)

| Metric | Result |
|---|---|
| Total Cells | 608 |
| LUTs | 339 |
| Flip-Flops | 230 |
| Clock Constraint | 100 MHz |
| Setup Slack (WNS) | +4.357 ns |
| Hold Slack (WHS) | +0.068 ns |
| Estimated Total Power | 0.25 W |

## 7. Repository Structure

```text
├── rtl/
│   ├── periph/
│   │   ├── timer8.v
│   │   ├── timer_regs.v
│   │   └── timer_top.v
│   ├── risc8_5stage_core.v
│   └── risc8_soc.v
│
├── sv/
│   ├── timer_ref.v
│   └── timer_checker.v
│
├── uvm/
│   ├── bus_if.sv
│   ├── timer_sva.sv
│   └── tb/
│
├── tb/
│   ├── tb_plain.v
│   ├── tb_risc8_soc.v
│   ├── tb_dump.v
│   └── tb_risc8_5stage.v
│
├── sw/
│   ├── timer_demo.s
│   ├── asm8.py
│   ├── iss.py
│   └── random_test.py
│
├── run_plain.sh
└── run_soc.sh
```

## 8. How to Run

### Run Timer Testbench

```bash
sh run_plain.sh
```

### Run CPU + Timer System Test

```bash
sh run_soc.sh
```

### Run UVM Verification

Open the project in AMD Vivado, configure the UVM simulation sources, set the test name to:

```text
+UVM_TESTNAME=tmr_all_test
```

Then run the simulation.

## 9. Key Contributions

- Designed an 8-bit Timer peripheral using Verilog HDL.
- Developed a reusable UVM verification environment.
- Implemented cycle-accurate reference checking and SystemVerilog Assertions.
- Integrated the Timer into a 5-stage pipelined RISC processor.
- Verified the integrated system through firmware and simulation.
- Evaluated FPGA resource utilization, timing, and power.

## 10. Author

**Name:** NGO VAN THANG

**Project:** Digital Design / RTL Design / Functional Verification

---

*This project demonstrates RTL design, functional verification, UVM methodology, and hardware-software integration for digital IC systems.*
