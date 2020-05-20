`default_nettype none

module control
  (
   input wire [31:0] insn,

   output logic branch_en, jal_en, jalr_en,
   output logic mem_re,
   output logic mem_we,
   output logic mem_to_reg,
   output logic [3:0] alu_op,
   output logic [3:0] mul_op,
   output logic [3:0] div_op,
   output logic [1:0] shift_op,
   output logic alu_src_a,
   output logic alu_src_b,
   output logic [1:0] alu_bytes,
   output logic reg_we,
   output logic [31:0] imm,
   output logic [4:0] rs1, rs2, rd,
   output logic unsigned_flag
   );

`include "core.svh"

    localparam R0 = 5'd0;

    localparam IMM_R  = 3'd0;
    localparam IMM_I  = 3'd1;
    localparam IMM_S  = 3'd2;
    localparam IMM_U  = 3'd3;
    localparam IMM_B  = 3'd4;
    localparam IMM_J  = 3'd5;
    localparam IMM_SH = 3'd6;
    logic [2:0] imm_t;

    /* verilator lint_off UNUSED */
    wire [6:0] opcode = insn[ 6: 0];
    wire [2:0] funct3 = insn[14:12];
    wire [6:0] funct7 = insn[31:25];
    /* verilator lint_on UNUSED */

    logic [19:0] LOW20  = 20'h0_0000;
    logic [19:0] HIGH20 = 20'hF_FFFF;
    logic [19:0] prefix;

    logic [28:0] param;

    always_comb begin
	shift_op = param[28:27];
	div_op   = param[26:23];
	mul_op   = param[22:19];

	unsigned_flag = param[18];
	imm_t = param[17:15];
	prefix = unsigned_flag ? LOW20 : insn[31] == 1'b0 ? LOW20 : HIGH20;
	case(imm_t)
	    IMM_I  : imm = {prefix[19:0], insn[31:20]};
	    IMM_S  : imm = {prefix[19:0], insn[31:25], insn[11:7]};
	    IMM_U  : imm = {insn[31:12], 12'd0};
	    IMM_B  : imm = {prefix[18:0], insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};
	    IMM_J  : imm = {prefix[10:0], insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};
	    IMM_SH : imm = {27'd0, insn[24:20]};
	    default: imm = 32'd0;
	endcase // case (imm_t)
	
	branch_en     = param[14];
	jal_en        = param[13];
	jalr_en       = param[12];
	mem_re        = param[11];
	mem_we        = param[10];
	mem_to_reg    = param[9];
	alu_op        = param[8:5];
	alu_src_a     = param[4]; // '0' -> rs1, '1' -> pc
	alu_src_b     = param[3]; // '0' -> rs2, '1' -> imm
	alu_bytes     = param[2:1];
	reg_we        = param[0];

	rd  = insn[11: 7];
	rs1 = (imm_t == IMM_U) ? R0 : insn[19:15];
	//rs2 = (imm_t == IMM_R || imm_t == IMM_S) ? insn[24:20] : R0;
	rs2 = (imm_t == IMM_J) ? R0 : insn[24:20];

    end

    always_comb begin
	casez(insn)
	    LUI  : param = {10'd0, 1'b0, IMM_U, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    AUIPC: param = {10'd0, 1'b0, IMM_U, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b1, 2'b00, 1'b1};

	    JAL  : param = {10'd0, 1'b0, IMM_J, 3'b010, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b1, 1'b0, 2'b00, 1'b1};
	    JALR : param = {10'd0, 1'b0, IMM_I, 3'b001, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};

	    BEQ  : param = {10'd0, 1'b0, IMM_B, 3'b100, 1'b0, 1'b0, 1'b0, ALU_EQ,  1'b0, 1'b0, 2'b00, 1'b0};
	    BNE  : param = {10'd0, 1'b0, IMM_B, 3'b100, 1'b0, 1'b0, 1'b0, ALU_NE,  1'b0, 1'b0, 2'b00, 1'b0};
	    BLT  : param = {10'd0, 1'b0, IMM_B, 3'b100, 1'b0, 1'b0, 1'b0, ALU_LT,  1'b0, 1'b0, 2'b00, 1'b0};
	    BGE  : param = {10'd0, 1'b0, IMM_B, 3'b100, 1'b0, 1'b0, 1'b0, ALU_GE,  1'b0, 1'b0, 2'b00, 1'b0};
	    BLTU : param = {10'd0, 1'b1, IMM_B, 3'b100, 1'b0, 1'b0, 1'b0, ALU_LT,  1'b0, 1'b0, 2'b00, 1'b0};
	    BGEU : param = {10'd0, 1'b1, IMM_B, 3'b100, 1'b0, 1'b0, 1'b0, ALU_GE,  1'b0, 1'b0, 2'b00, 1'b0};

	    LB   : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b1, 1'b0, 1'b1, ALU_ADD, 1'b0, 1'b1, 2'b01, 1'b1};
	    LH   : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b1, 1'b0, 1'b1, ALU_ADD, 1'b0, 1'b1, 2'b10, 1'b1};
	    LW   : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b1, 1'b0, 1'b1, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    LBU  : param = {10'd0, 1'b1, IMM_I, 3'b000, 1'b1, 1'b0, 1'b1, ALU_ADD, 1'b0, 1'b1, 2'b01, 1'b1};
	    LHU  : param = {10'd0, 1'b1, IMM_I, 3'b000, 1'b1, 1'b0, 1'b1, ALU_ADD, 1'b0, 1'b1, 2'b10, 1'b1};

	    SB   : param = {10'd0, 1'b0, IMM_S, 3'b000, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b01, 1'b0};
	    SH   : param = {10'd0, 1'b0, IMM_S, 3'b000, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b10, 1'b0};
	    SW   : param = {10'd0, 1'b0, IMM_S, 3'b000, 1'b0, 1'b1, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b0};

	    ADDI : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    SLTI : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b0, 1'b0, 1'b0, ALU_LT,  1'b0, 1'b1, 2'b00, 1'b1};
	    SLTIU: param = {10'd0, 1'b1, IMM_I, 3'b000, 1'b0, 1'b0, 1'b0, ALU_LT,  1'b0, 1'b1, 2'b00, 1'b1};
	    XORI : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b0, 1'b0, 1'b0, ALU_XOR, 1'b0, 1'b1, 2'b00, 1'b1};
	    ORI  : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b0, 1'b0, 1'b0, ALU_OR,  1'b0, 1'b1, 2'b00, 1'b1};
	    ANDI : param = {10'd0, 1'b0, IMM_I, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b1, 2'b00, 1'b1};

	    ADD   : param = {10'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b0, 2'b00, 1'b1};
	    SUB   : param = {10'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_SUB, 1'b0, 1'b0, 2'b00, 1'b1};
	    SLT   : param = {10'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_LT,  1'b0, 1'b0, 2'b00, 1'b1};
	    SLTU  : param = {10'd0, 1'b1, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_LT,  1'b0, 1'b0, 2'b00, 1'b1};
	    XOR   : param = {10'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_XOR, 1'b0, 1'b0, 2'b00, 1'b1};
	    OR    : param = {10'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_OR,  1'b0, 1'b0, 2'b00, 1'b1};
	    AND   : param = {10'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};

	    SLLI  : param = {SH_SLL, 8'd0, 1'b0, IMM_SH, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    SRLI  : param = {SH_SRL, 8'd0, 1'b0, IMM_SH, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    SRAI  : param = {SH_SRA, 8'd0, 1'b0, IMM_SH, 3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b1, 2'b00, 1'b1};
	    SLL   : param = {SH_SLL, 8'd0, 1'b0, IMM_R,  3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b0, 2'b00, 1'b1};
	    SRL   : param = {SH_SRL, 8'd0, 1'b0, IMM_R,  3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b0, 2'b00, 1'b1};
	    SRA   : param = {SH_SRA, 8'd0, 1'b0, IMM_R,  3'b000, 1'b0, 1'b0, 1'b0, ALU_ADD, 1'b0, 1'b0, 2'b00, 1'b1};
	    
	    MUL    : param = {6'd0, MUL_MUL,    1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};
	    MULH   : param = {6'd0, MUL_MULH,   1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};
	    MULHSU : param = {6'd0, MUL_MULHSU, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};
	    MULHU  : param = {6'd0, MUL_MULHU,  1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};

	    DIV    : param = {2'd0, DIV_DIV, 4'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};
	    REM    : param = {2'd0, DIV_REM, 4'd0, 1'b0, IMM_R, 3'b000, 1'b0, 1'b0, 1'b0, ALU_AND, 1'b0, 1'b0, 2'b00, 1'b1};

	endcase // case (insn)
    end

endmodule // control

`default_nettype wire
