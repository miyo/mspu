`default_nettype none

module core
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
   output wire        alu_unknown_op,
   output wire halt_mon
   );

    wire [31:0] emit_insn;
    wire [31:0] emit_pc_out;

    assign emit_insn_mon = emit_insn;
    assign emit_pc_out_mon = emit_pc_out;

    wire run_if, run_id, run_ex;
    
    wire [31:0] insn;
    wire [4:0]  rd;
    wire [4:0] reg_rd;
    wire [31:0] reg_wdata;
    wire [31:0] alu_a, alu_b;
    wire [31:0] alu_a_id, alu_b_id;
    wire [31:0] alu_result;
    wire [31:0] imm_value;

    wire [3:0] alu_op;
    wire [3:0] mul_op;
    wire [3:0] div_op;
    wire [1:0] shift_op;
    wire reg_we, reg_we_out;
    wire dmem_we, dmem_re;
    wire [4:0] dmem_wdata_src;
    wire [31:0] dmem_wdata;
    wire mem_to_reg;
    wire branch_en, jal_en, jalr_en;
    wire [1:0] alu_bytes;
    wire unsigned_flag, unsigned_flag_ex;

    wire [31:0] pc, pc_id;
    wire [31:0] pc_in;
    wire pc_in_en;

    wire mem_to_reg_ex;
    wire [1:0] alu_bytes_ex;
    wire [4:0] dmem_wdata_src_ex;
    wire [31:0] dmem_wdata_ex;
    wire dmem_we_ex;
    wire dmem_re_ex;
    wire [4:0] rd_ex;
    wire reg_we_ex;

    logic [4:0] alu_rs1, alu_rs2;

    logic if_stall, id_stall, ex_stall, mem_stall;

    logic [31:0] dmem_wdata_ex_i;

    always_comb begin
	if_stall = branch_en | jal_en | jalr_en;
	id_stall = 0;
	ex_stall = 0;
	mem_stall = 0;
    end

    wire mem_hazard;
    wire div_hazard;
    wire div_ready;
    wire shift_hazard;
    wire shift_ready;

    // IF
    instruction_fetch if_i(.clk(clk),
			   .reset(reset),
			   .run(run),
			   .stall(if_stall),
			   .stall_mem(mem_hazard),
			   .stall_div(div_hazard),
			   .div_ready(div_ready),
			   .stall_shift(shift_hazard),
			   .shift_ready(shift_ready),
			   .insn_addr(insn_addr),
			   .insn_din(insn_din),
			   .insn_we(insn_we),
			   // input
			   .pc_in_en(pc_in_en), // from EX
			   .pc_in(pc_in),       // from EX
			   // output
			   .pc_out(pc),
			   .insn(insn),
			   .run_out(run_if)
			   );

    // ID/WB
    decoder decoder_i(.clk(clk),
		      .reset(reset),
		      .run(run_if),
		      .stall(id_stall),
		      // input
		      .insn(insn), // from ID
		      .pc(pc),     // from ID
		      .reg_we_in(reg_we_out), // from MEM
		      .rd_in(reg_rd),         // from MEM
		      .reg_wdata(reg_wdata),  // from MEM
		      // output
		      .branch_en(branch_en),
		      .jal_en(jal_en),
		      .jalr_en(jalr_en),
		      .mem_re(dmem_re),
		      .mem_we(dmem_we),
		      .mem_to_reg_out(mem_to_reg),
		      .alu_op(alu_op),
		      .mul_op(mul_op),
		      .div_op(div_op),
		      .shift_op(shift_op),
		      .alu_a(alu_a_id),
		      .alu_b(alu_b_id),
		      .alu_rs1(alu_rs1),
		      .alu_rs2(alu_rs2),
		      .alu_bytes(alu_bytes),
		      .reg_we_out(reg_we),
		      .imm(imm_value),
		      .rd_out(rd),
		      .unsigned_flag(unsigned_flag),
		      .mem_dout_src(dmem_wdata_src),
		      .mem_dout(dmem_wdata),
		      // through
		      .pc_out(pc_id),
		      .run_out(run_id),

		      .mem_hazard(mem_hazard),
		      .div_hazard(div_hazard),
		      .div_ready(div_ready),
		      .shift_hazard(shift_hazard),
		      .shift_ready(shift_ready),

		      .emit_insn_mon(emit_insn),
		      .emit_pc_out_mon(emit_pc_out)
		      );

    data_forwarding data_forwarding_i (.clk(clk),
				       .reset(reset),
				       .rs1_id(alu_rs1), // from ID
				       .rs2_id(alu_rs2), // from ID
				       .rd_ex(rd_ex),         // from EX
				       .reg_we_ex(reg_we_ex), // from EX
				       .rd_ma(reg_rd),         // from MA
				       .reg_we_ma(reg_we_out), // from MA

				       .alu_a_id(alu_a_id), // from ID
				       .alu_b_id(alu_b_id), // from ID

				       .alu_result(alu_result), // from EX
				       .reg_wdata(reg_wdata), // from MA

				       .dmem_we(dmem_we),
				       .dmem_re(dmem_re),

				       .alu_a(alu_a), // to EX
				       .alu_b(alu_b)  // to EX
				       );

    // EX
    executer ex_i(.clk(clk),
		  .reset(reset),
		  .run(run_id),
		  .stall(ex_stall),
		  // input
		  .alu_op(alu_op), // from ID
		  .mul_op(mul_op), // from ID
		  .div_op(div_op), // from ID
		  .shift_op(shift_op), // from ID
		  .alu_a(alu_a),   // from ID
		  .alu_b(alu_b),   // from ID
		  .pc(pc_id),      // from ID
		  .imm_value(imm_value), // from ID
		  .branch_en(branch_en), // from ID
		  .jal_en(jal_en),   // from ID
		  .jalr_en(jalr_en), // from ID

		  .unsigned_flag(unsigned_flag),

		  // output
		  .alu_result(alu_result),
		  .alu_unknown_op(alu_unknown_op),
		  .addr_out(pc_in),
		  .addr_out_en(pc_in_en),
		  .div_ready_pre(div_ready),
		  .shift_ready_pre(shift_ready),
		  // through
		  .run_out(run_ex),
		  .mem_to_reg_in(mem_to_reg),
		  .mem_to_reg_out(mem_to_reg_ex),
		  .bytes_in(alu_bytes),
		  .bytes_out(alu_bytes_ex),
		  .wdata_src_in(dmem_wdata_src),
		  .wdata_src_out(dmem_wdata_src_ex),
		  .wdata_in(dmem_wdata),
		  .wdata_out(dmem_wdata_ex),
		  .we_in(dmem_we),
		  .we_out(dmem_we_ex),
		  .re_in(dmem_re),
		  .re_out(dmem_re_ex),
		  .rd_in(rd),
		  .rd_out(rd_ex),
		  .reg_we_in(reg_we),
		  .reg_we_out(reg_we_ex),
		  .unsigned_flag_out(unsigned_flag_ex)
		  );

    mem_forwarding mem_forwarding_i (
				     .dmem_wdata_src_ex(dmem_wdata_src_ex),
				     .reg_rd(reg_rd),
				     .reg_wdata(reg_wdata),
				     .dmem_wdata_ex(dmem_wdata_ex),
				     .dmem_wdata_to_mem(dmem_wdata_ex_i));

    // MEM
    data_memory#(.DEPTH(14))
    dmem_i(.clk(clk),
	   .reset(reset),
	   .run(run_ex),
	   .stall(mem_stall),
	   .addr_b(data_addr),
	   .din_b(data_din),
	   .we_b(data_we),
	   .oe_b(data_oe),
	   .dout_b(data_q),
	   // input
	   .addr(alu_result),     // from EX
	   .bytes(alu_bytes_ex),  // from EX
	   .wdata(dmem_wdata_ex_i), // from EX
	   .we(dmem_we_ex),  // from EX
	   .re(dmem_re_ex),  // from EX
	   .mem_to_reg_in(mem_to_reg_ex), // from EX
	   .alu_result(alu_result), // from EX
	   .rd_in(rd_ex),         // from EX
	   .reg_we_in(reg_we_ex), // from EX
	   .unsigned_flag(unsigned_flag_ex),
	   // output
	   .reg_wdata(reg_wdata),
	   .reg_we_out(reg_we_out),
	   .reg_rd(reg_rd),
	   // peripheral
	   .uart_dout(uart_dout),
	   .uart_we(uart_we)
	   );

    // HALT detector, halt_flag is asserted when core is halt.
    halt_detector halt_detector_i
      (.clk(clk),
       .reset(reset),
       .run_if(run_if),
       .emit_insn(emit_insn),
       .halt_flag(halt_mon)
       );

endmodule // core

`default_nettype wire
