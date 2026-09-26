# UART Receiver RTL Design & Functional Verification

## Overview

This project implements and verifies an **8-bit UART receiver** using Verilog RTL and structured SystemVerilog/UVM verification methodologies.

The UART receiver supports the standard **8N1 UART configuration**:

- 8 data bits
- No parity bit
- 1 stop bit
- LSB-first transmission
- Active-LOW start bit
- HIGH stop bit

The RTL design uses a **finite state machine (FSM)** and a configurable clock-cycle counter to receive and sample UART data at the appropriate time.

The verification environment was developed and executed using **Verilator on Ubuntu/Linux**.

---

## Design Features

The UART receiver includes:

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
Idle    Start    D0 D1 D2 D3 D4 D5 D6 D7    Stop    Idle
  1       0       LSB          Data Bits       1       1
```

Each UART frame contains:

```text
1 Start Bit + 8 Data Bits + 1 Stop Bit
```

The data is transmitted **least-significant bit first**.

---

## Receiver FSM

The RTL receiver uses the following FSM states:

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

The project contains two verification environments:

1. Conventional SystemVerilog verification environment
2. UVM-based verification environment

The original SystemVerilog environment was preserved while a structured UVM environment was added for transaction-level verification.

---

# Conventional SystemVerilog Verification Environment

The original verification environment is located in:

```text
tb/
```

## Verification Components

| File | Responsibility |
|---|---|
| `uart_rx_tb.sv` | Top-level testbench that coordinates verification |
| `uart_driver.sv` | Generates UART stimulus and transmits test frames |
| `uart_monitor.sv` | Observes DUT outputs and records received transactions |
| `uart_scoreboard.sv` | Compares expected and actual received data |
| `uart_coverage.sv` | Tracks functional verification scenarios |
| `uart_assertions.sv` | Checks important DUT behavior |

The conventional testbench includes directed tests, randomized transactions, negative tests, and corner-case scenarios.

## Conventional Verification Scenarios

The verification environment includes:

- Reset behavior
- Directed UART data-pattern tests
- Randomized 8-bit UART transactions
- Invalid stop-bit test
- False start-bit test
- Back-to-back UART frame test
- Scoreboard-based data comparison
- Functional coverage tracking
- Assertion checks for important DUT behavior

---

# UVM-Based Verification Environment

The UVM verification environment is located in:

```text
uvm_tb/
```

The UVM environment follows a structured transaction-level verification architecture.

## UVM Architecture

```text
                         uart_test
                            |
                            v
                         uart_env
                            |
             +--------------+--------------+
             |                             |
             v                             v
         uart_agent                   uart_scoreboard
             |
       +-----+-----+
       |     |     |
       v     v     v
  sequencer driver monitor
       |      |       |
       |      |       +------> Actual Transactions
       |      |
       |      +--------------> UART RX Stimulus
       |
       +---------------------> Sequence Items
```

---

## UVM Components

| File | Component | Responsibility |
|---|---|---|
| `tb.sv` | Top-level UVM testbench | Instantiates DUT, interface, clock/reset and starts UVM |
| `uart_if.sv` | Virtual interface | Connects UVM components to DUT signals |
| `uart_sequence_item.sv` | Transaction | Represents a UART transaction |
| `uart_sequence.sv` | Sequence | Generates directed, randomized and negative transactions |
| `uart_sequencer.sv` | Sequencer | Sends sequence items to the driver |
| `uart_driver.sv` | Driver | Converts transactions into UART serial stimulus |
| `uart_monitor.sv` | Monitor | Observes DUT outputs and creates actual transactions |
| `uart_scoreboard.sv` | Scoreboard | Compares expected and actual DUT behavior |
| `uart_coverage.sv` | Coverage | Tracks functional coverage |
| `uart_agent.sv` | Agent | Groups sequencer, driver and monitor |
| `uart_env.sv` | Environment | Instantiates and connects UVM verification components |
| `uart_test.sv` | Test | Creates the environment and starts the UART sequence |

---

# UVM Transaction Types

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
```

The received data must match the transmitted data.

### Invalid Stop-Bit Transaction

The stop bit is intentionally driven LOW.

Expected behavior:

```text
rx_valid      = 0
framing_error = 1
```

### False Start Transaction

A short LOW pulse is applied to simulate a false start condition.

Expected behavior:

```text
No rx_valid response
No framing_error response
```

The receiver must reject the false start and return to the idle state.

---

# UVM Sequence

The UART sequence contains:

- Directed normal transactions
- Randomized normal transactions
- Invalid stop-bit test
- False start-bit test
- Back-to-back normal transactions

The current sequence generates:

```text
4 directed normal transactions
10 randomized normal transactions
1 invalid stop-bit transaction
1 false-start transaction
4 additional normal transactions
```

Total:

```text
20 transactions
```

Of these:

```text
18 valid UART receptions
2 negative-test transactions
```

---

# UVM Driver

The UVM driver converts sequence items into serial UART waveforms.

For a normal UART transaction, the driver generates:

```text
Idle
Start Bit
8 Data Bits
Stop Bit
```

The data bits are transmitted LSB-first.

The configured simulation bit period is:

```text
CLKS_PER_BIT × CLOCK_PERIOD
```

With the current configuration:

```text
CLKS_PER_BIT  = 217
CLOCK_PERIOD  = 40 ns
```

Therefore:

```text
Bit Period = 217 × 40 ns
           = 8680 ns
```

---

# UVM Monitor

The monitor observes the DUT outputs through the virtual interface.

It creates a transaction when:

```text
rx_valid
```

or

```text
framing_error
```

is asserted.

The monitor captures:

- Received data
- `rx_valid`
- `framing_error`

These actual transactions are sent to the scoreboard and functional coverage component.

---

# UVM Scoreboard

