
# GCC bin directory
TOOL = /opt/riscv32imc/bin

CC = ${TOOL}/riscv32-unknown-elf-gcc
AS = ${TOOL}/riscv32-unknown-elf-gcc
ASFLAGS = -march=rv32imc -c
CFLAGS = -march=rv32imc -ffreestanding

OBJS = start.o firmware.o

# Use Diamond "deployment tool" to combine FPGA configuration file with firmware
# Note that byte mirroring must be enabled for the firmware.
ra_impl1.mcs: ../fpga/impl1/ra_impl1.bit ra.bin
	/opt/lattice/diamond/3.11_x64/bin/lin64/ddtcmd -oft -advanced -dev LFE5UM5G-85F \
		-if ../fpga/impl1/ra_impl1.bit -format int -flashsize 128 \
		-usermirror -userdata 1 -userfile ra.bin -address 0x00F00000 \
		-of ra_impl1.mcs
	cp ra_impl1.mcs ../fpga/impl1/ra_impl1.mcs

ra: ra.mem ra.hex

ra.elf: sections.lds $(OBJS)
	${TOOL}/riscv32-unknown-elf-ld -Bstatic -T sections.lds --strip-debug -nostdlib -o ra.elf -Map ra.map $(OBJS)

# Word hex file for bus_rom.v
ra.mem: ra.bin bintov
	./bintov ra.bin ra.mem

# Byte hex file for simulation
ra.hex: ra.bin bintob
	./bintob ra.bin ra.hex

bintov: bintov.c
	cc -o bintov bintov.c

bintob: bintob.c
	cc -o bintob bintob.c

ra.bin: ra.elf
	${TOOL}/riscv32-unknown-elf-objcopy -O binary ra.elf ra.bin

clean:
	rm -f ra.elf ra.hex ra.bin ra.map *.o *~
