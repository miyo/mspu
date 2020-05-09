`default_nettype none

module decoder
  (
   // system
   input wire clk,
   input wire reset,
   input wire run,

   // input
   input wire [31:0] insn,
   input wire [31:0] pc,
   input logic reg_we_in,
   input logic [4:0] rd_in,
   input logic [31:0] reg_wdata,

   // output
   output logic branch_en, jal_en, jalr_en,
   output logic mem_re,
   output logic mem_we,
   output logic mem_to_reg_out,
   output logic [3:0] alu_op,
   output logic [31:0] alu_a,
   output logic [31:0] alu_b,
   output logic [1:0] alu_bytes,
   output logic reg_we_out,
   output logic [31:0] imm,
   output logic [4:0] rd_out,
   output logic [31:0] mem_dout,
   output logic [31:0] pc_out
   );

    logic alu_src_a, alu_src_b;
    logic [4:0] rs1, rs2;
    logic [31:0] imm_value;

    assign imm = imm_value;

    assign pc_out = pc;

    control control_i(.insn(insn),
		      .branch_en(branch_en),
		      .jal_en(jal_en),
		      .jalr_en(jalr_en),
		      .mem_re(mem_re),
		      .mem_we(mem_we),
		      .mem_to_reg(mem_to_reg_out),
		      .alu_op(alu_op),
		      .alu_src_a(alu_src_a),
		      .alu_src_b(alu_src_b),
		      .alu_bytes(alu_bytes),
		      .reg_we(reg_we_out),
		      .imm(imm_value),
		      .rs1(rs1),
		      .rs2(rs2),
		      .rd(rd_out)
		      );

    logic [31:0] reg_a, reg_b;
    assign alu_a = alu_src_a == 0 ? reg_a : pc;
    assign alu_b = alu_src_b == 0 ? reg_b : imm_value;
    assign mem_dout = reg_b;

    registers rf_i(.clk(clk),
		   .reset(reset),
		   .run(run),
		   .raddr_a(rs1),
		   .raddr_b(rs2),
		   .rdata_a(reg_a),
		   .rdata_b(reg_b),
		   .waddr(rd_in),
		   .wdata(reg_wdata),
		   .reg_we(reg_we_in)
		   );

endmodule // decoder

`default_nettype wire