The scoreboard performs self-checking verification by comparing expected and actual transactions.

The expected transactions are provided by the UVM driver through an analysis port.

The actual transactions are provided by the UVM monitor.

The scoreboard uses separate analysis FIFOs for expected and actual transactions.

```text
UART Driver
     |
     | expected_port
     v
expected_fifo
     |
     v
UART Scoreboard
     ^
     |
actual_fifo
     ^
     |
UART Monitor
```

The scoreboard checks:

### Normal Transaction

```text
Expected rx_valid      = 1
Expected framing_error = 0
Expected data          = transmitted data
```

### Invalid Stop-Bit Transaction

```text
Expected rx_valid      = 0
Expected framing_error = 1
```

### False Start Transaction

```text
Expected:
No rx_valid
No framing_error
```

---

# Functional Coverage

The UVM environment includes functional coverage for UART data patterns and received transactions.

The verification environment currently achieves:

```text
UART Functional Coverage = 100.00%
```

Coverage is sampled from valid received transactions observed by the monitor.

---

# Verification Results

The latest UVM regression completed successfully with:

| Metric | Result |
|---|---:|
| Total transactions | 20 |
| Valid UART transactions | 18 |
| Negative-test transactions | 2 |
| Scoreboard checks | 20 |
| Scoreboard failures | 0 |
| Functional coverage | 100.00% |
| UVM errors | 0 |
| UVM fatal errors | 0 |

Example scoreboard results include:

```text
PASS: NORMAL
PASS: INVALID_STOP
PASS: FALSE_START
```

The invalid stop-bit test correctly detected:

```text
framing_error = 1
rx_valid      = 0
```

The false-start test correctly detected no DUT transaction.

---

# Negative Tests

## Invalid Stop-Bit Test

A complete UART frame is transmitted with the stop bit intentionally driven LOW.

Expected behavior:

```text
rx_valid      = 0
framing_error = 1
```

The UVM scoreboard explicitly checks the DUT response.

---

## False Start-Bit Test

A short LOW pulse is applied to the RX line to simulate a false start condition.

Expected behavior:

```text
The receiver rejects the false start
No rx_valid response
No framing_error response
```

The scoreboard uses a bounded observation window to verify that the DUT does not generate an unexpected transaction.

---

# Back-to-Back Frame Test

Two or more UART frames are transmitted consecutively without an additional idle gap.

The test verifies that the receiver:

- Correctly detects consecutive frames
- Correctly receives each data byte
- Returns to the correct idle state
- Does not lose frame boundaries

The current UVM sequence includes four consecutive normal transactions:

```text
0x3C
0xC3
0x96
0x69
```

---

# Simulation Configuration

The current simulation uses:

```text
CLKS_PER_BIT   = 217
CLOCK_PERIOD   = 40 ns
BIT_PERIOD     = 8680 ns
```

The verification environment uses:

```text
Verilator
SystemVerilog
UVM
Ubuntu/Linux
```

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

# Compilation Using Verilator

## Conventional SystemVerilog Testbench

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

Run the simulation:

```bash
./sim/obj_dir/Vuart_rx_tb
```

---

# UVM Compilation

The UVM environment can be compiled using:

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

Run the UVM simulation:

```bash
./sim/uvm_obj_dir/Vtb
```

To save the simulation output:

```bash
./sim/uvm_obj_dir/Vtb 2>&1 | tee sim/uvm_run.log
```

---

# Waveform Viewing

The simulation can generate a VCD waveform for signal-level analysis.

To open the waveform using GTKWave:

```bash
gtkwave waves/dump.vcd
```

The waveform can be used to inspect:

- Clock
- Reset
- UART RX signal
- Received data
- `rx_valid`
- `framing_error`
- UART frame timing
- FSM behavior

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
│   ├── tb.sv
│   ├── uart_if.sv
│   ├── uart_sequence_item.sv
│   ├── uart_sequence.sv
│   ├── uart_sequencer.sv
│   ├── uart_driver.sv
│   ├── uart_monitor.sv
│   ├── uart_scoreboard.sv
│   ├── uart_coverage.sv
│   ├── uart_agent.sv
│   ├── uart_env.sv
│   └── uart_test.sv
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

Generated Verilator build files and simulation outputs are excluded from version control using `.gitignore`.

---

# Git and GitHub

The project is maintained using Git and hosted on GitHub.

Typical workflow:

```bash
git status
git add <file>
git commit -m "Commit message"
git push origin main
```

Generated simulation files such as Verilator build directories and VCD files are excluded from Git using `.gitignore`.

---

# Future Scope

Potential extensions to the project include:

- UART baud-rate variation testing
- Protocol corner-case testing
- Parameterized data width
- Parameterized stop-bit configuration
- Additional UVM sequences and regression tests
- Expanded functional coverage
- Constraint-based randomized testing
- Lint analysis
- RTL synthesis
- Static timing analysis
- Gate-level simulation
- FPGA implementation
- ASIC RTL-to-GDSII flow

---

# Conclusion

This project demonstrates the design and verification of an **8-bit UART receiver** using RTL design principles and structured verification methodologies.

The project includes both a conventional SystemVerilog verification environment and a UVM-based environment, demonstrating:

- Transaction-level verification
- Reusable verification components
- Sequence-driven stimulus generation
- Self-checking scoreboard-based verification
- Functional coverage
- Negative testing
- Protocol validation
- Error detection
- Structured UVM architecture

The latest UVM regression successfully completed with:

```text
20 total transactions
20 scoreboard checks passed
0 scoreboard failures
100% functional coverage
0 UVM errors
0 UVM fatal errors
```

The project provides a foundation for extending the UART receiver verification environment toward more advanced RTL verification, synthesis, timing analysis, FPGA implementation, and ASIC design flows.
