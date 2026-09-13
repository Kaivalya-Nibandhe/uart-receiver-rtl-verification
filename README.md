# UART Receiver RTL Design & Functional Verification

## Overview

This project implements and verifies an **8-bit UART receiver** using Verilog RTL and a structured SystemVerilog verification environment.

The UART receiver supports the standard **8N1 UART configuration**:

* 8 data bits
* No parity bit
* 1 stop bit
* LSB-first transmission
* Active-LOW start bit
* HIGH stop bit

The design uses a finite state machine (FSM) and a configurable clock-cycle counter to receive and sample UART data at the appropriate time.

The verification environment was developed and executed using **Verilator on Ubuntu/Linux**.

---

## Design Features

* 8-bit UART receiver
* FSM-based receiver control
* Parameterized baud-rate timing
* Configurable `CLKS_PER_BIT` parameter
* Start-bit validation
* LSB-first data reception
* Stop-bit validation
* `rx_valid` pulse after successful frame reception
* `framing_error` indication for an invalid stop bit
* Safe recovery to the idle state
* Support for consecutive UART frames

---

## UART Frame Format

The receiver supports the following UART frame format:

```text
Idle   Start   D0   D1   D2   D3   D4   D5   D6   D7   Stop   Idle
  1      0     LSB                    Data Bits                 1
```

Each frame contains:

```text
1 Start Bit + 8 Data Bits + 1 Stop Bit
```

The data is transmitted **least-significant bit first**.

---

## Receiver FSM

The RTL receiver uses the following states:

| State           | Description                                               |
| --------------- | --------------------------------------------------------- |
| `STATE_IDLE`    | Waits for the UART RX line to go LOW                      |
| `STATE_START`   | Validates the start bit near the middle of the bit period |
| `STATE_DATA`    | Samples the eight data bits                               |
| `STATE_STOP`    | Checks whether the stop bit is HIGH                       |
| `STATE_CLEANUP` | Clears status signals and returns to idle                 |

### Output Signals

| Signal          | Description                                        |
| --------------- | -------------------------------------------------- |
| `rx`            | Serial UART input                                  |
| `rx_data[7:0]`  | Received 8-bit data                                |
| `rx_valid`      | Indicates successful reception of a complete frame |
| `framing_error` | Indicates that the received stop bit was LOW       |
| `clk`           | System clock                                       |
| `rst`           | Active-HIGH reset                                  |

---

## Verification Environment

The project uses a modular, self-checking SystemVerilog testbench.

### Verification Components

| File                 | Responsibility                                                    |
| -------------------- | ----------------------------------------------------------------- |
| `uart_driver.sv`     | Generates UART stimulus and transmits test frames                 |
| `uart_monitor.sv`    | Observes DUT outputs and records received transactions            |
| `uart_scoreboard.sv` | Compares expected and actual received data                        |
| `uart_coverage.sv`   | Tracks executed verification scenarios                            |
| `uart_assertions.sv` | Checks important signal behavior                                  |
| `uart_rx_tb.sv`      | Top-level testbench that coordinates the verification environment |

The testbench includes directed tests, randomized transactions, negative tests, and corner-case scenarios.

---

## Test Scenarios

The following scenarios are included in the verification environment:

* Reset behavior
* Directed UART data-pattern tests
* Randomized 8-bit UART transactions
* Invalid stop-bit test
* False start-bit test
* Back-to-back UART frame test
* Scoreboard-based data comparison
* Functional coverage tracking
* Assertion checks for important DUT behavior

### Negative Tests

#### Invalid Stop-Bit Test

A complete UART frame is transmitted with the stop bit driven LOW instead of HIGH.

Expected behavior:

```text
rx_valid      = 0
framing_error = 1
```

#### False Start-Bit Test

A short LOW pulse is applied to the RX line to simulate a false start condition.

Expected behavior:

```text
The receiver rejects the false start and does not generate rx_valid.
```

#### Back-to-Back Frame Test

Two UART frames are transmitted consecutively without an additional idle gap.

Expected behavior:

```text
Both frames are received correctly.
```

---

## Project Structure

```text
uart_receiver/
├── README.md
├── .gitignore
│
├── rtl/
│   └── uart_rx.v
│
├── tb/
│   ├── uart_rx_tb.sv
│   ├── uart_driver.sv
│   ├── uart_monitor.sv
│   ├── uart_scoreboard.sv
│   ├── uart_coverage.sv
│   └── uart_assertions.sv
│
├── sim/
│   └── obj_dir/
│
├── waves/
│   └── dump.vcd
│
└── docs/
```

The `sim/obj_dir/` directory contains generated Verilator build files and should not be committed to GitHub.

---

## Tools and Technologies

* Verilog
* SystemVerilog
* Finite State Machines
* RTL Design
* Functional Verification
* Verilator
* GTKWave
* Ubuntu/Linux
* Git and GitHub

---

## Simulation Configuration

The current testbench uses:

```text
CLKS_PER_BIT  = 217
CLOCK_PERIOD  = 40 ns
```

Therefore, the simulated UART bit period is:

```text
217 × 40 ns = 8680 ns
```

The UART timing is controlled using simulation delays in the testbench driver.

---

## Compilation Using Verilator

Run the following commands from the project root:

```bash
rm -rf sim/obj_dir
mkdir -p sim/obj_dir

verilator --binary -j 0 -Wall \
rtl/uart_rx.v \
tb/uart_driver.sv \
tb/uart_monitor.sv \
tb/uart_coverage.sv \
tb/uart_assertions.sv \
tb/uart_scoreboard.sv \
tb/uart_rx_tb.sv \
--top uart_rx_tb \
--language 1800-2012 \
--timing \
-CFLAGS "-std=c++20" \
--trace \
-Mdir sim/obj_dir
```

---

## Running the Simulation

After successful compilation, run:

```bash
./sim/obj_dir/Vuart_rx_tb
```

The testbench prints the status of the executed tests, scoreboard comparisons, coverage information, and assertion results.

---

## Waveform Viewing

The simulation can generate a VCD waveform file for signal-level analysis.

To open the waveform using GTKWave:

```bash
gtkwave waves/dump.vcd
```

Important signals for analysis include:

```text
clk
rst
rx
rx_data[7:0]
rx_valid
framing_error
```

---

## Verification Result

All implemented test scenarios passed successfully during Verilator simulation.

The testbench successfully exercised normal UART reception, randomized data transfers, invalid frame conditions, false start detection, and back-to-back frame reception.

---

## Future Improvements

Possible future enhancements include:

* Parameterized data width
* Configurable parity support
* Configurable number of stop bits
* Oversampling-based UART reception
* Additional baud-rate configurations
* More extensive constrained-random testing
* Automated coverage summary generation
* Continuous integration using GitHub Actions
* Improved waveform documentation for individual UART frames

---

## Author

**Kaivalya Nibandhe**

This project was developed as part of practical learning in RTL design, digital design verification, and VLSI development workflows.
