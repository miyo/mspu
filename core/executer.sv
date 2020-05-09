module executer (
		 input wire clk,
		 input wire reset,
		 input wire run,

		 input wire [3:0] alu_op,
		 input wire [31:0] alu_a,
		 input wire [31:0] alu_b,

		 input wire [31:0] pc,
		 input wire [31:0] imm_value,
		 input wire branch_en,
		 input wire jal_en,
		 input wire jalr_en,

		 output wire [31:0] alu_result,
		 output wire alu_unknown_op,
		 output wire [31:0] addr_out,
		 output wire addr_out_en,
		 
		 input  wire mem_to_reg_in,
		 output wire mem_to_reg_out,
		 input  wire [1:0] bytes_in,
		 output wire [1:0] bytes_out,
		 input  wire [31:0] wdata_in,
		 output wire [31:0] wdata_out,
		 input  wire we_in,
		 output wire we_out,
		 input  wire re_in,
		 output wire re_out,
		 input  wire [4:0] rd_in,
		 output wire [4:0] rd_out,
		 input  wire reg_we_in,
		 output wire reg_we_out
		 );

    always_comb begin
    	mem_to_reg_out = mem_to_reg_in;
	bytes_out = bytes_in;
	wdata_out = wdata_in;
	we_out = we_in;
	re_out = re_in;
	rd_out = rd_in;
	reg_we_out = reg_we_in;
    end

    wire [31:0] alu_r;
    assign alu_result = alu_r;

    alu alu_i(.alu_op(alu_op),
	      .a(alu_a),
	      .b(alu_b),
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
			  .addr_out(addr_out),
			  .addr_out_en(addr_out_en)
			  );

endmodule // executer
