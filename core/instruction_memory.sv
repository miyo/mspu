`default_nettype none

module instruction_memory#(parameter DEPTH = 12)
  (
   input wire clk,
   input wire reset,

   input  wire [31:0] pc,
   output wire [31:0] insn,

   input wire [31:0] addr,
   input wire [31:0] din,
   input wire        we
   );

    logic [31:0] mem [2**DEPTH];
    reg [31:0] dout;

    assign insn = dout;

    always@(posedge clk) begin
	if(we) begin
	    mem[addr[DEPTH-1+2:2]] <= din;
	end
    end

    assign dout = mem[pc[DEPTH-1+2:2]];
    
endmodule // instruction_memory

`default_nettype wire


