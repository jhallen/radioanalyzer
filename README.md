# Radio Analyzer Project

Joe's Antique Radio Analyzer

This is a low cost instrument containing both a sweep generator and an
oscilloscope.  It is designed primarily to perform alignment on antique
radios, and is intended to replace classic marker sweep generators.

The signal generator must be capable of generating an FM stereo signal up
to 108 MHz, suitable for commercial broadcast receivers (up to 148 MHz for 2
meter ham radio would be preferred).  It must generate modulated AM up to
1.8 MHz (up to 30 MHz and with SSB support would be preferred for ham radio
use).

The output should be controlled with an attenuator.

The oscilloscope should have at least 10 MHz bandwidth- suitable for viewing
the frequency response of a circuit driven by the sweep generator and
measuring with an RF detector probe, but also suitable for TV repair work. 
It should have a good oscilloscope front-end: 1M impedance, attenuator /
variable-gain amplifier and self-calibration.

# Design

The analyzer is based around a low cost Lattice Semiconductor ECP5 FPGA. 
[PicoRV32](https://github.com/cliffordwolf/picorv32) (a RISC-V
implementation tailored for FPGAs) is used as the soft processor.  An LCD
screen and touch panel user interface are included in the soft SoC made from
this processor.

Normally I would not recommend using a soft core processor because FPGA
gates are expensive.  However in this particular case, where I already need
an FPGA, and where conventional microcontrollers with video support
cost more than one step size change of the ECP5 FPGA, it's worth it.

The PicoRV32 has a lot of value even though it's a relatively simple CPU. 
The value is that it (and RISC-V) is license free, not encumbered by patents
and all of the work to port GCC and LLVM/Clang has already been done.  These
toolchains represent thousands of man-years of effort.

