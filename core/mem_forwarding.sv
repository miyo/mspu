module mem_forwarding
  (
   input wire [4:0] dmem_wdata_src_ex,
   input wire [4:0] reg_rd,
   
   input wire [31:0] reg_wdata,
   input wire [31:0] dmem_wdata_ex,
   
   output logic [31:0] dmem_wdata_to_mem
   );

    always_comb begin
	if(dmem_wdata_src_ex == 0) begin
	    dmem_wdata_to_mem = 0;
	end else if(dmem_wdata_src_ex == reg_rd) begin
	    dmem_wdata_to_mem = reg_wdata;
	end else begin
	    dmem_wdata_to_mem = dmem_wdata_ex;
	end
    end

endmodule // mem_forwarding
