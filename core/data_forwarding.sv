module data_forwarding
  (
   input logic clk,
   input logic reset,

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

   input logic dmem_we,
   input logic dmem_re,

   output logic [31:0] alu_a,
   output logic [31:0] alu_b
   );


    logic [3:0] dmem_we_d;
    logic [1:0] dmem_re_d;
    logic [31:0] dmem_waddr_d;
    logic [31:0] dmem_wdata_d;
    logic [31:0] alu_a_d;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    dmem_waddr_d <= 0;
	    dmem_wdata_d <= 0;
	end else begin
	    dmem_we_d <= {dmem_we_d[2:0], dmem_we};
	    dmem_re_d <= {dmem_re_d[0:0], dmem_re};
	    if(dmem_we) begin
		dmem_waddr_d <= alu_a;
		dmem_wdata_d <= alu_result;
	    end
	    alu_a_d <= alu_a;
	end
    end
    logic [31:0] reg_wdata_i;
    always_comb begin
	if(dmem_we_d[2] == 1 && dmem_re_d[1] == 1 && alu_a_d == dmem_waddr_d) begin
	    reg_wdata_i = reg_wdata;
	end else if(dmem_we_d[3] == 1 && dmem_re_d[1] == 1 && alu_a_d == dmem_waddr_d) begin
	    reg_wdata_i = dmem_wdata_d;
	end else begin
	    reg_wdata_i = reg_wdata;
	end
    end


    /* verilator lint_off UNUSED */
    logic [1:0] alu_a_src, alu_b_src;
    logic [31:0] reg_wdata_d;
    logic reg_we_ma_d;
    logic [4:0] rd_ma_d;
    /* verilator lint_on UNUSED */

    always_comb begin
	if(reg_we_ex && rd_ex != 0 && rd_ex == rs1_id)
	  alu_a_src = 2'd1;
	else if(reg_we_ma && rd_ma != 0 && rd_ma == rs1_id)
	  alu_a_src = 2'd2;
	else if(reg_we_ma_d && rd_ma_d != 0 && rd_ma_d == rs1_id)
	  alu_a_src = 2'd3;
	else
	  alu_a_src = 2'd0;
	
	if(reg_we_ex && rd_ex != 0 && rd_ex == rs2_id)
	  alu_b_src = 2'd1;
	else if(reg_we_ma && rd_ma != 0 && rd_ma == rs2_id)
	  alu_b_src = 2'd2;
	else if(reg_we_ma_d && rd_ma_d != 0 && rd_ma_d == rs2_id)
	  alu_b_src = 2'd3;
	else
	  alu_b_src = 2'd0;

	alu_a = alu_a_src == 2'd1 ? alu_result :
		alu_a_src == 2'd2 ? reg_wdata_i :
		alu_a_src == 2'd3 ? reg_wdata_d :
		alu_a_id;
	alu_b = alu_b_src == 2'd1 ? alu_result :
		alu_b_src == 2'd2 ? reg_wdata_i :
		alu_b_src == 2'd3 ? reg_wdata_d :
		alu_b_id;
    end

    always_ff @(posedge clk) begin
	reg_wdata_d <= reg_wdata_i;
	reg_we_ma_d <= reg_we_ma;
	rd_ma_d <= rd_ma;
    end

endmodule // data_forwarding
