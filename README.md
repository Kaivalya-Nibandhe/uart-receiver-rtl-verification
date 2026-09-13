# UART Receiver RTL Design & Functional Verification

## 1. Project Overview

This project implements and verifies an **8-bit UART receiver** using Verilog RTL and SystemVerilog-based verification components.

The receiver follows the **UART 8N1 protocol**:

* 8 data bits
* No parity bit
* 1 stop bit
* Least Significant Bit transmitted first
* Idle line is logic HIGH
* Start bit is logic LOW

The design is verified using **Verilator** through directed testing, randomized testing, negative testing, functional coverage, assertions, monitoring, and scoreboard-based checking.

---

## 2. Project Objectives

The main objectives of this project are to:

* Design an 8-bit UART receiver using Verilog RTL.
* Implement UART protocol control using a finite state machine.
* Support configurable baud-rate timing through a clock-cycle parameter.
* Develop a structured SystemVerilog verification environment.
* Verify correct reception of different UART data patterns.
* Detect invalid start and stop bits.
* Verify back-to-back UART frame reception.
* Implement functional coverage tracking.
* Use a scoreboard to compare expected and actual received data.
* Use assertions to check important protocol and output properties.
* Analyze simulation waveforms using VCD output.

---

## 3. UART Receiver Features

The UART receiver includes the following features:

* FSM-based UART reception.
* Parameterized clock cycles per UART bit.
* Start-bit detection and validation.
* Serial-to-parallel conversion.
* LSB-first data sampling.
* Stop-bit validation.
* `rx_valid` pulse generation after a valid frame.
* Reset support.
* Rejection of invalid stop-bit frames.
* Support for consecutive UART frames.

---

## 4. UART Protocol

The implemented UART frame uses the following format:

```text
Idle      Start       Data Bits                  Stop       Idle
 HIGH       LOW     D0 D1 D2 D3 D4 D5 D6 D7        HIGH      HIGH
```

For an 8N1 UART frame:

```text
| Start Bit | 8 Data Bits, LSB First | Stop Bit |
|    0      |       D0 ... D7        |     1    |
```

The receiver waits for the falling edge of the start bit, samples the data bits at the configured timing interval, and checks that the stop bit is logic HIGH.

---

## 5. Project Directory Structure

```text
uart_receiver/
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
├── docs/
│
└── README.md
```

### Directory Description

| Directory/File | Description                                    |
| -------------- | ---------------------------------------------- |
| `rtl/`         | Contains the UART receiver RTL design          |
| `tb/`          | Contains the complete verification environment |
| `sim/`         | Contains generated Verilator simulation files  |
| `waves/`       | Contains generated VCD waveform files          |
| `docs/`        | Contains additional project documentation      |
| `README.md`    | Project overview and simulation instructions   |

---

## 6. Design File

### `rtl/uart_rx.v`

This file contains the UART receiver RTL implementation.

The receiver uses an FSM with the following states:

```text
IDLE → START → DATA → STOP → CLEANUP
```

### FSM State Description

| State     | Function                                           |
| --------- | -------------------------------------------------- |
| `IDLE`    | Waits for the beginning of a start bit             |
| `START`   | Validates the start bit                            |
| `DATA`    | Samples and stores the eight data bits             |
| `STOP`    | Checks whether the stop bit is valid               |
| `CLEANUP` | Deasserts `rx_valid` and returns to idle operation |

---

## 7. Verification Environment

The verification environment is divided into multiple components.

### 7.1 UART Driver

**File:** `tb/uart_driver.sv`

The driver generates UART serial stimulus for the DUT.

It supports:

* Directed data transmission.
* Randomized data transmission.
* Invalid stop-bit testing.
* False start-bit testing.
* Back-to-back UART frame transmission.

The driver converts parallel 8-bit data into a serial UART waveform.

---

### 7.2 UART Monitor

**File:** `tb/uart_monitor.sv`

The monitor observes the DUT outputs.

It:

* Waits for a rising edge of `rx_valid`.
* Captures the received `rx_data`.
* Maintains the most recently received data value.
* Stores the previously received data value.
* Counts successfully received transactions.

The monitor allows the testbench to observe DUT behavior independently of the driver.

---

### 7.3 UART Scoreboard

**File:** `tb/uart_scoreboard.sv`

The scoreboard compares the expected transmitted data with the actual received data.

It records:

* Number of passed comparisons.
* Number of failed comparisons.
* Overall scoreboard status.

A transaction passes when the expected and actual 8-bit values match.

---

### 7.4 Functional Coverage

**File:** `tb/uart_coverage.sv`

The coverage component tracks whether important data patterns and bit values have been exercised.

The coverage model includes:

#### Data Pattern Bins

* `8'h00`
* `8'hFF`
* `8'hAA`
* `8'h55`
* Values with only the least significant bit set
* Values with only the most significant bit set
* Values with both edge bits set
* Values with middle bits set
* Other data values

#### Individual Bit Coverage

For each of the eight data bits, the coverage model tracks:

* Whether the bit has been observed as `0`
* Whether the bit has been observed as `1`

The coverage report displays the number of covered bins and the calculated coverage percentage.

---

### 7.5 Assertions

**File:** `tb/uart_assertions.sv`

The assertion module checks important output properties.

The current assertions check that:

