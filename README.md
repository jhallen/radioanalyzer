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
