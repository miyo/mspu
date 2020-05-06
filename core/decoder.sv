`default_nettype none

module decoder
  (
   input wire [31:0] insn,

   output wire branch_en, jal_en, jalr_en,
   output wire mem_re,
   output wire mem_we,
   output wire mem_to_reg,
   output wire [3:0] alu_op,
   output wire alu_src_a,
   output wire alu_src_b,
   output wire [1:0] alu_bytes,
   output wire reg_we,
   output wire [31:0] imm,
   output wire [4:0] rs1, rs2, rd
   );

`include "core.svh"

/*
 *     +---------------------+--------+-----------+--------+-----------+
 * I:  |imm[11:0]            |rs1[4:0]|funct3[2:0]|rd[4:0] |opcode[6:0]|
 * S:  |imm[11:5]   |rs2[4:0]|rs1[4:0]|funct3[2:0]|imm[4:0]|opcode[6:0]|
 * R:  |funct7[11:5]|rs2[4:0]|rs1[4:0]|funct3[2:0]|rd[4:0] |opcode[6:0]|
 * U:  |imm[31:12]                                |rd[4:0] |opcode[6:0]|
 *     +---------------------+--------+-----------+--------+-----------+
 */

    localparam IMM_I = 3'd1;
    localparam IMM_S = 3'd2;
    localparam IMM_U = 3'd3;
    localparam IMM_B = 3'd4;
    localparam IMM_J = 3'd5;
    wire [2:0] imm_t;

    wire [6:0] opcode = insn[ 6: 0];
    assign rd     = insn[11: 7];
    wire [2:0] funct3 = insn[14:12];
    assign rs1    = (imm_t == IMM_U) ? 5'd0 : insn[19:15];
    assign rs2    = insn[24:20];
    wire [6:0] funct7 = insn[31:25];

    assign imm = imm_t==IMM_I ? {20'd0, insn[31:20]} :
		 imm_t==IMM_S ? {20'd0, insn[31:25], insn[11:7]} :
		 imm_t==IMM_U ? {insn[31:12], 12'd0} :
		 imm_t==IMM_B ? {19'd0, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0} :
		 imm_t==IMM_J ? {3'b0, 8'h0, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0} :
		 32'd0;

    wire [17:0] param;
    assign imm_t      = param[17:15];
    assign branch_en  = param[14];
    assign jal_en     = param[13];
    assign jalr_en    = param[12];
    assign mem_re     = param[11];
    assign mem_we     = param[10];
    assign mem_to_reg = param[9];
    assign alu_op     = param[8:5];
    assign alu_src_a  = param[4];
    assign alu_src_b  = param[3];
    assign alu_bytes  = param[2:1];
    assign reg_we     = param[0];

    always_comb begin
	casez(insn)
	    BEQ  : param = {IMM_B, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_EQ,  1'b0, 1'b0, 2'b00, 1'b0};
	    JALR : param = {IMM_I, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    JAL  : param = {IMM_J, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, ALU_NOP, 1'b1, 1'b0, 2'b00, 1'b1};
	    LUI  : param = {IMM_U, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    AUIPC: param = {IMM_U, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b1, 2'b00, 1'b1};
	    ADDI : param = {IMM_I, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    LB   : param = {IMM_I, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, ALU_NOP, 1'b0, 1'b0, 2'b01, 1'b1};
	    SB   : param = {3'd0,  1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, ALU_NOP, 1'b0, 1'b0, 2'b01, 1'b0};
	endcase // case (insn)
    end

endmodule // decoder


`default_nettype wire

