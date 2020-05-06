#!/bin/sh

rm -rf obj_dir
verilator --cc core.sv --trace --exe tb_core.cpp
make -C obj_dir -f Vcore.mk 
./obj_dir/Vcore
