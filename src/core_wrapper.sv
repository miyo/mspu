`default_nettype none

module core_wrapper
  (
   input wire clk,
   input wire reset,
   input wire run,

   input wire [31:0] insn_addr,
   input wire [31:0] insn_din,
   input wire        insn_we,

   input wire [31:0] data_addr,
   input wire [31:0] data_din,
   input wire        data_we,
   input wire        data_oe,
   output wire [31:0] data_q,

   output wire [31:0] uart_dout,
   output wire        uart_we,

   output wire [31:0] emit_insn_mon,
   output wire [31:0] emit_pc_out_mon,
   output wire halt_mon,

   input wire snk_sop,
   input wire snk_eop,
   input wire snk_valid,
   input wire [511:0] snk_din,

   input wire src_req,
   output wire src_sop,
   output wire src_eop,
   output wire src_valid,
   output wire [511:0] src_q
   );


    logic [31:0] core_data_addr;
    logic [31:0] core_data_din;
    logic core_data_we;
    logic core_data_oe;
    logic [31:0] core_data_q;

    logic [31:0] snk_data_addr;
    logic [31:0] snk_data_din;
    logic snk_data_we;

    logic [31:0] src_data_addr;
    logic src_data_oe;
    logic [31:0] src_data_q;

    assign core_data_addr = snk_data_we ? snk_data_addr :
			    src_data_oe ? src_data_addr :
			    data_addr;
    assign core_data_din  = snk_data_we ? snk_data_din : data_din;
    assign core_data_we   = data_we | snk_data_we;
    assign core_data_oe   = data_oe | src_data_oe;
    assign data_q         = core_data_q;
    assign src_data_q     = core_data_q;

    core core_i(
		.clk(clk),
		.reset(reset),
		.run(run),
		
		.insn_addr(insn_addr),
		.insn_din(insn_din),
		.insn_we(insn_we),
		
		.data_addr(core_data_addr),
		.data_din(core_data_din),
		.data_we(core_data_we),
		.data_oe(core_data_oe),
		.data_q(core_data_q),

		.uart_dout(uart_dout),
		.uart_we(uart_we),

		.emit_insn_mon(emit_insn_mon),
		.emit_pc_out_mon(emit_pc_out_mon),
		.halt_mon(halt_mon));

    datawidthconv_512_to_32 datawidthconv_512_to_32_i (.clk(clk),
						       .reset(reset),
						       .snk_sop(snk_sop),
						       .snk_eop(snk_eop),
						       .snk_valid(snk_valid),
						       .snk_din(snk_din),
						       .data_addr(snk_data_addr),
						       .data_din(snk_data_din),
						       .data_we(snk_data_we));
    
    datawidthconv_32_to_512 datawidthconv_32_to_512_i (.clk(clk),
						       .reset(reset),
						       .src_req(src_req),
						       .data_addr(src_data_addr),
						       .data_oe(src_data_oe),
						       .data_q(src_data_q),
						       .src_sop(src_sop),
						       .src_eop(src_eop),
						       .src_valid(src_valid),
						       .src_q(src_q));
    
endmodule // core_wrapper

`default_nettype wire