See [https://riscv.org/faq/](https://riscv.org/faq/)

The signal generator uses a DDS implemented in the FPGA.  An expensive DAC
is avoided by using a delta-sigma modulator enhanced with a digital to time
converter (DTC).

See this paper: [https://pdfs.semanticscholar.org/a947/d7774c73c58028026ef628da1f0323acfce6.pdf](https://pdfs.semanticscholar.org/a947/d7774c73c58028026ef628da1f0323acfce6.pdf)

The expensive ADCs needed for the oscilloscope are avoided by using an LVDS
input comparator in combination with a time to digital converter (TDC).

See this paper: [https://cas.tudelft.nl/pubs/Homulle15fpga.pdf](https://cas.tudelft.nl/pubs/Homulle15fpga.pdf).

The oscilloscope front end will use discrete components to avoid expensive
ICs.  This is the approach taken by low cost oscilloscope manufacturers. 
See:

[EEVblog #675 - How To Reverse Engineer A Rigol DS1054Z](https://www.youtube.com/watch?v=lJVrTV_BeGg)

# Firmware development

I'm starting with Lattice's $99 ECP5 evaluation board, which includes a one
year license for Lattice Diamond for the LFE5UM5G-85 FPGA.  This version of
the ECP5 (one which includes high speed serdes) normally requires a
subscription license.  I intend to use the LFE5U FPGA in the final product,
which does not require a subscription license.

![ECP5 Evaluation Card](doc/ecp5-eval-card.png)

There is an open source FPGA tool chain that works with ECP5 available
called Project Trellis, see
[https://github.com/SymbiFlow/prjtrellis](https://github.com/SymbiFlow/prjtrellis)

Even so, it's relatively new so I will have a Diamond build path.

# Build Instructions

See [Build Instructions](doc/build.md)

# SoC Bus

I use a Verilog source code centered approach to System On Chip (SoC) design
(I have been designing FPGAs this way for years, and there is usally a
bridge to an external master CPU or to on an on-chip ARM processor).  This
means that instead of using some external tool to generate the SoC, I design
the SoC bus to be very convenient to use from Verilog source code.  The
system is designed right in Verilog, no external tools needed.

Consider a SoC component, such a CSR (Control and Status Register).  It
has:

* Input signals from the bus
* Output signals to the bus
* Bus address

The input signals are gathered into a Verilog bus called "bus_in" (the port
name is "bus_in").  Bus_in includes:

* Address bits
* Write data bits
* Write request pulse
* Byte enables
* Read request pulse
* Clock
* Synchronous reset

The output signals are gathered into a Verilog bus called "bus_out" (the port
name is "bus_out").  But_out includes:

* Read acknowledge
* Write acknowledge
* Read data
* Interrupt request

The protocol is very simple.  A transaction is initiated with a single clock
read or write request pulse.  Coincident with this pulse is the address,
write data and byte enables.  These signals are only valid during the pulse.

A transaction is complete when a component returns a single cycle pulse on
read acknowledge or write acknowledge.  Read data is supplied coincident
with the read acknowledge pulse.  At all other times, components must drive
zeros on all bus_out signals.

All of the bus_outs are ORed together and fed back to the bus master.  This
return bus ends up implemented as an OR-tree, which is a very efficient
structure within the FPGA (it's a simple tree of LUTs with no control
signals).  Small components may not drive all of the bus_out signals- they
must drive 0 on any unused signals and the synthesis tool will optimize them
out.

Better synthesis tools support the Verilog "wor" type.  Xilinx XST (part of
ISE) and Altera Quartus both support "wor".  Xilinx Vivado and Synplify
(used by Lattice) unfortunately do not.  If "wor" is supported, all of the
bus_outs can just be connected to the same signal:

```verilog
wire [BUS_IN_SIZE-1:0] bus_in;

wor [BUS_OUT_SIZE-1:0] bus_out;
assign bus_out = 0; // In case no other driver of bus_out...

bus_ram #(.BUS_ADDR(32'h0000_0000), .SIZE(65536)) my_ram
  (
  .bus_in (bus_in),
  .bus_out (bus_out)
  );

bus_rom #(.BUS_ADDR(32'h0001_0000), .SIZE(65536)) my_rom
  (
  .bus_in (bus_in),
  .bus_out (bus_out)
  );

bus_reg #(.BUS_ADDR(32'h0200_0000)) my_gpio
  (
  .bus_in (bus_in),
  .bus_out (bus_out),
  .out (leds)
  );

bus_uart #(.BUS_ADDR(32'h0200_0004)) my_uart
  (
  .bus_in (bus_in),
  .bus_out (bus_out),
  .ser_tx (ser_tx),
  .ser_rx (ser_rx)
  );
````

This is very tidy, since adding a bus component is purely a local editing
operation, meaning that only one part of the source file has to be edited.

If "wor" is not supported, then the bus_outs have to be explicitly ORed,
usually at the end of any module containing bus components:

```verilog
wire [BUS_IN_SIZE-1:0] bus_in;
wire [BUS_OUT_SIZE-1:0] bus_out;

wire [BUS_OUT_SIZE-1:0] bus_out_ram;

bus_ram #(.BUS_ADDR(32'h0000_0000), .SIZE(65536)) my_ram
  (
  .bus_in (bus_in),
  .bus_out (bus_out_ram)
  );

wire [BUS_OUT_SIZE-1:0] bus_out_rom;

bus_rom #(.BUS_ADDR(32'h0001_0000), .SIZE(65536)) my_rom
  (
  .bus_in (bus_in),
  .bus_out (bus_out_rom)
  );

wire [BUS_OUT_SIZE-1:0] bus_out_gpio;

bus_reg #(.BUS_ADDR(32'h0200_0000)) my_gpio
  (
  .bus_in (bus_in),
  .bus_out (bus_out_gpio),

  .out (leds)
  );

wire [BUS_OUT_SIZE-1:0] bus_out_uart;

bus_uart #(.BUS_ADDR(32'h0200_0004)) my_uart
  (
  .bus_in (bus_in),
  .bus_out (bus_out_uart),
  .ser_tx (ser_tx),
  .ser_rx (ser_rx)
  );

// bus_out OR-tree

assign bus_out = bus_out_ram | bus_out_rom | bus_out_uart | bus_out_gpio;
````

Now when you add a componenent, you must edit two locations of the source
file, but this is still not so bad in practice.

Read acknowledge and write acknowledge should be registered outputs: the
fastest components have a one flop delay.  The read and write request pulses
are combinatorial outputs from the CPU (they use the lookahead signals from
the PicoRV32 core).  Back to back single cycle transactions are possible:
the CPU can provide a request pulse within the same cycle that it sees an
acknowledgment pulse.

The protocol is tolerant of extra pipeline delays on bus_in or bus_out.  If
the bus is very large, pipeline flip flops can be inserted anywhere on
bus_in or bus_out to help with timing closure.

On the other hand, only a single transaction can be outstanding on the bus. 
The CPU does not issue a new transaction until the previous one has
been completed.

A timeout mechanism can optionally be implemented to end transactions that
never return an acknowledgment pulse.

The bus can be segmented into different clock domains.  One way is with
asynchronous clock domain crossing FIFOs on bus_in and on bus_out.  The "not
empty" signal from each FIFO should be wired to its "read enable" signal and
should gate the downstream request and upstream acknowledge signals.

The address of each component is specified by a Verilog parameter called
"BUS_ADDR" and the bus size of the component in bytes is specified with a
Verilog parameter called "SIZE".  It is up to each component to decode the
address bus to determine if it should respond to a particular transaction. 
This may seem inefficient, but remember that the synthesis tool is going to
optimize the logic- the address decoders will be combined to save space. 
Furthermore, bus segments can be created by special segmenting modules. 
These modules gate the read and write request pulses so that they only occur
within a specified address range and tie upper address bits to constants. 
Although downstream components decode the entire 32-bit address bus, the
upper bits are constant so the necessary logic is reduced.

All bus component instances are required to have the BUS_ADDR parameter.  This
means it is easy to find the address map by using the UNIX regular
expression search tool "grep":

	grep '\.BUS_ADDR' *.v

Two include files help with declaring bus_in and bus_out.  Bus_params.v
holds parameters which define the size and field positions of bus_in and
bus_out.  Typically the old-style module syntax is used so that bus_params
can be included prior to the first port declaration:

```verilog
module bus_module
  (
  bus_in,
  bus_out
  );

`include "bus_params.h"

input [BUS_IN_WIDTH-1:0] bus_in;
output [BUS_OUT_WIDTH-1:0] bus_out;
````

Bus_decl.v breaks out the fields of bus_in and bus_out into individual
wires.  Bus_params must have been included first:

```verilog
`include "bus_decl.h"
````

This file has:

```verilog
// Declare the internal bus structure
// Break out the structure into wires

wire [BUS_IN_WIDTH-1:0] bus_in;

// No support for wor in Vivado!
//wor [BUS_OUT_WIDTH-1:0] bus_out; // wor used here so that we can have multiple drivers
//assign bus_out = 0; // In case nobody is driving.

wire [BUS_OUT_WIDTH-1:0] bus_out;

// Bus input fields

wire bus_reset_l = bus_in[BUS_FIELD_RESET_L]; // Reset
wire bus_clk = bus_in[BUS_FIELD_CLK]; // Clock

wire [BUS_DATA_WIDTH-1:0] bus_wr_data = bus_in[BUS_WR_DATA_END-1:BUS_WR_DATA_START]; // Write data
wire [BUS_ADDR_WIDTH-1:0] bus_addr = bus_in[BUS_ADDR_END-1:BUS_ADDR_START]; // Address
wire bus_rd_req = bus_in[BUS_FIELD_RE]; // Read request
wire bus_wr_req = bus_in[BUS_FIELD_WE]; // Write request
wire [3:0] bus_be = bus_in[BUS_FIELD_BE+3:BUS_FIELD_BE]; // Byte enables

// Bus output fields

wire bus_irq = bus_out[BUS_FIELD_IRQ]; // Interrupt request
wire bus_wr_ack = bus_out[BUS_FIELD_WR_ACK]; // Write acknowledge
wire bus_rd_ack = bus_out[BUS_FIELD_RD_ACK]; // Read acknowledge
wire [BUS_DATA_WIDTH-1:0] bus_rd_data = bus_out[BUS_RD_DATA_END-1:BUS_RD_DATA_START]; // Read data
````

# SPI Flash

A single SPI NOR flash device is used for both FPGA configuration and RISC-V
firmware.  This was somewhat challenging on the ECP5, here are some hints:

You must use a Lattice black box for user logic to access the SPI sclk: see
USRMCLK in the ECP5 sysConfig Usage Guide

In Tools -> Spreadsheet view -> Global Preferences -> sysConfig, you must
disable the SLAVE_SPI_PORT and MASTER_SPI_PORT.  This is documented in the
ECP5 sysConfig Usage Guide.  A consequence of leaving these disabled is that
you can not program the SPI Flash using the Programmer without first loading
a design into the FPGA which has the MASTER_SPI_PORT enabled.  This enables
"SPI Flash Background Programming" to work from the Programmer. 

The bank 8 I/O pins must all be set for LVCMOS25 (the default), even if
bank 8 is using 3.3V.  If you use LVCMOS33, strange things happen: MISO and
MOSI are forced to open drain.

You can use the Lattice "Deployment Tool" to generate an image for the
SPI-flash that combines the .bit file and the firmware.  However, you must
enable bit mirroring for the firmware (and not for the .bit file).
