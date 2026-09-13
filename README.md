# UART Receiver RTL Design & Functional Verification

A Verilog/SystemVerilog-based implementation and verification of an 8-bit UART receiver using FSM-based protocol control, configurable baud-rate timing, and a structured self-checking testbench.

## Project Overview

This project implements an asynchronous UART receiver at the RTL level and verifies its functionality through simulation. The design receives serial data, detects the start bit, samples the incoming data, checks the stop bit, and produces a parallel 8-bit output.

The verification environment includes stimulus generation, monitoring, result checking, protocol assertions, and functional coverage.

## Design Features

* 8-bit UART data reception.
* FSM-based receiver control.
* Parameterized baud-rate timing using configurable clock-cycle counting.
* Serial-to-parallel data conversion.
* Start-bit and stop-bit handling.
* Reset support.
* Detection and handling of invalid reception conditions, where implemented.

## Verification Environment

The testbench includes:

* **Driver:** Generates UART serial stimulus.
* **Monitor:** Observes and captures receiver activity.
* **Scoreboard:** Compares expected data against received data.
* **Assertions:** Checks protocol and design properties.
* **Functional coverage:** Measures verification of important scenarios.
* **Testbench top:** Coordinates the verification components and simulation.

## Repository Structure

```text
uart-receiver-rtl-verification/
│
├── rtl/
│   └── uart_rx.v
│
├── tb/
│   ├── uart_rx_tb.sv
│   ├── uart_driver.sv
│   ├── uart_monitor.sv
│   ├── uart_scoreboard.sv
│   ├── uart_assertions.sv
│   └── uart_coverage.sv
│
├── UART/
├── uart_if.sv
├── README.md
└── .gitignore
```

## UART Frame Format

The receiver is intended to process a standard UART frame consisting of:

```text
Idle | Start | Data[0] ... Data[7] | Stop
  1  |   0   |     8 data bits     |  1
```

The exact supported configuration should be confirmed from the RTL.

## Verification Strategy

The testbench is designed to verify:

1. Correct reception of valid UART frames.
2. Correct serial-to-parallel data conversion.
3. Start-bit detection.
4. Baud-rate timing behavior.
5. Reset behavior.
6. Back-to-back frame reception.
7. Protocol corner cases.
8. Assertion and functional coverage results.

## Simulation

### Prerequisites

* Verilog/SystemVerilog simulator.
* [Icarus Verilog](https://steveicarus.github.io/iverilog/) or [Verilator](https://verilator.org/guide/latest/).

### Running the Simulation

The exact compilation and simulation commands depend on the simulator and testbench top module.

Example command structure:

```bash
iverilog -g2012 -o sim.out \
  rtl/uart_rx.v \
  uart_if.sv \
  tb/*.sv

vvp sim.out
```

Update the file list and top-level module as required by the actual project.

## Results

Add verified results here, including:

* Number of test cases executed.
* Number of passed and failed checks.
* Functional coverage percentage.
* Assertion results.
* Waveform evidence.

## Future Improvements

* Add constrained-random UART stimulus.
* Expand protocol error injection.
* Add a reference-model-based checker.
* Automate simulation and regression testing.
* Integrate linting and continuous integration.

## Author

Kaivalya Nibandhe
