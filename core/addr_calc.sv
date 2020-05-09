module addr_calc(
		 input wire [31:0] pc,
		 input wire [31:0] imm,
		 input wire [31:0] alu_result,
		 input wire branch_en,
		 input wire jal_en,
		 input wire jalr_en,
		 output wire [31:0] addr_out,
		 output wire        addr_out_en
		 );

    always_comb begin
	if((branch_en & alu_result[0]) | jal_en) begin
	    addr_out = pc + imm;
	    addr_out_en = 1'b1;
	end else if(jalr_en) begin
	    addr_out = alu_result + 4;
	    addr_out_en = 1'b1;
	end else begin
	    addr_out_en = 1'b0;
	end
    end

endmodule // addr_calc
