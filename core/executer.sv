module executer (
		 input logic clk,
		 input logic reset,
		 input logic run,
		 input logic stall,

		 input logic [3:0] alu_op,
		 input logic [31:0] alu_a,
		 input logic [31:0] alu_b,

		 input logic [31:0] pc,
		 input logic [31:0] imm_value,
		 input logic branch_en,
		 input logic jal_en,
		 input logic jalr_en,

		 input logic [31:0] alu_a_ex,
		 input logic [31:0] alu_a_mem,
		 input logic [1:0]  alu_a_src,

		 input logic [31:0] alu_b_ex,
		 input logic [31:0] alu_b_mem,
		 input logic [1:0]  alu_b_src,

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
		 output logic reg_we_out
		 );

    wire [31:0] alu_r;
    wire [31:0] addr_out_i;
    wire addr_out_en_i;

    always_ff @(posedge clk) begin
    	run_out <= run;
	if(run && !stall) begin
    	    mem_to_reg_out <= mem_to_reg_in;
    	    bytes_out <= bytes_in;
    	    wdata_out <= wdata_in;
    	    we_out <= we_in;
    	    re_out <= re_in;
    	    rd_out <= rd_in;
    	    reg_we_out <= reg_we_in;
    	    alu_result <= alu_r;
    	    run_out <= 1'b1;
	    addr_out <= addr_out_i;
	    addr_out_en <= addr_out_en_i;
	end else begin
    	    run_out <= 1'b0;
	end
    end

    logic [31:0] alu_a_i, alu_b_i;

    always_comb begin
	alu_a_i = alu_a_src == 2'd1 ? alu_a_ex :
		  alu_a_src == 2'd2 ? alu_a_mem :
		  alu_a;
	alu_b_i = alu_b_src == 2'd1 ? alu_b_ex :
		  alu_b_src == 2'd2 ? alu_b_mem :
		  alu_b;
    end

    alu alu_i(.alu_op(alu_op),
	      .a(alu_a_i),
	      .b(alu_b_i),
	      .zero(),
	      .result(alu_r),
	      .unknown_op(alu_unknown_op)
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
