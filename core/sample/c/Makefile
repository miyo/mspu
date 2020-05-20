PREFIX=riscv64-unknown-elf
CC=$(PREFIX)-gcc
LD=$(PREFIX)-ld
OBJCOPY=$(PREFIX)-objcopy

all:
	$(CC) -march=rv32i -mabi=ilp32 -o startup.o -c startup.s
	$(CC) -march=rv32i -mabi=ilp32 -mcmodel=medany -o hello-c.o -c hello.c
	$(LD) -static -nostatfiles -T hello.ld -o hello-c hello-c.o startup.o
	$(OBJCOPY) -O binary --only-section=.text hello-c hello-c.insn
	$(OBJCOPY) -O binary --only-section=.data hello-c hello-c.data


test:
	qemu-system-riscv32 -M virt -kernel hello -nographic

