set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports uart_txo]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports uart_rxi]

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports sw0]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports sw1]

set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports reset]




connect_debug_port u_ila_0/clk [get_nets [list clk_IBUF_BUFG]]
connect_debug_port dbg_hub/clk [get_nets clk_IBUF_BUFG]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_wiz_0_i/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {insn_din[0]} {insn_din[1]} {insn_din[2]} {insn_din[3]} {insn_din[4]} {insn_din[5]} {insn_din[6]} {insn_din[7]} {insn_din[8]} {insn_din[9]} {insn_din[10]} {insn_din[11]} {insn_din[12]} {insn_din[13]} {insn_din[14]} {insn_din[15]} {insn_din[16]} {insn_din[17]} {insn_din[18]} {insn_din[19]} {insn_din[20]} {insn_din[21]} {insn_din[22]} {insn_din[23]} {insn_din[24]} {insn_din[25]} {insn_din[26]} {insn_din[27]} {insn_din[28]} {insn_din[29]} {insn_din[30]} {insn_din[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {data_addr[0]} {data_addr[1]} {data_addr[2]} {data_addr[3]} {data_addr[4]} {data_addr[5]} {data_addr[6]} {data_addr[7]} {data_addr[8]} {data_addr[9]} {data_addr[10]} {data_addr[11]} {data_addr[12]} {data_addr[13]} {data_addr[14]} {data_addr[15]} {data_addr[16]} {data_addr[17]} {data_addr[18]} {data_addr[19]} {data_addr[20]} {data_addr[21]} {data_addr[22]} {data_addr[23]} {data_addr[24]} {data_addr[25]} {data_addr[26]} {data_addr[27]} {data_addr[28]} {data_addr[29]} {data_addr[30]} {data_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {data_din[0]} {data_din[1]} {data_din[2]} {data_din[3]} {data_din[4]} {data_din[5]} {data_din[6]} {data_din[7]} {data_din[8]} {data_din[9]} {data_din[10]} {data_din[11]} {data_din[12]} {data_din[13]} {data_din[14]} {data_din[15]} {data_din[16]} {data_din[17]} {data_din[18]} {data_din[19]} {data_din[20]} {data_din[21]} {data_din[22]} {data_din[23]} {data_din[24]} {data_din[25]} {data_din[26]} {data_din[27]} {data_din[28]} {data_din[29]} {data_din[30]} {data_din[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {insn_addr[0]} {insn_addr[1]} {insn_addr[2]} {insn_addr[3]} {insn_addr[4]} {insn_addr[5]} {insn_addr[6]} {insn_addr[7]} {insn_addr[8]} {insn_addr[9]} {insn_addr[10]} {insn_addr[11]} {insn_addr[12]} {insn_addr[13]} {insn_addr[14]} {insn_addr[15]} {insn_addr[16]} {insn_addr[17]} {insn_addr[18]} {insn_addr[19]} {insn_addr[20]} {insn_addr[21]} {insn_addr[22]} {insn_addr[23]} {insn_addr[24]} {insn_addr[25]} {insn_addr[26]} {insn_addr[27]} {insn_addr[28]} {insn_addr[29]} {insn_addr[30]} {insn_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 32 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {uart_dout[0]} {uart_dout[1]} {uart_dout[2]} {uart_dout[3]} {uart_dout[4]} {uart_dout[5]} {uart_dout[6]} {uart_dout[7]} {uart_dout[8]} {uart_dout[9]} {uart_dout[10]} {uart_dout[11]} {uart_dout[12]} {uart_dout[13]} {uart_dout[14]} {uart_dout[15]} {uart_dout[16]} {uart_dout[17]} {uart_dout[18]} {uart_dout[19]} {uart_dout[20]} {uart_dout[21]} {uart_dout[22]} {uart_dout[23]} {uart_dout[24]} {uart_dout[25]} {uart_dout[26]} {uart_dout[27]} {uart_dout[28]} {uart_dout[29]} {uart_dout[30]} {uart_dout[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 8 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {uart_rx_dout[0]} {uart_rx_dout[1]} {uart_rx_dout[2]} {uart_rx_dout[3]} {uart_rx_dout[4]} {uart_rx_dout[5]} {uart_rx_dout[6]} {uart_rx_dout[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 5 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {core_i/decoder_i/emit_rs1[0]} {core_i/decoder_i/emit_rs1[1]} {core_i/decoder_i/emit_rs1[2]} {core_i/decoder_i/emit_rs1[3]} {core_i/decoder_i/emit_rs1[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 32 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {core_i/decoder_i/emit_insn[0]} {core_i/decoder_i/emit_insn[1]} {core_i/decoder_i/emit_insn[2]} {core_i/decoder_i/emit_insn[3]} {core_i/decoder_i/emit_insn[4]} {core_i/decoder_i/emit_insn[5]} {core_i/decoder_i/emit_insn[6]} {core_i/decoder_i/emit_insn[7]} {core_i/decoder_i/emit_insn[8]} {core_i/decoder_i/emit_insn[9]} {core_i/decoder_i/emit_insn[10]} {core_i/decoder_i/emit_insn[11]} {core_i/decoder_i/emit_insn[12]} {core_i/decoder_i/emit_insn[13]} {core_i/decoder_i/emit_insn[14]} {core_i/decoder_i/emit_insn[15]} {core_i/decoder_i/emit_insn[16]} {core_i/decoder_i/emit_insn[17]} {core_i/decoder_i/emit_insn[18]} {core_i/decoder_i/emit_insn[19]} {core_i/decoder_i/emit_insn[20]} {core_i/decoder_i/emit_insn[21]} {core_i/decoder_i/emit_insn[22]} {core_i/decoder_i/emit_insn[23]} {core_i/decoder_i/emit_insn[24]} {core_i/decoder_i/emit_insn[25]} {core_i/decoder_i/emit_insn[26]} {core_i/decoder_i/emit_insn[27]} {core_i/decoder_i/emit_insn[28]} {core_i/decoder_i/emit_insn[29]} {core_i/decoder_i/emit_insn[30]} {core_i/decoder_i/emit_insn[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 5 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {core_i/decoder_i/emit_rs2[0]} {core_i/decoder_i/emit_rs2[1]} {core_i/decoder_i/emit_rs2[2]} {core_i/decoder_i/emit_rs2[3]} {core_i/decoder_i/emit_rs2[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {core_i/decoder_i/emit_pc_out[0]} {core_i/decoder_i/emit_pc_out[1]} {core_i/decoder_i/emit_pc_out[2]} {core_i/decoder_i/emit_pc_out[3]} {core_i/decoder_i/emit_pc_out[4]} {core_i/decoder_i/emit_pc_out[5]} {core_i/decoder_i/emit_pc_out[6]} {core_i/decoder_i/emit_pc_out[7]} {core_i/decoder_i/emit_pc_out[8]} {core_i/decoder_i/emit_pc_out[9]} {core_i/decoder_i/emit_pc_out[10]} {core_i/decoder_i/emit_pc_out[11]} {core_i/decoder_i/emit_pc_out[12]} {core_i/decoder_i/emit_pc_out[13]} {core_i/decoder_i/emit_pc_out[14]} {core_i/decoder_i/emit_pc_out[15]} {core_i/decoder_i/emit_pc_out[16]} {core_i/decoder_i/emit_pc_out[17]} {core_i/decoder_i/emit_pc_out[18]} {core_i/decoder_i/emit_pc_out[19]} {core_i/decoder_i/emit_pc_out[20]} {core_i/decoder_i/emit_pc_out[21]} {core_i/decoder_i/emit_pc_out[22]} {core_i/decoder_i/emit_pc_out[23]} {core_i/decoder_i/emit_pc_out[24]} {core_i/decoder_i/emit_pc_out[25]} {core_i/decoder_i/emit_pc_out[26]} {core_i/decoder_i/emit_pc_out[27]} {core_i/decoder_i/emit_pc_out[28]} {core_i/decoder_i/emit_pc_out[29]} {core_i/decoder_i/emit_pc_out[30]} {core_i/decoder_i/emit_pc_out[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list data_we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list insn_we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list run]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list run_d]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list uart_rx_rd]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list uart_rx_rd_d]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list uart_we]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk]
