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
   input wire        data_we
   );

    localparam START_ADDR = 32'h8000_0000;
    
    wire [31:0] insn;
    wire [31:0] reg_a, reg_b;
    wire [4:0]  rs1, rs2, rd;
    wire [31:0] reg_wdata;
    wire [31:0] alu_a, alu_b;
    wire        alu_zero;
    wire [31:0] alu_result;
    wire        alu_unknown_op;
    wire [31:0] dmem_rdata;
    wire [31:0] imm_value;
    wire [31:0] immgen_out;
    wire [31:0] shift_left_1_out;

    wire [3:0] alu_op;
    wire reg_we;
    wire dmem_we, dmem_re;
    wire mem_to_reg;
    wire branch_en, jal_en, jalr_en;
    wire alu_src_a, alu_src_b;
    wire [1:0] alu_bytes;

    // program counter
    logic [31:0] pc = START_ADDR;

    logic [31:0] npc;
    logic pc_src;
    always_comb begin
	pc_src = (branch_en & alu_result[0]) | jal_en;
	if(reset == 1'b1 || run == 1'b0)
	  npc = START_ADDR;
	else if(pc_src)
	  npc = pc + shift_left_1_out;
	else if(jalr_en)
	  npc = alu_result + 4;
	else
	  npc = pc + 4;
    end

    always @(posedge clk) begin
	pc <= npc;
    end
    
    instruction_memory#(.DEPTH(12))
    imem_i(.clk(clk),
	 .reset(reset),
	 .pc(pc),
	 .insn(insn),
	 .addr(insn_addr),
	 .din(insn_din),
	 .we(insn_we)
	 );
    
    registers rf_i(.clk(clk),
		   .reset(reset),
		   .run(run),
		   .raddr_a(rs1),
		   .rdata_a(reg_a),
		   .raddr_b(rs2),
		   .rdata_b(reg_b),
		   .waddr(rd),
		   .wdata(reg_wdata),
		   .reg_we(reg_we)
		   );

    assign alu_a = alu_src_a == 0 ? reg_a : pc;
    assign alu_b = alu_src_b == 0 ? reg_b : imm_value;

    alu alu_i(.clk(clk),
	      .reset(reset),
	      .alu_op(alu_op),
	      .a(alu_a),
	      .b(alu_b),
	      .zero(alu_zero),
	      .result(alu_result),
	      .unknown_op(alu_unknown_op)
	      );

    data_memory#(.DEPTH(12))
    dmem_i(.clk(clk),
	   .reset(reset),
	   .addr(alu_result),
	   .bytes(alu_bytes),
	   .rdata(dmem_rdata),
	   .re(dmem_re),
	   .wdata(reg_b),
	   .we(dmem_we),
	   .addr_b(data_addr),
	   .din_b(data_din),
	   .we_b(data_we)
	   );

    assign reg_wdata = mem_to_reg ? dmem_rdata : alu_result;

    immgen immgen_i(.d(imm_value), .q(immgen_out));
    shift_left_1 shift_left_1(.d(immgen_out), .q(shift_left_1_out));

    decoder decoder_i(.insn(insn),
		      .branch_en(branch_en),
		      .jal_en(jal_en),
		      .jalr_en(jalr_en),
		      .mem_re(dmem_re),
		      .mem_we(dmem_we),
		      .mem_to_reg(mem_to_reg),
		      .alu_op(alu_op),
		      .alu_src_a(alu_src_a),
		      .alu_src_b(alu_src_b),
		      .alu_bytes(alu_bytes),
		      .reg_we(reg_we),
		      .imm(imm_value),
		      .rs1(rs1),
		      .rs2(rs2),
		      .rd(rd)
		      );

endmodule // core

`default_nettype wire
