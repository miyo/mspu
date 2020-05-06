TOP := core
SOURCES := $(wildcard *.sv) $(wildcard *.svh)
TESTBENCH := tb_core.cpp testbench.h

.PHONY: all sim clean

all: $(SOURCES) $(TESTBENCH)
	verilator --cc $(TOP).sv --trace --exe tb_core.cpp
	make -C obj_dir -f V$(TOP).mk 

sim:
	./obj_dir/V$(TOP)

clean:
	-rm -rf obj_dir
	-rm -f *.vcd
