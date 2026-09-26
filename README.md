# UART Receiver RTL Design & Functional Verification

## Overview

This project implements and verifies an **8-bit UART receiver** using Verilog RTL and SystemVerilog-based verification.

The project includes both:

1. A modular SystemVerilog verification environment
2. A UVM-based verification environment

The design supports the standard **8N1 UART configuration**:

- 8 data bits
- No parity bit
- 1 stop bit
- LSB-first transmission
- Active-LOW start bit
- HIGH stop bit

The RTL receiver uses a finite state machine (FSM) and configurable clock-cycle counting to sample UART data at the appropriate time.

The verification environment was developed and executed using **Verilator on Ubuntu/Linux**.

---

## Design Features

- 8-bit UART receiver
- FSM-based receiver control
- Parameterized baud-rate timing
- Configurable `CLKS_PER_BIT` parameter
- Start-bit validation
- LSB-first data reception
- Stop-bit validation
- `rx_valid` indication after successful frame reception
- `framing_error` indication for an invalid stop bit
- Safe recovery to the IDLE state
- Support for consecutive UART frames

---

## UART Frame Format

The receiver supports the following UART frame format:

```text
Idle   Start   D0  D1  D2  D3  D4  D5  D6  D7   Stop   Idle
 1       0     LSB                 Data Bits        1      1
```

Each valid UART frame contains:

```text
1 Start Bit + 8 Data Bits + 1 Stop Bit
```

The data is transmitted **least-significant bit first**.

---

## Receiver FSM

The RTL receiver uses the following states:

| State | Description |
|---|---|
| `STATE_IDLE` | Waits for the UART RX line to go LOW |
| `STATE_START` | Validates the start bit near the middle of the bit period |
| `STATE_DATA` | Samples the eight data bits |
| `STATE_STOP` | Checks whether the stop bit is HIGH |
| `STATE_CLEANUP` | Clears status signals and returns to IDLE |

---

## Output Signals

| Signal | Description |
|---|---|
| `rx` | Serial UART input |
| `rx_data[7:0]` | Received 8-bit data |
| `rx_valid` | Indicates successful reception of a complete frame |
| `framing_error` | Indicates that the received stop bit was LOW |
| `clk` | System clock |
| `rst` | Active-HIGH reset |

---

# Verification Environment

The project contains two verification approaches.

## 1. Conventional SystemVerilog Verification

The original verification environment is a modular, self-checking SystemVerilog testbench.

### Components

| File | Responsibility |
|---|---|
| `uart_driver.sv` | Generates UART stimulus and transmits test frames |
| `uart_monitor.sv` | Observes DUT outputs and records received transactions |
| `uart_scoreboard.sv` | Compares expected and actual received data |
| `uart_coverage.sv` | Tracks verification scenarios and functional coverage |
| `uart_assertions.sv` | Checks important DUT behavior |
| `uart_rx_tb.sv` | Top-level conventional testbench |

The conventional environment includes:

- Reset behavior
- Directed UART data-pattern tests
- Randomized 8-bit UART transactions
- Invalid stop-bit test
- False start-bit test
- Back-to-back UART frames
- Scoreboard-based data comparison
- Functional coverage
- Assertion checks
- Waveform generation

---

# 2. UVM Verification Environment

A UVM-based verification environment was developed from the conventional testbench.

The UVM environment follows the standard layered structure:

```text
                         uart_test
                             |
                             v
                       uart_sequence
                             |
                             v
                       uart_sequencer
                             |
                             v
                       +-------------+
                       | uart_agent  |
                       +-------------+
                        /     |      \
                       /      |       \
                      v       v        v
                 sequencer  driver   monitor
                              |         |
                              |         |
                              v         v
                             DUT    scoreboard
                                       |
                                       v
                                    coverage
```

## UVM Components

