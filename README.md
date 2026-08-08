# APB Slave RAM with Modport Interface (SystemVerilog)

A SystemVerilog implementation of an AMBA APB slave RAM, built around a single
`apb_if` interface with dedicated `master` and `slave` modports, verified with
a class-based testbench driven through a virtual interface.

## Overview

The project models a minimal APB (Advanced Peripheral Bus) subsystem:

- A shared `apb_if` interface carries all protocol signals plus the common
  clock and reset.
- `master` and `slave` modports enforce correct signal direction on each side
  of the bus, so the DUT and testbench cannot accidentally drive the wrong
  signals.
- The DUT (`apb_slave_ram`) is a parameterized RAM that responds to APB
  read/write transactions.
- The testbench acts as the APB master. A `apb_driver` class holds a
  `virtual apb_if.master` handle and issues write/read transactions, then
  self-checks the data read back against what was written.

<img width="766" height="316" alt="image" src="https://github.com/user-attachments/assets/01d3f783-b9b9-4034-b808-b6219a48f965" />

## Repository structure

| File | Description |
|---|---|
| `apb_ram_design.sv` | `apb_if` interface (with master/slave modports) and the `apb_slave_ram` DUT |
| `tb_apb_ram.sv` | `apb_txn` transaction, `apb_driver` class (virtual interface), and the top-level testbench |
| `README.md` | This file |

## Interface signals

| Signal | Width | Direction (master → slave) | Purpose |
|---|---|---|---|
| `pclk` | 1 | shared | Clock |
| `presetn` | 1 | shared | Active-low reset |
| `paddr` | 8 | master → slave | Address |
| `pwrite` | 1 | master → slave | 1 = write, 0 = read |
| `psel` | 1 | master → slave | Slave select |
| `penable` | 1 | master → slave | Access phase qualifier |
| `pwdata` | 32 | master → slave | Write data |
| `prdata` | 32 | slave → master | Read data |
| `pready` | 1 | slave → master | Transfer complete |
| `pslverr` | 1 | slave → master | Slave error |

## DUT: `apb_slave_ram`

- Parameter `DEPTH` (default 256) sets the number of 32-bit words.
- On `psel && penable`, asserts `pready` and either writes `pwdata` to
  `mem[paddr]` or returns `mem[paddr]` on `prdata`.
- Synchronous, active-low asynchronous reset on `presetn`.

## Testbench

- `apb_txn` — a randomizable transaction (`addr`, `wdata`, `write`).
- `apb_driver` — wraps a `virtual apb_if.master` handle with `reset()`,
  `write()`, and `read()` tasks that follow the APB setup/access handshake
  and wait on `pready`.
- `tb_apb_ram` — instantiates the interface and DUT, creates the driver on
  `bus.master`, applies reset, then runs 10 write/read pairs with random
  data and checks each read value against what was written.

## Running the simulation

Tested with Cadence Xcelium on EDA Playground:

```
xrun -Q -unbuffered -timescale 1ns/1ns -sysv -access +rw apb_ram_design.sv tb_apb_ram.sv
```

Any SystemVerilog-2012 compliant simulator (Xcelium, Questa, VCS) will work.

### Expected output

```
PASS addr=0 data=...
PASS addr=1 data=...
...
ALL TESTS PASSED
```

## Waveform
<img width="631" height="234" alt="image" src="https://github.com/user-attachments/assets/b7f24201-882e-49ae-a9da-ee6c404d0113" />

