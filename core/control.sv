`default_nettype none

module control
  (
   input wire [31:0] insn,

   output logic branch_en, jal_en, jalr_en,
   output logic mem_re,
   output logic mem_we,
   output logic mem_to_reg,
   output logic [3:0] alu_op,
   output logic alu_src_a,
   output logic alu_src_b,
   output logic [1:0] alu_bytes,
   output logic reg_we,
   output logic [31:0] imm,
   output logic [4:0] rs1, rs2, rd
   );

`include "core.svh"

    localparam R0 = 5'd0;

    localparam IMM_I = 3'd1;
    localparam IMM_S = 3'd2;
    localparam IMM_U = 3'd3;
    localparam IMM_B = 3'd4;
    localparam IMM_J = 3'd5;
    wire [2:0] imm_t;

    wire [17:0] param;

    wire [6:0] opcode = insn[ 6: 0];
    wire [2:0] funct3 = insn[14:12];
    wire [6:0] funct7 = insn[31:25];

    logic [31:0] LOW32  = 32'h0000_0000;
    logic [31:0] HIGH32 = 32'hFFFF_FFFF;
    logic [31:0] prefix;
    always_comb begin
	imm_t = param[17:15];
	prefix = (insn[31] == 1'b0) ? LOW32 : HIGH32;
	case(imm_t)
	    IMM_I : imm = {prefix[19:0], insn[31:20]};
	    IMM_S : imm = {prefix[19:0], insn[31:25], insn[11:7]};
	    IMM_U : imm = {insn[31:12], 12'd0};
	    IMM_B : imm = {prefix[18:0], insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};
	    IMM_J : imm = {prefix[10:0], insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};
	    default: imm = 32'd0;
	endcase // case (imm_t)
	
	rd  = insn[11: 7];
	rs1 = (imm_t == IMM_U) ? R0 : insn[19:15];
	rs2 = (imm_t == IMM_J) ? R0 : insn[24:20];
	
	branch_en  = param[14];
	jal_en     = param[13];
	jalr_en    = param[12];
	mem_re     = param[11];
	mem_we     = param[10];
	mem_to_reg = param[9];
	alu_op     = param[8:5];
	alu_src_a  = param[4]; // '0' -> rs1, '1' -> pc
	alu_src_b  = param[3]; // '0' -> rs2, '1' -> imm
	alu_bytes  = param[2:1];
	reg_we     = param[0];
    end

    always_comb begin
	casez(insn)
	    BEQ  : param = {IMM_B, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_EQ,  1'b0, 1'b0, 2'b00, 1'b0};
	    JALR : param = {IMM_I, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    JAL  : param = {IMM_J, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b0, 2'b00, 1'b1};
	    LUI  : param = {IMM_U, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    AUIPC: param = {IMM_U, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b1, 2'b00, 1'b1};
	    ADDI : param = {IMM_I, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    LB   : param = {IMM_I, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, ALU_ADD, 1'b0, 1'b1, 2'b01, 1'b1};
	    SB   : param = {IMM_S, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b01, 1'b0};
	endcase // case (insn)
    end

endmodule // control

`default_nettype wire
