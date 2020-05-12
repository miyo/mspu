module data_forwarding
  (
   input logic [4:0] rs1_id,
   input logic [4:0] rs2_id,

   input logic [4:0] rd_ex,
   input logic reg_we_ex,

   input logic [4:0] rd_ma,
   input logic reg_we_ma,

   input logic [31:0] alu_a_id,
   input logic [31:0] alu_b_id,

   input logic [31:0] alu_result,
   input logic [31:0] reg_wdata,

   output logic [31:0] alu_a,
   output logic [31:0] alu_b
   );

    logic [1:0] alu_a_src, alu_b_src;

    always_comb begin
	if(reg_we_ex && rd_ex != 0 && rd_ex == rs1_id)
	  alu_a_src = 2'd1;
	else if(reg_we_ma && rd_ma != 0 && rd_ma == rs1_id)
	  alu_a_src = 2'd2;
	else
	  alu_a_src = 2'd0;
	
	if(reg_we_ex && rd_ex != 0 && rd_ex == rs2_id)
	  alu_b_src = 2'd1;
	else if(reg_we_ma && rd_ma != 0 && rd_ma == rs2_id)
	  alu_b_src = 2'd2;
	else
	  alu_b_src = 2'd0;

	alu_a = alu_a_src == 2'd1 ? alu_result :
		alu_a_src == 2'd2 ? reg_wdata :
		alu_a_id;
	alu_b = alu_b_src == 2'd1 ? alu_result :
		alu_b_src == 2'd2 ? reg_wdata :
		alu_b_id;
    end

endmodule // data_forwarding
