module fifo_ft_512_256#(DEVICE="ARTIX7")(
		       input wire [511:0] data,
		       input wire wrreq,
		       input wire rdreq,
		       input wire clock,
		       input wire sclr,
		       output wire [511:0] q,
		       output wire [10:0] usedw,
		       output wire empty,
		       output wire full,
		       output almost_full
		       );

endmodule // fifo_ft_512_256
