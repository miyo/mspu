TOP := core
SOURCES := $(wildcard *.sv) $(wildcard *.svh)
TESTBENCH := tb_core.cpp testbench.h

.PHONY: all sim clean

all: $(SOURCES) $(TESTBENCH)
	verilator -Wall --cc $(TOP).sv --trace --exe tb_$(TOP).cpp
	make -C obj_dir -f V$(TOP).mk 

div: div.sv tb_div.cpp
	verilator -Wall --cc div.sv --trace --exe tb_div.cpp
	make -C obj_dir -f Vdiv.mk 

sim:
	./obj_dir/V$(TOP)

clean:
	-rm -rf obj_dir
	-rm -f *.vcd
