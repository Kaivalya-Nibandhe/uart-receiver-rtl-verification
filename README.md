# UART Receiver RTL Design & Functional Verification

## Overview

This project implements and verifies an **8-bit UART receiver** using Verilog RTL and structured SystemVerilog verification environments.

The UART receiver supports the standard **8N1 UART configuration**:

- 8 data bits
- No parity bit
- 1 stop bit
- LSB-first transmission
- Active-LOW start bit
- HIGH stop bit

The design uses a finite state machine (FSM) and a configurable clock-cycle counter to receive and sample UART data at the appropriate time.

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
- Safe recovery to the idle state
- Support for consecutive UART frames

---

## UART Frame Format

The receiver supports the following UART frame format:

```text
Idle   Start   D0   D1   D2   D3   D4   D5   D6   D7   Stop   Idle
 1       0    LSB                         Data Bits          1      1

Each frame contains:

1 Start Bit + 8 Data Bits + 1 Stop Bit

The data is transmitted least-significant bit first.

UART Configuration
Parameter	Configuration
Data bits	8
Parity	None
Stop bits	1
Start bit	LOW
Stop bit	HIGH
Data order	LSB first
Receiver FSM

The RTL receiver uses the following states:

State	Description
STATE_IDLE	Waits for the UART RX line to go LOW
STATE_START	Validates the start bit near the middle of the bit period
STATE_DATA	Samples the eight data bits
STATE_STOP	Checks whether the stop bit is HIGH
STATE_CLEANUP	Clears status signals and returns to idle
Output Signals
Signal	Description
rx	Serial UART input
rx_data[7:0]	Received 8-bit data
rx_valid	Indicates successful reception of a complete frame
framing_error	Indicates that the received stop bit was LOW
clk	System clock
rst	Active-HIGH reset
RTL Design

The main RTL source file is:

rtl/uart_rx.v

The receiver uses a configurable clock-cycle counter to determine when UART bits should be sampled.

Simulation Configuration

The current simulation uses:

CLKS_PER_BIT = 217
CLOCK_PERIOD = 40 ns

Therefore, the simulated UART bit period is:

217 × 40 ns = 8680 ns

The UART timing is controlled using simulation delays in the verification driver.

Verification Environment

The project contains two verification environments:

Conventional SystemVerilog verification environment
UVM-based verification environment

The original environment is retained in the tb/ directory, while the UVM environment is located in uvm_tb/.

This allows the project to demonstrate both modular SystemVerilog verification and a structured UVM verification methodology.

Conventional SystemVerilog Verification Environment

The original verification environment is located in:

tb/
Verification Components
File	Responsibility
uart_rx_tb.sv	Top-level testbench that coordinates verification
uart_driver.sv	Generates UART stimulus and transmits test frames
uart_monitor.sv	Observes DUT outputs and records received transactions
uart_scoreboard.sv	Compares expected and actual received data
uart_coverage.sv	Tracks functional verification scenarios
uart_assertions.sv	Checks important DUT behavior

The conventional testbench includes directed tests, randomized transactions, negative tests, corner-case scenarios, scoreboard checking, functional coverage, and assertions.

Conventional Verification Scenarios

The verification environment includes:

Reset behavior
Directed UART data-pattern tests
Randomized 8-bit UART transactions
Invalid stop-bit test
False start-bit test
Back-to-back UART frame test
Scoreboard-based data comparison
Functional coverage tracking
Assertion checks for important DUT behavior
UVM-Based Verification Environment

A structured UVM-based verification environment was added to provide a reusable and scalable verification architecture for the UART receiver.

The UVM environment uses:

SystemVerilog
UVM
Verilator
Virtual interface
Sequence items
Sequences
Sequencer
Driver
Monitor
Agent
Scoreboard
Functional coverage
UVM environment
UVM test
UVM Architecture
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
      +-------+-------+
      |       |       |
      v       v       v
 sequencer  driver  monitor
              |        |
              |        +----------------------+
              |                               |
              v                               v
         UART RX line                    DUT outputs
                                              |
                                              v
                                        Scoreboard
UVM Components
Component	File	Responsibility
Interface	uart_if.sv	Connects the UVM testbench to the DUT
Sequence Item	uart_sequence_item.sv	Represents a UART transaction
Sequence	uart_sequence.sv	Generates directed, randomized, and negative-test transactions
Sequencer	uart_sequencer.sv	Supplies sequence items to the driver
Driver	uart_driver.sv	Converts transactions into UART serial stimulus
Monitor	uart_monitor.sv	Observes DUT outputs
Agent	uart_agent.sv	Contains sequencer, driver, and monitor
Scoreboard	uart_scoreboard.sv	Compares expected and actual DUT behavior
Coverage	uart_coverage.sv	Tracks functional verification coverage
Environment	uart_env.sv	Instantiates and connects verification components
Test	uart_test.sv	Controls the UVM test execution
Top Module	tb.sv	Instantiates the DUT, interface, and UVM test
UVM Sequence Item

The UVM sequence item represents an individual UART transaction.

Each transaction contains information for:

UART data
Frame type
rx_valid
framing_error

The sequence supports the following frame types:

UART_NORMAL
UART_INVALID_STOP
UART_FALSE_START
UVM Verification Sequence

The current UVM sequence generates 20 total transactions.

The transaction distribution is:

4  directed normal transactions
10 randomized normal transactions
1  invalid stop-bit transaction
1  false-start transaction
4  back-to-back normal transactions

Therefore:

Total transactions      = 20
Valid UART transactions = 18
Negative tests          = 2
Negative Tests
Invalid Stop-Bit Test

A complete UART frame is transmitted with the stop bit driven LOW instead of HIGH.

Expected behavior:

rx_valid      = 0
framing_error = 1

The UVM scoreboard explicitly checks that the DUT detects the framing error.

The test uses:

Data = 0xA5

Expected result:

PASS: INVALID_STOP
Framing error detected
rx_valid = 0
framing_error = 1
False Start-Bit Test

A short LOW pulse is applied to the RX line to simulate a false start condition.

Expected behavior:

No rx_valid response
No framing_error response

The UVM scoreboard verifies that the DUT does not generate an unexpected transaction.

Expected result:

PASS: FALSE_START
No rx_valid or framing_error response detected
Back-to-Back Frame Test

The verification environment also tests consecutive UART frames without an additional idle gap.

The current sequence includes the following back-to-back data values:

0x3C
0xC3
0x96
0x69

Expected behavior:

Both frames are received correctly.

The scoreboard verifies each received value against the corresponding expected transaction.

Scoreboard Verification

The UVM scoreboard uses separate analysis FIFOs for expected and actual transactions.

The verification flow is:

uart_driver
     |
     | expected transactions
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
     ^
     |
   DUT

The scoreboard checks:

Normal Transaction
Expected:
rx_valid      = 1
framing_error = 0
data          = expected data
Invalid Stop-Bit Transaction
Expected:
rx_valid      = 0
framing_error = 1
False Start
Expected:
No rx_valid event
No framing_error event
Functional Coverage

Functional coverage is collected by the UVM coverage component.

The verification environment tracks execution of the UART verification scenarios and data patterns.

The latest UVM regression achieves:

UART Functional Coverage = 100.00%
Current UVM Verification Results

The latest successful UVM simulation produced:

Total transactions       = 20
Valid transactions       = 18
Negative-test cases      = 2

Scoreboard PASS          = 20
Scoreboard FAIL          = 0
Scoreboard CHECKS        = 20

Functional Coverage      = 100.00%

UVM_ERROR                = 0
UVM_FATAL                = 0

The UVM simulation completed successfully using Verilator.

Tools and Technologies

The project uses:

Verilog
SystemVerilog
UVM
Finite State Machines
RTL Design
Functional Verification
Verilator
GTKWave
Ubuntu/Linux
Git
GitHub
Software Configuration

The project was developed and tested using:

Operating System : Ubuntu/Linux
Simulator        : Verilator 5.052
Verification     : UVM
Waveform Viewer  : GTKWave
Version Control  : Git/GitHub

The UVM environment uses the UVM_HOME environment variable to locate the UVM source.

Project Structure
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
│   ├── uart_agent.sv
│   ├── uart_scoreboard.sv
│   ├── uart_coverage.sv
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

The tb/ directory contains the original conventional SystemVerilog verification environment.

The uvm_tb/ directory contains the structured UVM verification environment.

Generated Verilator build files and simulation outputs are excluded from version control using .gitignore.
Compilation Using Verilator — Conventional Testbench

From the project root:

cd ~/vlsi_project/uart_receiver

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
    --top-module uart_rx_tb \
    --language 1800-2012 \
    --timing \
    -CFLAGS "-std=c++20" \
    --trace \
    -Mdir sim/obj_dir

After successful compilation:

./sim/obj_dir/Vuart_rx_tb

The conventional testbench prints:

Test status
Scoreboard comparisons
Coverage information
Assertion results
Compilation Using Verilator — UVM Testbench

The UVM environment requires the UVM package and UVM include directory.

From the project root:

cd ~/vlsi_project/uart_receiver

Remove the previous UVM build directory:

rm -rf sim/uvm_obj_dir

Compile using:

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
Running the UVM Simulation

After successful compilation:

./sim/uvm_obj_dir/Vtb

To save the simulation output to a log file:

./sim/uvm_obj_dir/Vtb 2>&1 | tee sim/uvm_run.log

The log contains:

UVM driver activity
Monitor observations
Scoreboard comparisons
Negative-test results
Functional coverage
UVM report summary
Waveform Viewing

The simulation can generate a VCD waveform file for signal-level analysis.

The waveform is stored in:

waves/dump.vcd

To open the waveform using GTKWave:

gtkwave waves/dump.vcd

Waveforms can be used to inspect:

clk
rst
rx
rx_data
rx_valid
framing_error
UART frame timing
FSM behavior
Git and GitHub

The project is maintained using Git and GitHub.

Check repository status:

git status

View the commit history:

git log --oneline

Add changes:

git add .

Commit changes:

git commit -m "Description of changes"

Push changes:

git push origin main
Reproducing the Project on Another Linux System

The repository is structured so that the RTL and verification source files can be transferred to another Linux system.

After cloning the repository:

git clone <repository-url>
cd uart_receiver

The RTL source is located at:

rtl/uart_rx.v

The conventional verification environment is located at:

tb/

The UVM verification environment is located at:

uvm_tb/

The generated sim/ build files do not need to be transferred because Verilator can regenerate them.

Waveform files also do not need to be transferred unless waveform analysis is required.

Verification Methodology

The project demonstrates a progression from a modular SystemVerilog testbench to a structured UVM environment.

The conventional environment follows the flow:

Driver
   |
   v
DUT
   |
   v
Monitor
   |
   v
Scoreboard

The UVM environment follows a transaction-level architecture:

Sequence
   |
   v
Sequencer
   |
   v
Driver
   |
   v
DUT
   |
   v
Monitor
   |
   v
Scoreboard

The UVM architecture separates:

Stimulus generation
Transaction management
DUT driving
DUT monitoring
Expected-versus-actual checking
Functional coverage

into dedicated reusable verification components.

Verification Summary

The UART receiver has been verified using directed, randomized, negative, and corner-case scenarios.

The verification environment covers:

UART frame reception
Multiple data patterns
Randomized data
Start-bit validation
Stop-bit validation
Framing-error detection
False-start rejection
Consecutive frame reception
Expected-versus-actual data checking
Functional coverage
Assertion-based checking
UVM-based transaction-level verification

Latest UVM regression result:

==================================================
              UART UVM REGRESSION
==================================================

Total Transactions       : 20
Valid Transactions       : 18
Negative Tests           : 2

Scoreboard PASS          : 20
Scoreboard FAIL          : 0
Scoreboard CHECKS        : 20

Functional Coverage      : 100.00%

UVM_ERROR                : 0
UVM_FATAL                : 0

==================================================
                 VERIFICATION PASS
==================================================
Future Scope

The current project focuses on RTL design and functional verification.

Possible future extensions include:

SystemVerilog Assertions expansion
Additional constrained-random testing
More extensive functional coverage
Protocol corner-case testing
UART baud-rate variation
Parameterized data width
Parameterized stop-bit configuration
Lint analysis
RTL synthesis
Static timing analysis
Gate-level simulation
ASIC RTL-to-GDSII flow
FPGA implementation
Formal verification
Additional UVM sequences and regression tests
Conclusion

This project demonstrates the design and verification of an 8-bit UART receiver using RTL design principles and structured verification methodologies.

The project includes both a conventional SystemVerilog verification environment and a UVM-based environment, demonstrating transaction-level verification, reusable verification components, scoreboard-based checking, functional coverage, and negative testing.

The latest UVM regression successfully completed:

20 total transactions
20 scoreboard checks passed
0 scoreboard failures
100% functional coverage
0 UVM errors
0 UVM fatal errors

The project is developed using:

Verilog
SystemVerilog
UVM
Verilator
GTKWave
Ubuntu/Linux
Git
GitHub
