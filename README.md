# Verilog UART Transmitter and Receiver

A UART-style serial communication system implemented in Verilog HDL. The project consists of an FSM-based transmitter (`uart_tx`), receiver (`uart_rx`), top-level integration module (`uart_top`), and a self-checking testbench for end-to-end loopback verification.

The design demonstrates hierarchical RTL integration by connecting the serial output of the transmitter directly to the serial input of the receiver through an internal wire.

---

## Project Overview

The complete data path is:

```text
          8-bit Parallel Data
                 |
                 v
        +-----------------+
        |     uart_tx     |
        |   Transmitter   |
        +-----------------+
                 |
                 | tx
                 v
          serial_line
                 |
                 | rx
                 v
        +-----------------+
        |     uart_rx     |
        |    Receiver     |
        +-----------------+
                 |
                 v
          8-bit RX Data
```

The top-level module internally connects:

```verilog
uart_tx.tx  -->  serial_line  -->  uart_rx.rx
```

This loopback configuration allows the complete TX-to-RX path to be verified in simulation.

---

## Features

- 8-bit parallel input data
- Serial data transmission
- LSB-first data transfer
- One start bit
- One stop bit
- FSM-based UART transmitter
- FSM-based UART receiver
- Counter-based bit timing
- Shift-register-based serialization
- Bit-indexed receive data reconstruction
- Start-bit detection and validation
- Stop-bit validation
- Transmitter `busy` output
- Receiver `rx_done` completion pulse
- Hierarchical module instantiation
- Top-level TX/RX loopback integration
- Self-checking Verilog testbench
- Automatic PASS/FAIL reporting
- VCD waveform generation for GTKWave

---

## Repository Structure

```text
Verilog_UART_TX_RX/
|
├── uart_tx.v
├── uart_rx.v
├── uart_top.v
├── uart_top_tb.v
├── README.md
└── .gitignore
```

---

## RTL Architecture

### 1. UART Transmitter — `uart_tx.v`

The transmitter accepts an 8-bit parallel data word and sends it serially.

### Inputs

| Signal | Width | Description |
|---|---:|---|
| `clk` | 1 bit | System clock |
| `reset` | 1 bit | Synchronous reset |
| `tx_start` | 1 bit | Starts a new transmission |
| `tx_data` | 8 bits | Parallel data to transmit |

### Outputs

| Signal | Width | Description |
|---|---:|---|
| `tx` | 1 bit | Serial transmit output |
| `busy` | 1 bit | Indicates active transmission |

### Transmitter FSM

The transmitter uses four states:

```text
IDLE --> START --> SEND_BIT --> STOP --> IDLE
```

#### `IDLE`

- Serial output remains high
- `busy` remains low
- Waits for `tx_start`

#### `START`

- Captures `tx_data` into the internal shift register
- Drives the serial line low
- Holds the start bit for the configured counter interval
- Sets `busy` high

#### `SEND_BIT`

- Sends the current least-significant bit
- Holds each data bit for the configured counter interval
- Right-shifts the internal shift register
- Advances the bit counter
- Transmits all eight data bits LSB-first

#### `STOP`

- Drives the serial line high
- Holds the stop interval
- Returns to `IDLE` after completion

---

### 2. UART Receiver — `uart_rx.v`

The receiver detects the incoming start condition, reconstructs eight serial data bits, validates the stop bit, and produces the received byte.

### Inputs

| Signal | Width | Description |
|---|---:|---|
| `clk` | 1 bit | System clock |
| `reset` | 1 bit | Synchronous reset |
| `rx` | 1 bit | Serial receive input |

### Outputs

| Signal | Width | Description |
|---|---:|---|
| `rx_data` | 8 bits | Reconstructed received byte |
| `rx_done` | 1 bit | Pulses high after successful reception |

### Receiver FSM

The receiver uses four states:

```text
IDLE --> START --> RECEIVE --> STOP --> IDLE
```

#### `IDLE`

- Waits for the serial line to go low
- Detects a possible start bit

#### `START`

- Validates that the line remains low during the start interval
- Rejects the start condition if the line returns high too early
- Moves to data reception after successful validation

#### `RECEIVE`

- Uses the baud counter to determine data sampling intervals
- Samples the serial input
- Stores received bits using the bit counter
- Reconstructs the 8-bit byte

#### `STOP`

- Waits for the stop-bit timing interval
- Checks whether the serial input is high
- Transfers the reconstructed byte to `rx_data`
- Pulses `rx_done` for successful reception

---

### 3. Top-Level Integration — `uart_top.v`

The top-level module instantiates both the transmitter and receiver.

An internal wire connects the two modules:

```verilog
wire serial_line;
```

The transmitter drives this wire:

```verilog
.tx(serial_line)
```

The receiver reads from the same wire:

```verilog
.rx(serial_line)
```

Conceptually:

