
CC = riscv32-unknown-elf-gcc
AS = riscv32-unknown-elf-as
ASFLAGS = -march=rv32imc
CFLAGS = -march=rv32imc -ffreestanding

OBJS = start.o firmware.o


ra: ra.mem

ra.elf: sections.lds $(OBJS)
	riscv32-unknown-elf-ld -Bstatic -T sections.lds --strip-debug -nostdlib -o ra.elf -Map ra.map $(OBJS)

ra.mem: ra.bin bintov
	./bintov ra.bin ra.mem

bintov: bintov.c
	cc -o bintov bintov.c

ra.bin: ra.elf
	riscv32-unknown-elf-objcopy -O binary ra.elf ra.bin

clean:
	rm -f ra.elf ra.hex ra.bin ra.map *.o *~
