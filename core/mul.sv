`default_nettype none

module mul
  (
   input wire [3:0] mul_op,

   input wire signed [31:0] a,
   input wire signed [31:0] b,

   output logic signed [31:0] result,
   output logic unknown_op
   );

`include "core.svh"

    logic signed [31:0] mul_r;
    logic unknown_op_r;

    always_comb begin
	result = mul_r;
	unknown_op = unknown_op_r;
    end

    wire unsigned [31:0] ua;
    wire unsigned [31:0] ub;
    assign ua = a;
    assign ub = b;

    logic [63:0] a_b;
    /* verilator lint_off UNUSED */
    logic [63:0] ua_ub; // unused [31:0]
    logic [63:0] a_ub;  // unused [31:0]
    /* verilator lint_off UNUSED */

    always_comb begin
	unknown_op_r = 0;
	a_b = a * b;
	ua_ub = ua * ub;
	a_ub = a * ub;
	case (mul_op)
	    MUL_MUL    : mul_r = a_b[31:0];
	    MUL_MULH   : mul_r = a_b[63:32];
	    MUL_MULHSU : mul_r = a_ub[63:32];
	    MUL_MULHU  : mul_r = ua_ub[63:32];
	    default: begin
		mul_r = 0;
		unknown_op_r = 1;
	    end
	endcase // case (op)
    end

endmodule // registers

`default_nettype wire
