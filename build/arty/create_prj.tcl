set_param general.maxThreads 1

set project_dir    "prj"
set project_name   "arty_top"
set project_target "xc7a35ticsg324-1L"
set source_files { \
		../../core/addr_calc.sv \
		../../core/alu.sv \
		../../core/control.sv \
		../../core/core.sv \
		../../core/core.svh \
		../../core/data_memory.sv \
		../../core/decoder.sv \
		../../core/executer.sv \
		../../core/instruction_fetch.sv \
		../../core/instruction_memory.sv \
		../../core/registers.sv \
		../../core/simple_dualportram.sv \
		../../core/data_forwarding.sv \
		../../core/mul.sv \
		../../core/div.sv \
		../../core/shift.sv \
		../../src/mspe.sv \
		../../core/arty/clk_div.v \
		../../core/arty/uart_rx.v \
		../../core/arty/uart_tx.v \
	  }
set constraint_files {../../core/arty/arty.xdc}

set sim_files { }

create_project -force $project_name $project_dir -part $project_target
add_files -norecurse $source_files
add_files -fileset constrs_1 -norecurse $constraint_files
#add_files -fileset sim_1 -norecurse $sim_files

#import_ip -files fifo_generator_0.xci

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

