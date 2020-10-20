CC := riscv64-unknown-elf-gcc
OBJCOPY := riscv64-unknown-elf-objcopy
ARCH := -march=rv32i
FLAGS := -mabi=ilp32 -nostartfiles

all:
	$(CC) $(ARCH) $(FLAGS) -Tlinker.ld hello.s -o hello
	$(OBJCOPY) -O binary --only-section=.text hello hello.insn
	$(OBJCOPY) -O binary --only-section=.data hello hello.data
	
	$(CC) -march=rv32im $(FLAGS) -Tfact.ld simple.s -o simple
	$(OBJCOPY) -O binary --only-section=.text simple simple.insn
	$(OBJCOPY) -O binary --only-section=.data simple simple.data
	
	$(CC) -march=rv32im $(FLAGS) -Tfact.ld printnum.s -o printnum
	$(OBJCOPY) -O binary --only-section=.text printnum printnum.insn
	$(OBJCOPY) -O binary --only-section=.data printnum printnum.data
	
	$(CC) -march=rv32im $(FLAGS) -Tfact.ld fact.s -o fact
	$(OBJCOPY) -O binary --only-section=.text fact fact.insn
	$(OBJCOPY) -O binary --only-section=.data fact fact.data
	
	$(CC) -march=rv32im $(FLAGS) -Tfact.ld fifo.s -o fifo
	$(OBJCOPY) -O binary --only-section=.text fifo fifo.insn
	$(OBJCOPY) -O binary --only-section=.data fifo fifo.data
	
	$(CC) -march=rv32im $(FLAGS) -Tadd.ld add.s -o add
	$(OBJCOPY) -O binary --only-section=.text add add.insn
	$(OBJCOPY) -O binary --only-section=.data add add.data

clean:
	-rm -f hello
	-rm -f hello.insn
	-rm -f hello.data
	-rm -f simple
	-rm -f simple.insn
	-rm -f simple.data
