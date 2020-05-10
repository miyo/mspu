`default_nettype none

module registers
  (
   input wire clk,
   input wire reset,
   input wire run,

   input  wire [4:0]  raddr_a,
   input  wire [4:0]  raddr_b,
   output logic [31:0] rdata_a,
   output logic [31:0] rdata_b,
   
   input wire [4:0]  waddr,
   input wire [31:0] wdata,
   input wire reg_we
   );

    logic [31:0] mem [31:0];

    always_comb begin
	rdata_a = mem[raddr_a];
	rdata_b = mem[raddr_b];
    end

    always @(posedge clk) begin
	if(reset == 0 && run == 1) begin
	    if((reg_we == 1) && (waddr != 0)) begin
		mem[waddr] <= wdata;
	    end
	end
    end

endmodule // registers

`default_nettype wire


