module executer (
		 input logic clk,
		 /* verilator lint_off UNUSED */
		 input logic reset,
		 /* verilator lint_on UNUSED */
		 input logic run,
		 input logic stall,

		 input logic [3:0] alu_op,
		 input logic [3:0] mul_op,
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
		 
		 output logic run_out,
		 input  logic mem_to_reg_in,
		 output logic mem_to_reg_out,
		 input  logic [1:0] bytes_in,
		 output logic [1:0] bytes_out,
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

    wire [31:0] alu_r;
    wire alu_unknown_op_i;
    wire [31:0] addr_out_i;
    wire addr_out_en_i;

    wire [31:0] mul_r;
    wire mul_unknown_op_i;

    logic [1:0] state = 0;
    logic [2:0] stall_counter;

    always_ff @(posedge clk) begin
    	run_out <= run;
	case(state)
	    0: begin
		if(run && !stall) begin
    		    mem_to_reg_out <= mem_to_reg_in;
    		    bytes_out <= bytes_in;
    		    wdata_out <= wdata_in;
    		    we_out <= we_in;
    		    re_out <= re_in;
    		    rd_out <= rd_in;
    		    reg_we_out <= reg_we_in;
		    if(mul_op != 4'b0000) begin
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
	    default: begin
		state <= 0;
	    end
	endcase
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
