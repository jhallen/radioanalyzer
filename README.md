# radioanalyzer

Joe's Antique Radio Analyzer

This is a low cost combination tracking sweep generator and oscilloscope
designed primarily to perform alignment on antique radios.

It is based around a low cost Lattice Semiconductor ECP5 FPGA.  PicoRV32 (a
RISC-V implementation) is used as the soft processor.  An LCD screen and
touch panel user interface are included in the soft SoC made from this
processor.

The signal generator uses a DDS implemented in the FPGA.  An expensive DAC
is avoided by using a delta-sigma modulator enhanced with a digital to time
converter.

The expensive ADCs needed for the oscilloscope are avoided by using an LVDS
input comparator in combination with a time to digital converter.

# Build Instructions

## RISCV toolchain

The picorv32 project has a script to build it, so:

	git clone https://github.com/cliffordwolf/picorv32/tree/v1.0

Follow instructions in README.md file, starting with "make download-tools".

## Lattice Diamond

I followed these instructions for installing Diamond on Ubuntu:

https://ycnrg.org/lattice-diamond-on-ubuntu-16-04/

http://timallen.name/index.php/2019/01/14/installing-lattice-diamond-on-ubuntu-18-04/

I tried using LSE at first, but it was crashing with mysterious errors, so I
switched to Synplify.  But I found that the bash shell scripts used to
launch Synplify reference /bin/sh, which is dash on Ubuntu.  Simple solution
is to link /bin/sh to /bin/bash instead of /bin/dash.

## Development board

I'm using Lattice's $99 ECP5 evaluation board, which includes a one year
license for Lattice Diamond for the LFE5UM5G-85 FPGA.  This version of the
ECP5 (one which include high speed serdes) normally requires a subscription
license.  I intend to use the LFE5U FPGA in the final product, which does
not require a subscription license.

## Serial Cable

In Windows I am able to use the extra ports of the FTDI USB to serial
adapter chip for the embedded programmer as a console UART for the FPGA.  In
Linux, all ports of the FTDI chip become disabled, so this can't be done. 
Worse, the Diamond programmer crashes if you have any other FTDI cable
plugged into your computer.  The solution is to use a Prolific or SiLabs
based USB to serial adapter cable for the serial console.

# SoC Bus

I use a Verilog source code approach to SoC design.  This means that instead
of using some external tool to generate the SoC, I design the SoC bus to be
very convenient to use from Verilog source code.  The system is designed
right in Verilog, no external tools needed.

Consider an SoC component, such a CSR (Control and Status Register).  It
has:

* Input signals from the bus
* Output signals to the bus
* Bus address
* Size in bytes

The input signals are gathered into a Verilog bus called "bus_in" (the port
name is "bus_in").  Bus_in includes:

* Address bits
* Write data bits
* Write request pulse
* Byte enables
* Read request pulse
* Clock
* Synchronous reset

The output signals gathered into a Verilog bus called "bus_out" (the port
name is "bus_out").  But_out includes:

* Read acknowledge
* Write acknowledge
* Read data
* Interrupt request

The protocol is very simple.  A transaction is initiated with a single clock
read or write request pulse.  Coincident with this pulse is the address,
write data and byte enables.

A transaction is complete when a component returns a single cycle pulse on
read acknowledge or write acknowledge.  Read data is supplied coincident
with the read acknowledge pulse.  At all other times, components must drive
zeros on all bus_out signals.

All of the bus_outs are ORed together and fed back to the bus master.  This
return bus ends up implemented as an OR-tree, which is very efficiently
implemented within the FPGA (it's a simple tree of LUTs with no control
signals).

Better synthesis tools support the Verilog "wor" type.  Xilinx XST (from
ISE) and Altera Quartus both support "wor".  Xilinx Vivado and Synplify
(used by Lattice) unfortunately do not.  If "wor" is supported, all of the
bus_outs are just connected to the same signal:

	wire [BUS_IN_SIZE-1:0] bus_in;
	wor [BUS_OUT_SIZE-1:0] bus_out;

	bus_ram my_ram (.bus_in (bus_in), .bus_out (bus_out));

	bus_rom my_rom (.bus_in (bus_in), .bus_out (bus_out));

	bus_uart my_uart (.bus_in (bus_in), .bus_out (bus_out), ...);

This is very nice, since added a bus component is purely a local editing
operation.


If "wor" is not supported, then the bus_outs have to be explicitly ORed,
usually at the end of any module containing bus components:

	wire [BUS_IN_SIZE-1:0] bus_in;
	wire [BUS_OUT_SIZE-1:0] bus_out;

	wire [BUS_OUT_SIZE-1:0] bus_out_ram;
	bus_ram my_ram (.bus_in (bus_in), .bus_out (bus_out_ram));

	wire [BUS_OUT_SIZE-1:0] bus_out_rom;
	bus_rom my_rom (.bus_in (bus_in), .bus_out (bus_out_rom));

	wire [BUS_OUT_SIZE-1:0] bus_out_uart;
	bus_uart my_uart (.bus_in (bus_in), .bus_out (bus_out_uart), ...);

	assign bus_out = bus_out_ram | bus_out_rom | bus_out_uart | etc.;

Now when you add a componenent, you must edit two locations, bus still not
so bad in practice.

Read acknowledge and write acknowledge should be registered outputs: the
fastest components have a one flop delay.  The read and write pulses are
combinatorial outputs from the CPU (they use the lookahead signals from the
PicoRV32 core).  Back to back single cycle transactions are possible: the
CPU can provide a request pulse within the same cycle that it sees an
acknowledgment pulse.

The protocol is tolerant of extra pipeline delays on bus_in or bus_out.  If
the bus is very large, pipeline flip flops can be inserted anywhere on
bus_in or bus_out to help with timing closure.  Clock domain crossing
modules are also provided.

The bus address is specified by a Verilog parameter called "ADDR" and the
bus size of the component is specified with a Verilog parameter called
"SIZE".  It is up to each component to decode the address bus to determine
if it should respond to a particular transaction.  This may seem
inefficient, but remember that the synthesis tool is going to optimize the
logic- the address decoders will be combined to save space.  Furthermore,
bus segments can be created by special segmenting modules.  These modules
gate the read and write request pulses so that they only occur within a
specified address range and tie upper address bits to constants.  Although
downstream components decode the entire 32-bit address bus, the upper bits
are constant so the necessary logic is reduced.

All bus component instances are required to have the ADDR parameter.  This
means it is easy to find the address map by using "grep":

	grep ADDR *.v

Two include files help with declaring bus_in and bus_out.  Bus_params.v
holds parameters which define the size and field positions of bus_in and
bus_out.  Typically the old-style module syntax is used so that bus_params
can be included prior to the first port declaration:

	module bus_module
	  (
	  bus_in,
	  bus_out
	  );

	`include "bus_params.h"

	input [BUS_IN_SIZE-1:0] bus_in;
	output [BUS_OUT_SIZE-1:0] bus_out;

Bus_decl.v breaks out the fields of bus_in into individual signals. 
Bus_params must have been included first:

	`include "bus_decl.h"

Provides:

	wire bus_clk = bus_in[];
	wire bus_reset_l = bus_in[];
	wire bus_we = bus_in[];
	wire bus_re = bus_in[];
	wire [3:0] bus_be = bus_in[:];
	wire [31:0] bus_addr = bus_in[];
	wire [31:0] bus_wr_data = bus_in[];

