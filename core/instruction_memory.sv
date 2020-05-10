`default_nettype none

module instruction_memory#(parameter DEPTH = 12)
  (
   input wire clk,
   input wire reset,

   /* verilator lint_off UNUSED */
   input  wire [31:0] pc,
   /* verilator lint_on UNUSED */
   output wire [31:0] insn,

   /* verilator lint_off UNUSED */
   input wire [31:0] addr,
   /* verilator lint_on UNUSED */
   input wire [31:0] din,
   input wire        we
   );

    logic [DEPTH-2-1:0] mem_raddr, mem_waddr;
    logic [31:0] mem_din, mem_dout;
    logic [3:0] mem_we, mem_oe;

    /* verilator lint_off PINCONNECTEMPTY */
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_0(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr), .dout(mem_dout[7:0]), .oe(mem_oe[0]),
	    .waddress(mem_waddr), .din(mem_din[7:0]), .we(mem_we[0]));
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_1(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr), .dout(mem_dout[15:8]), .oe(mem_oe[1]),
	    .waddress(mem_waddr), .din(mem_din[15:8]), .we(mem_we[1]));
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_2(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr), .dout(mem_dout[23:16]), .oe(mem_oe[2]),
	    .waddress(mem_waddr), .din(mem_din[23:16]), .we(mem_we[2]));
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_3(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr), .dout(mem_dout[31:24]), .oe(mem_oe[3]),
	    .waddress(mem_waddr), .din(mem_din[31:24]), .we(mem_we[3]));
    /* verilator lint_on PINCONNECTEMPTY */

    always_comb begin
	mem_waddr = addr[DEPTH-1:2];
	mem_din = din;
	mem_we = {we, we, we, we};
    end

    always_comb begin
	mem_raddr = pc[DEPTH-1:2];
	insn = mem_dout;
	mem_oe = 4'b1111;
    end
    
endmodule // instruction_memory

`default_nettype wire


