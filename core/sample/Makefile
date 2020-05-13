CC := riscv64-unknown-elf-gcc
OBJCOPY := riscv64-unknown-elf-objcopy
FLAGS := -march=rv32i -mabi=ilp32 -nostartfiles

all:
	$(CC) $(FLAGS) -Tlinker.ld hello.s -o hello
	$(OBJCOPY) -O binary --only-section=.text hello hello.insn
	$(OBJCOPY) -O binary --only-section=.data hello hello.data
	
	$(CC) $(FLAGS) -Tlinker.ld simple.s -o simple
	$(OBJCOPY) -O binary --only-section=.text simple simple.insn
	$(OBJCOPY) -O binary --only-section=.data simple simple.data

clean:
	-rm -f hello
	-rm -f hello.insn
	-rm -f hello.data
	-rm -f simple
	-rm -f simple.insn
	-rm -f simple.data
