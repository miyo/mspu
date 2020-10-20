TOP := core
SOURCES := $(wildcard *.sv) $(wildcard *.svh)
TESTBENCH := tb_core.cpp testbench.h

.PHONY: all sim clean test

all: $(SOURCES) $(TESTBENCH)
	verilator -Wall --cc $(TOP).sv --trace --exe tb_$(TOP).cpp
	make -C obj_dir -f V$(TOP).mk 

div: div.sv tb_div.cpp
	verilator -Wall --cc div.sv --trace --exe tb_div.cpp
	make -C obj_dir -f Vdiv.mk 

shift: shift.sv tb_shift.cpp
	verilator -Wall --cc shift.sv --trace --exe tb_shift.cpp
	make -C obj_dir -f Vshift.mk 

sim:
	./obj_dir/V$(TOP)
	./obj_dir/V$(TOP) sample/hello.insn sample/hello.data
	./obj_dir/V$(TOP) sample/fact.insn sample/fact.data
	./obj_dir/V$(TOP) sample/printnum.insn sample/printnum.data
	./obj_dir/V$(TOP) sample/simple.insn sample/simple.data
	./obj_dir/V$(TOP) sample/add.insn sample/add.data
	./obj_dir/V$(TOP) sample/c/hello-c.insn sample/c/hello-c.data
	./obj_dir/V$(TOP) sample/c/fib-c.insn sample/c/fib-c.data

clean:
	-rm -rf obj_dir
	-rm -f *.vcd
