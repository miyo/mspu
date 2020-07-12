set_param general.maxThreads 1

set project_dir    "prj"
set project_name   "arty_top"
set project_target "xc7a35ticsg324-1L"
set source_files { \
		../addr_calc.sv \
		../alu.sv \
		../control.sv \
		../core.sv \
		../core.svh \
		../data_memory.sv \
		../decoder.sv \
		../executer.sv \
		../instruction_fetch.sv \
		../instruction_memory.sv \
		../registers.sv \
		../simple_dualportram.sv \
		../data_forwarding.sv \
		../mul.sv \
		../div.sv \
		../shift.sv \
		../../peripheral/clk_div.v \
		../../peripheral/uart_rx.v \
		../../peripheral/uart_tx.v \
		arty_top.sv \
	  }
set constraint_files {./arty.xdc}

set sim_files { \
		./dummy_top_tb.sv \
		./dummy_top.sv
		}

create_project -force $project_name $project_dir -part $project_target
add_files -norecurse $source_files
add_files -fileset constrs_1 -norecurse $constraint_files
add_files -fileset sim_1 -norecurse $sim_files

import_ip -files fifo_generator_0.xci
import_ip -files clk_wiz_0.xci

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

reset_project

launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -jobs 4
wait_on_run impl_1

open_run impl_1
report_utilization -file [file join $project_dir "project.rpt"]
report_timing -file [file join $project_dir "project.rpt"] -append

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

close_project

quit