1. `rx_valid` does not remain HIGH for two consecutive clock cycles.
2. `rx_valid` remains LOW during reset.
3. `rx_data` remains stable while `rx_valid` is HIGH.

The assertion module is instantiated in the testbench and is compiled along with the other verification files.

---

## 8. Test Scenarios

The testbench executes the following scenarios.

### 8.1 Directed Transactions

The following data patterns are explicitly tested:

```text
0x00
0xFF
0xAA
0x55
0x01
0x80
0x81
0x7E
```

These patterns test:

* All-zero data.
* All-one data.
* Alternating bit patterns.
* Least Significant Bit behavior.
* Most Significant Bit behavior.
* Edge-bit combinations.
* Middle-bit activity.

---

### 8.2 Randomized Transactions

Additional transactions use randomized 8-bit data values.

This increases the variety of data patterns tested and helps identify unexpected RTL behavior.

---

### 8.3 Invalid Stop-Bit Test

The driver transmits a frame with an invalid stop bit.

Expected behavior:

```text
The DUT must reject the frame.
rx_valid must not be asserted.
```

---

### 8.4 False Start-Bit Test

The driver briefly drives the RX line LOW and then returns it HIGH before a valid start bit can be completed.

Expected behavior:

```text
The DUT must reject the false start condition.
No valid transaction should be reported.
```

---

### 8.5 Back-to-Back Frame Test

Two UART frames are transmitted consecutively without an extended idle interval between them.

Expected behavior:

* Both frames must be received.
* Both data values must match the transmitted values.
* The monitor transaction count must increase by two.

---

## 9. Simulation Parameters

The current testbench uses the following parameters:

| Parameter             |       Value |
| --------------------- | ----------: |
| Clock period          |       40 ns |
| Clock frequency       |      25 MHz |
| Clock cycles per bit  |         217 |
| UART bit period       |     8680 ns |
| Approximate baud rate | 115200 baud |
| UART data width       |      8 bits |
| Stop bits             |           1 |
| Parity                |        None |

The UART bit period is calculated as:

```text
BIT_PERIOD = CLKS_PER_BIT × CLOCK_PERIOD_NS
```

Therefore:

```text
BIT_PERIOD = 217 × 40 ns
           = 8680 ns
```

---

## 10. Software Requirements

The project requires:

* Verilator
* A C++ compiler supporting C++20
* Linux terminal or compatible shell environment

The simulation uses Verilator timing support and VCD waveform tracing.

---

## 11. Compilation Instructions

From the project root directory, run:

```bash
rm -rf sim/obj_dir
```

Compile the RTL and verification files:

```bash
verilator --binary -j 0 -Wall \
rtl/uart_rx.v \
tb/uart_driver.sv \
tb/uart_monitor.sv \
tb/uart_coverage.sv \
tb/uart_assertions.sv \
tb/uart_scoreboard.sv \
tb/uart_rx_tb.sv \
--top uart_rx_tb \
--timing \
-CFLAGS "-std=c++20" \
--trace \
-Mdir sim/obj_dir
```

---

## 12. Running the Simulation

Run the generated executable:

```bash
./sim/obj_dir/Vuart_rx_tb
```

The simulation prints:

* Transmitted data.
* Monitored received data.
* Scoreboard comparison results.
* Negative-test results.
* Assertion failures, if any.
* Functional coverage results.
* Final scoreboard status.

---

## 13. Waveform Analysis

The testbench generates a VCD waveform file using:

```systemverilog
$dumpfile("dump.vcd");
$dumpvars(0, uart_rx_tb);
```

If the VCD file is generated in the project root, move it into the waveform directory:

```bash
mv dump.vcd waves/
```

The waveform can be viewed using a waveform viewer such as GTKWave:

```bash
gtkwave waves/dump.vcd
```

Important signals to inspect include:

* `clk`
* `rst`
* `rx`
* `rx_data`
* `rx_valid`
* DUT FSM state
* Bit counter
* Clock counter

---

## 14. Expected Results

A successful simulation should show:

* Correct reception of directed data patterns.
* Correct reception of randomized data.
* Passing scoreboard comparisons.
* Rejection of invalid stop-bit frames.
* Rejection of false start-bit conditions.
* Correct reception of back-to-back frames.
* No assertion failures.
* A passing final scoreboard status.

The final scoreboard should report:

```text
SCOREBOARD STATUS = PASS
```

---

## 15. Verification Summary

The project verifies the UART receiver at the functional RTL level using:

* Directed testing
* Randomized testing
* Negative testing
* Back-to-back frame testing
* Functional coverage
* Output monitoring
* Scoreboard-based data checking
* SystemVerilog assertions
* VCD waveform analysis

This project demonstrates the basic RTL-to-verification workflow used in digital design and VLSI verification.

---

## 16. Future Improvements

Possible future enhancements include:

* Adding configurable data width.
* Adding configurable parity support.
* Supporting one or two stop bits.
* Adding baud-rate tolerance testing.
* Testing clock-frequency variation.
* Adding error flags for framing errors.
* Adding timeout detection.
* Adding a more advanced constrained-random testbench.
* Migrating the environment to a UVM-based structure.
* Adding automated regression scripts.
* Generating machine-readable test reports.
* Adding code coverage and assertion coverage.