```text
+------------------+
|     uart_top     |
|                  |
|   +----------+   |
|   | uart_tx  |   |
|   +----------+   |
|        |         |
|        | tx      |
|        v         |
|  serial_line     |
|        |         |
|        | rx      |
|        v         |
|   +----------+   |
|   | uart_rx  |   |
|   +----------+   |
|                  |
+------------------+
```

This module demonstrates hierarchical RTL design and inter-module signal connectivity.

---

## UART Frame Format

The implemented frame structure is:

```text
Idle   Start   D0   D1   D2   D3   D4   D5   D6   D7   Stop
  1      0      x    x    x    x    x    x    x    x      1
```

Data is transmitted LSB-first:

```text
D0 --> D1 --> D2 --> D3 --> D4 --> D5 --> D6 --> D7
```

For example, transmitting:

```text
0xA5 = 1010_0101
```

results in the data-bit transmission order:

```text
1, 0, 1, 0, 0, 1, 0, 1
```

---

## Verification

The integrated design is verified using `uart_top_tb.v`.

The testbench performs end-to-end loopback testing:

```text
Testbench
    |
    | tx_data + tx_start
    v
 UART TX
    |
    | serial_line
    v
 UART RX
    |
    | rx_data + rx_done
    v
Automatic Comparison
```

The testbench:

- Generates the clock
- Applies reset
- Drives multiple test bytes
- Pulses `tx_start`
- Waits for `rx_done`
- Compares received data against expected data
- Prints PASS or FAIL automatically
- Generates a VCD waveform

---

## Self-Checking Test Cases

The following data patterns were tested:

| Test | Transmitted | Expected | Received | Result |
|---:|---:|---:|---:|---|
| 1 | `0xA5` | `0xA5` | `0xA5` | PASS |
| 2 | `0x00` | `0x00` | `0x00` | PASS |
| 3 | `0xFF` | `0xFF` | `0xFF` | PASS |
| 4 | `0xAB` | `0xAB` | `0xAB` | PASS |
| 5 | `0x3C` | `0x3C` | `0x3C` | PASS |

Example simulation output:

```text
PASS: Expected A5, Received a5
PASS: Expected 00, Received 00
PASS: Expected FF, Received ff
PASS: Expected AB, Received ab
PASS: Expected 3C, Received 3c

--------------------------------
SELF-CHECKING TESTBENCH FINISHED
--------------------------------
```

---

## Simulation Using Icarus Verilog

### Compile

```bash
iverilog -o uart_top_sim uart_tx.v uart_rx.v uart_top.v uart_top_tb.v
```

### Run

```bash
vvp uart_top_sim
```

The simulation automatically prints the self-checking PASS/FAIL results.

---

## Waveform Viewing Using GTKWave

The testbench generates:

```text
uart_top_test.vcd
```

Open it with:

```bash
gtkwave uart_top_test.vcd
```

Useful signals to inspect include:

```text
clk
reset
tx_start
tx_data
busy
serial_line
rx_data
rx_done
```

Internal FSM and counter signals can also be inspected during debugging.

---

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave

---

## Current Design Scope

This project is a simplified educational RTL implementation intended to demonstrate UART-style serial communication and Verilog design concepts.

The current implementation uses:

- Fixed 8-bit data width
- One start bit
- One stop bit
- No parity bit
- Shared TX/RX clock in loopback simulation
- Counter-based timing
- Fixed small counter values for simulation-oriented verification

The receiver performs start-condition validation and timed sampling, but it is **not** a conventional production UART receiver using 8x or 16x oversampling.

---

## Current Limitations

The current design does not include:

- Parameterized system clock frequency
- Parameterized baud rate
- 8x or 16x RX oversampling
- Asynchronous RX input synchronizer
- Metastability protection
- Configurable parity
- Configurable stop-bit count
- Dedicated framing-error output
- Configurable data width
- FIFO buffering
- Hardware flow control

Therefore, this design should not be considered a production-ready UART IP core.

---

## Possible Future Improvements

Future versions could include:

- Parameterized `CLK_FREQ`
- Parameterized `BAUD_RATE`
- Automatic baud-divider calculation
- Two-flop RX synchronizer
- 8x or 16x oversampling
- Majority-vote sampling
- Framing-error flag
- Parity generation and checking
- Configurable data width
- Configurable stop bits
- TX and RX FIFOs
- More extensive randomized verification
- SystemVerilog assertions
- SystemVerilog testbench environment

---

## Learning Outcomes

This project demonstrates practical experience with:

- RTL design using Verilog HDL
- Finite State Machines
- Sequential and combinational logic separation
- Shift registers
- Bit counters
- Timing counters
- Serial communication concepts
- Hierarchical module instantiation
- Inter-module signal connectivity
- Top-level RTL integration
- TX/RX loopback verification
- Self-checking testbenches
- Automatic expected-vs-actual comparison
- Waveform-based debugging

---

## Author

**Arpan**

Electrical Engineering Student  
Interested in Digital VLSI, RTL Design, and Hardware Verification