| File | Responsibility |
|---|---|
| `uart_if.sv` | Virtual interface connecting UVM components to the DUT |
| `uart_sequence_item.sv` | Defines UART transactions |
| `uart_sequence.sv` | Generates directed, randomized, and negative transactions |
| `uart_sequencer.sv` | Sends sequence items to the driver |
| `uart_driver.sv` | Converts transactions into UART serial stimulus |
| `uart_monitor.sv` | Observes DUT outputs and creates transactions |
| `uart_agent.sv` | Contains sequencer, driver, and monitor |
| `uart_scoreboard.sv` | Compares expected and actual DUT behavior |
| `uart_coverage.sv` | Measures functional coverage |
| `uart_env.sv` | Instantiates and connects the verification components |
| `uart_test.sv` | Controls the UVM test and sequence execution |
| `tb.sv` | UVM top-level testbench and DUT/interface connection |

---

## UVM Transaction Types

The UVM sequence supports three transaction types:

```text
UART_NORMAL
UART_INVALID_STOP
UART_FALSE_START
```

### Normal Transaction

Expected behavior:

```text
rx_valid      = 1
framing_error = 0
rx_data       = expected data
```

### Invalid Stop-Bit Transaction

The stop bit is intentionally driven LOW.

Expected behavior:

```text
rx_valid      = 0
framing_error = 1
```

### False Start Transaction

A short LOW pulse is applied to the RX line to simulate a false start condition.

Expected behavior:

```text
No rx_valid response
No framing_error response
```

---

# Verification Plan

The UVM sequence contains:

| Test Category | Number |
|---|---:|
| Directed normal transactions | 4 |
| Randomized normal transactions | 10 |
| Invalid stop-bit test | 1 |
| False-start test | 1 |
| Back-to-back normal transactions | 4 |
| **Total transactions** | **20** |

Of the 20 transactions:

```text
18 → expected valid UART receptions
 1 → invalid stop-bit negative test
 1 → false-start negative test
```

---

# Scoreboard Verification

The UVM scoreboard uses separate analysis FIFOs for expected and actual transactions.

```text
uart_driver
     |
     | expected_port
     v
expected_fifo
     |
     v
uart_scoreboard
     ^
     |
actual_fifo
     ^
     |
uart_monitor
```

The scoreboard verifies:

### Normal frames

- Received data matches expected data
- `rx_valid` is asserted
- `framing_error` remains deasserted

### Invalid stop-bit frame

- `framing_error` is asserted
- `rx_valid` remains deasserted

### False start

- No unexpected DUT transaction is generated

---

# Verification Results

The completed UVM environment was compiled and simulated using Verilator.

Final verification results:

```text
Normal transactions       : 18 PASS
Invalid stop-bit test     : 1 PASS
False-start test          : 1 PASS
-------------------------------------
Total scoreboard checks   : 20
Scoreboard failures       : 0
```

### Final Scoreboard

```text
Scoreboard Summary:
PASS = 20
FAIL = 0
CHECKS = 20
```

### Functional Coverage

```text
UART Functional Coverage = 100.00%
```

### UVM Status

```text
UVM_ERROR = 0
UVM_FATAL = 0
```

The false-start test intentionally produces no monitor transaction, resulting in:

```text
20 scoreboard checks
19 monitor transactions
```

This is expected because the false-start case is specifically verified by checking for the absence of a DUT response.

---

# Simulation Configuration

The current simulation uses:

```text
CLKS_PER_BIT   = 217
CLOCK_PERIOD   = 40 ns
```

Therefore:

```text
UART bit period = 217 × 40 ns
                = 8680 ns
```

The UART timing is controlled using simulation delays in the testbench driver.

---

# Tools and Technologies

- Verilog
- SystemVerilog
- UVM
- RTL Design
- Finite State Machines
- Functional Verification
- Functional Coverage
- Verilator
- GTKWave
- Ubuntu/Linux
- Git
- GitHub

---

# Verilator Setup

The project was developed using Verilator.

