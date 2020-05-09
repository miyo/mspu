`default_nettype none

module alu
  (
   input wire [3:0] alu_op,

   input wire [31:0] a,
   input wire [31:0] b,

   output logic zero,
   output logic [31:0] result,
   output logic unknown_op
   );

`include "core.svh"

    logic [31:0] alu_r;
    logic unknown_op_r;

    always_comb begin
	result = alu_r;
	zero = alu_r == 32'd0 ? 1'b1 : 1'b0;
	unknown_op = unknown_op_r;
    end

    always_comb begin
	unknown_op_r = 0;
	case (alu_op)
	    ALU_AND : alu_r = a & b;
	    ALU_OR  : alu_r = a | b;
	    ALU_ADD : alu_r = a + b;
	    ALU_SUB : alu_r = a - b;
	    ALU_EQ  : alu_r = (a == b) ? 32'b1 : 32'b0;
	    default: unknown_op_r = 1;
	endcase // case (op)
    end

endmodule // registers

`default_nettype wire


