`default_nettype none

module immgen(
	      input wire [31:0] d,
	      output wire [31:0] q
	      );

    assign q = d[31:0];

endmodule // immgen

`default_nettype wire
