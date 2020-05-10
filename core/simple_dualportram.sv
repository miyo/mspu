module simple_dualportram #( parameter WIDTH = 32, DEPTH = 10 )
   (
    input wire 		    clk,
    /* verilator lint_off UNUSED */
    input wire 		    reset,
    /* verilator lint_on UNUSED */
    output wire [31:0] 	    length,
    input wire  [DEPTH-1:0] raddress,
    input wire  [DEPTH-1:0] waddress,
    input wire  [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout,
    input wire 		    we,
    /* verilator lint_off UNUSED */
    input wire 		    oe
    /* verilator lint_on UNUSED */
    );

    assign length = 2**DEPTH;

`define BRAM

`ifdef BRAM
    (* ram_style = "block" *) reg [WIDTH-1:0] mem [2**DEPTH-1:0];
`else
    reg [WIDTH-1:0] mem [2**DEPTH-1:0];
`endif

    logic [WIDTH-1:0] dout_r;
    assign dout = dout_r;
    
    always@(posedge clk) begin
	if(we) begin
	    mem[waddress[DEPTH-1:0]] <= din;
	end
    end

`ifdef BRAM
    always@(posedge clk) begin
	dout_r <= mem[raddress[DEPTH-1:0]];
    end
`else
    assign dout_r = mem[raddress[DEPTH-1:0]];
`endif
    
endmodule // simple_dualportram

