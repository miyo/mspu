module executer (
		 input logic clk,
		 input logic reset,
		 input logic run,
		 input logic stall,

		 input logic [3:0] alu_op,
		 input logic [3:0] mul_op,
		 input logic [3:0] div_op,
		 input logic [1:0] shift_op,
		 input logic [31:0] alu_a,
		 input logic [31:0] alu_b,

		 input logic [31:0] pc,
		 input logic [31:0] imm_value,
		 input logic branch_en,
		 input logic jal_en,
		 input logic jalr_en,

		 input logic unsigned_flag,

		 output logic [31:0] alu_result,
		 output logic alu_unknown_op,
		 output logic [31:0] addr_out,
		 output logic addr_out_en,
		 output logic div_ready_pre,
		 output logic shift_ready_pre,
		 
		 output logic run_out,
		 input  logic mem_to_reg_in,
		 output logic mem_to_reg_out,
		 input  logic [1:0] bytes_in,
		 output logic [1:0] bytes_out,
		 input  logic [4:0] wdata_src_in,
		 output logic [4:0] wdata_src_out,
		 input  logic [31:0] wdata_in,
		 output logic [31:0] wdata_out,
		 input  logic we_in,
		 output logic we_out,
		 input  logic re_in,
		 output logic re_out,
		 input  logic [4:0] rd_in,
		 output logic [4:0] rd_out,
		 input  logic reg_we_in,
		 output logic reg_we_out,
		 output logic unsigned_flag_out
		 );

`include "core.svh"

    wire [31:0] alu_r;
    wire alu_unknown_op_i;
    wire [31:0] addr_out_i;
    wire addr_out_en_i;

    wire [31:0] mul_r;
    wire mul_unknown_op_i;

    logic div_kick, div_ready;
    logic [31:0] div_quotient;
    logic [31:0] div_remainder;
    logic div_unsigned_flag;
    logic [31:0] div_a, div_b;

    logic shift_kick, shift_ready;
    logic [31:0] shift_q;
    logic [31:0] shift_a, shift_b;
    logic shift_unsigned_flag;
    logic shift_lshift_flag;

    logic [2:0] state = 0;
    logic [2:0] stall_counter;
    logic shift_ready_pre_i;
    logic shift_nop = 0;

    assign shift_ready_pre = shift_ready_pre_i || shift_nop;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state <= 0;
	    alu_result <= 0;
	end else begin
    	    run_out <= run;
	    case(state)
		0: begin
		    if(run && !stall) begin
    			mem_to_reg_out <= mem_to_reg_in;
    			bytes_out <= bytes_in;
    			wdata_src_out <= wdata_src_in;
    			wdata_out <= wdata_in;
    			we_out <= we_in;
    			re_out <= re_in;
    			rd_out <= rd_in;
    			reg_we_out <= reg_we_in;
			if(shift_op != SH_NOP) begin
			    if(alu_b == 0) begin
				shift_nop <= 1;
			    end else begin
				shift_kick <= 1;
				shift_unsigned_flag <= unsigned_flag;
				shift_lshift_flag <= (shift_op == SH_SLL) ? 1'b1 : 1'b0;
				shift_nop <= 0;
			    end
			    state <= state + 3;
    			    reg_we_out <= 1'b0;
			    shift_a <= alu_a;
			    shift_b <= alu_b;
			end else if(div_op != DIV_NOP) begin
    			    reg_we_out <= 1'b0;
			    div_kick <= 1;
			    div_a <= alu_a;
			    div_b <= alu_b;
			    div_unsigned_flag <= unsigned_flag;
			    state <= state + 2;
			end else if(mul_op != MUL_NOP) begin
			    alu_result <= mul_r;
			    alu_unknown_op <= mul_unknown_op_i;
			end else begin
    			    alu_result <= alu_r;
			    alu_unknown_op <= alu_unknown_op_i;
			end
			addr_out <= addr_out_i;
			addr_out_en <= addr_out_en_i;
			unsigned_flag_out <= unsigned_flag;
			if(addr_out_en_i == 1) begin
			    state <= state + 1;
			    stall_counter <= 2;
			end
		    end else begin
		    end
		end
		1: begin
		    addr_out_en <= 1'b0;
		    if(stall_counter == 0) begin
			state <= 0;
		    end else begin
			stall_counter <= stall_counter - 1;
		    end
		end
		2: begin
		    div_kick <= 0;
		    shift_nop <= 0;
		    if(div_kick == 0 && div_ready == 1) begin
			if(div_op == DIV_DIV) begin
    			    reg_we_out <= 1'b1;
			    alu_result <= div_quotient;
			    alu_unknown_op <= 0;
			end else if(div_op == DIV_REM) begin
    			    reg_we_out <= 1'b1;
			    alu_result <= div_remainder;
			    alu_unknown_op <= 0;
			end else begin
			    alu_unknown_op <= 1;
			end
			state <= 0;
		    end
		end
		3: begin
		    shift_kick <= 0;
		    if(shift_kick == 0 && shift_ready == 1) begin
    			reg_we_out <= 1'b1;
			if(shift_nop) begin
			    alu_result <= shift_a;
			end else begin
			    alu_result <= shift_q;
			end
			alu_unknown_op <= 0;
			state <= 0;
		    end
		end
		default: begin
		    state <= 0;
		end
	    endcase // case (state)
	end // else: !if(reset == 1)
    end

    /* verilator lint_off PINCONNECTEMPTY */
    alu alu_i(.alu_op(alu_op),
	      .a(alu_a),
	      .b(alu_b),
	      .unsigned_flag(unsigned_flag),
	      .zero(),
	      .result(alu_r),
	      .unknown_op(alu_unknown_op_i)
	      );
    /* verilator lint_on PINCONNECTEMPTY */

    mul mul_i(.mul_op(mul_op),
	      .a(alu_a),
	      .b(alu_b),
	      .result(mul_r),
	      .unknown_op(mul_unknown_op_i)
	      );

    div div_i(.clk(clk),
	      .reset(reset),
	      .kick(div_kick),
	      .unsigned_flag(div_unsigned_flag),
	      .dividend(div_a),
	      .divider(div_b),
	      .ready(div_ready),
	      .ready_pre(div_ready_pre),
	      .quotient(div_quotient),
	      .remainder(div_remainder)
	      );

    shift shift_i(.clk(clk),
		  .reset(reset),
		  .kick(shift_kick),
		  .unsigned_flag(shift_unsigned_flag),
		  .lshift(shift_lshift_flag),
		  .a(shift_a),
		  .b(shift_b),
		  .ready(shift_ready),
		  .ready_pre(shift_ready_pre_i),
		  .q(shift_q)
		  );

    addr_calc addr_calc_i(.pc(pc),
			  .imm(imm_value),
			  .alu_result(alu_r),
			  .branch_en(branch_en),
			  .jal_en(jal_en),
			  .jalr_en(jalr_en),
			  .addr_out(addr_out_i),
			  .addr_out_en(addr_out_en_i)
			  );

endmodule // executer
