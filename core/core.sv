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

   output wire [31:0] uart_dout,
   output wire        uart_we
   );

    wire run_if, run_id, run_ex;
    
    wire [31:0] insn;
    wire [4:0]  rs1, rs2, rd;
    wire [4:0] reg_rd;
    wire [31:0] reg_wdata;
    wire [31:0] alu_a, alu_b;
    wire [31:0] alu_result;
    wire        alu_unknown_op;
    wire [31:0] dmem_rdata;
    wire [31:0] imm_value;
    wire [31:0] immgen_out;
    wire [31:0] shift_left_1_out;

    wire [3:0] alu_op;
    wire reg_we, reg_we_out;
    wire dmem_we, dmem_re;
    wire [31:0] dmem_wdata;
    wire mem_to_reg, mem_to_reg_in;
    wire branch_en, jal_en, jalr_en;
    wire [1:0] alu_bytes;

    wire [31:0] pc, pc_id;
    wire [31:0] pc_in;
    wire pc_in_en;

    wire mem_to_reg_ex;
    wire [1:0] alu_bytes_ex;
    wire [31:0] dmem_wdata_ex;
    wire dmem_we_ex;
    wire dmem_re_ex;
    wire [4:0] rd_ex;
    wire reg_we_ex;

    logic [4:0] alu_rs1, alu_rs2;
    logic [1:0] alu_a_src, alu_b_src;

    logic if_stall, id_stall, ex_stall, mem_stall;

    logic jump_reg;
    logic pc_in_en_reg;
    wire jump = branch_en | jal_en | jalr_en;
    always_ff @(posedge clk) begin
	jump_reg <= jump;
	pc_in_en_reg <= pc_in_en;
    end

    always_comb begin
	//if_stall = (jump & ~jump_reg) | (pc_in_en & ~pc_in_en_reg);
	//id_stall = (pc_in_en & ~pc_in_en_reg);
	if_stall = (jump & ~jump_reg);
	id_stall = (jump & ~jump_reg);
	ex_stall = 0;
	mem_stall = 0;
    end

    // IF
    instruction_fetch if_i(.clk(clk),
			   .reset(reset),
			   .run(run),
			   .stall(if_stall),
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
		      .alu_a(alu_a),
		      .alu_b(alu_b),
		      .alu_rs1(alu_rs1),
		      .alu_rs2(alu_rs2),
		      .alu_bytes(alu_bytes),
		      .reg_we_out(reg_we),
		      .imm(imm_value),
		      .rd_out(rd),
		      .mem_dout(dmem_wdata),
		      // through
		      .pc_out(pc_id),
		      .run_out(run_id)
		      );

    always_comb begin
	if(reg_we_ex && rd_ex != 0 && rd_ex == alu_rs1)
	  alu_a_src = 2'd1;
	else if(reg_we_out && reg_rd != 0 && reg_rd == alu_rs1)
	  alu_a_src = 2'd2;
	else
	  alu_a_src = 2'd0;
	
	if(reg_we_ex && rd_ex != 0 && rd_ex == alu_rs2)
	  alu_b_src = 2'd1;
	else if(reg_we_out && reg_rd != 0 && reg_rd == alu_rs2)
	  alu_b_src = 2'd2;
	else
	  alu_b_src = 2'd0;
    end

    // EX
    executer ex_i(.clk(clk),
		  .reset(reset),
		  .run(run_id),
		  .stall(ex_stall),
		  // input
		  .alu_op(alu_op), // from ID
		  .alu_a(alu_a),   // from ID
		  .alu_b(alu_b),   // from ID
		  .pc(pc_id),      // from ID
		  .imm_value(imm_value), // from ID
		  .branch_en(branch_en), // from ID
		  .jal_en(jal_en),   // from ID
		  .jalr_en(jalr_en), // from ID

		  .alu_a_ex(alu_result),
		  .alu_a_mem(reg_wdata),
		  .alu_a_src(alu_a_src),

		  .alu_b_ex(alu_result),
		  .alu_b_mem(reg_wdata),
		  .alu_b_src(alu_b_src),

		  // output
		  .alu_result(alu_result),
		  .alu_unknown_op(alu_unknown_op),
		  .addr_out(pc_in),
		  .addr_out_en(pc_in_en),
		  // through
		  .run_out(run_ex),
		  .mem_to_reg_in(mem_to_reg),
		  .mem_to_reg_out(mem_to_reg_ex),
		  .bytes_in(alu_bytes),
		  .bytes_out(alu_bytes_ex),
		  .wdata_in(dmem_wdata),
		  .wdata_out(dmem_wdata_ex),
		  .we_in(dmem_we),
		  .we_out(dmem_we_ex),
		  .re_in(dmem_re),
		  .re_out(dmem_re_ex),
		  .rd_in(rd),
		  .rd_out(rd_ex),
		  .reg_we_in(reg_we),
		  .reg_we_out(reg_we_ex)
		  );

    // MEM
    data_memory#(.DEPTH(12))
    dmem_i(.clk(clk),
	   .reset(reset),
	   .run(run_ex),
	   .stall(mem_stall),
	   .addr_b(data_addr),
	   .din_b(data_din),
	   .we_b(data_we),
	   // input
	   .addr(alu_result),     // from EX
	   .bytes(alu_bytes_ex),  // from EX
	   .wdata(dmem_wdata_ex), // from EX
	   .we(dmem_we_ex),  // from EX
	   .re(dmem_re_ex),  // from EX
	   .mem_to_reg_in(mem_to_reg_ex), // from EX
	   .alu_result(alu_result), // from EX
	   .rd_in(rd_ex),         // from EX
	   .reg_we_in(reg_we_ex), // from EX
	   // output
	   .reg_wdata(reg_wdata),
	   .reg_we_out(reg_we_out),
	   .reg_rd(reg_rd),
	   // peripheral
	   .uart_dout(uart_dout),
	   .uart_we(uart_we)
	   );

endmodule // core

`default_nettype wire