Check the installed version with:

```bash
verilator --version
```

The project was verified using:

```text
Verilator 5.052
```

---

# Conventional Testbench Compilation

From the project root:

```bash
cd ~/vlsi_project/uart_receiver

rm -rf sim/obj_dir

verilator --binary --timing --trace \
    -Wno-ZERODLY \
    --top-module uart_rx_tb \
    --Mdir sim/obj_dir \
    rtl/uart_rx.v \
    tb/uart_driver.sv \
    tb/uart_monitor.sv \
    tb/uart_scoreboard.sv \
    tb/uart_coverage.sv \
    tb/uart_assertions.sv \
    tb/uart_rx_tb.sv
```

Run the conventional testbench:

```bash
./sim/obj_dir/Vuart_rx_tb
```

---

# UVM Setup

The UVM environment uses the Verilator-compatible UVM implementation.

The environment variable should point to the UVM source:

```bash
echo $UVM_HOME
```

Expected:

```text
/home/<user>/uvm-verilator
```

The UVM source is compiled through:

```text
$UVM_HOME/src/uvm_pkg.sv
```

---

# UVM Compilation

From the project root:

```bash
cd ~/vlsi_project/uart_receiver

rm -rf sim/uvm_obj_dir

verilator --binary --timing \
    -j 4 \
    --coverage \
    -Wno-fatal \
    -Wno-TIMESCALEMOD \
    -Wno-ZERODLY \
    +incdir+$UVM_HOME/src \
    +incdir+uvm_tb \
    +define+UVM_NO_DPI \
    $UVM_HOME/src/uvm_pkg.sv \
    rtl/uart_rx.v \
    uvm_tb/tb.sv \
    --top-module tb \
    --Mdir sim/uvm_obj_dir
```

---

# Running the UVM Simulation

After successful compilation:

```bash
./sim/uvm_obj_dir/Vtb
```

To save the simulation output:

```bash
./sim/uvm_obj_dir/Vtb 2>&1 | tee sim/uvm_run.log
```

To quickly inspect the final verification result:

```bash
grep -E "PASS:|FAIL:|Scoreboard Summary|Completed UART sequence|Functional Coverage|UVM_ERROR|UVM_FATAL" sim/uvm_run.log
```

---

# Waveform Viewing

The conventional testbench can generate a VCD waveform for signal-level analysis.

The waveform is stored in:

```text
waves/dump.vcd
```

Open it using GTKWave:

```bash
gtkwave waves/dump.vcd
```

---

# Project Structure

```text
uart_receiver/
│
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
├── uvm_tb/
│   ├── uart_if.sv
│   ├── uart_sequence_item.sv
│   ├── uart_sequence.sv
│   ├── uart_sequencer.sv
│   ├── uart_driver.sv
│   ├── uart_monitor.sv
│   ├── uart_agent.sv
│   ├── uart_scoreboard.sv
│   ├── uart_coverage.sv
│   ├── uart_env.sv
│   ├── uart_test.sv
│   └── tb.sv
│
├── sim/
│   ├── obj_dir/
│   └── uvm_obj_dir/
│
├── waves/
│   └── dump.vcd
│
└── docs/
```

Generated simulation files under `sim/` and waveform files under `waves/` should generally not be committed to the Git repository unless intentionally required.

---

# Verification Summary

The project demonstrates an RTL-to-verification workflow for an 8-bit UART receiver:

```text
UART RTL Design
       |
       v
Conventional SystemVerilog Verification
       |
       v
Directed + Randomized + Negative Testing
       |
       v
Scoreboard + Functional Coverage + Assertions
       |
       v
UVM-Based Verification Environment
       |
       v
20 Scoreboard Checks
       |
       v
20 PASS / 0 FAIL
       |
       v
100% Functional Coverage
```

The UVM environment verifies both expected successful UART reception and error-handling behavior, including invalid stop-bit detection and rejection of false start conditions.
