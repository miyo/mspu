`default_nettype none

module sink_fifo#( parameter DEVICE="ARTIX7")
  (
   input wire wr_clk,
   input wire wr_rst,
   input wire rd_clk,
   input wire rd_rst,
   input wire [511:0] din,
   input wire we,
   input wire re,
   output wire [31:0] q,
   output wire [31:0] rd_count,
   output wire [31:0] wr_count,
   output wire empty,
   output wire full
   );

    wire [63:0] q64;
    wire valid64;

    generate
        if (DEVICE == "CYCLONEV") begin
            fifo_ft_512_64_to_32_1024
	      fifo_ft_512_64_to_32_1024_i(
		       .data(din),
		       .wrreq(we),
		       .rdreq(re),
		       .wrclk(wr_clk),
		       .rdclk(rd_clk),
		       .q(q), 
		       .rdusedw(rd_count),
		       .wrusedw(wr_count),
		       .rdempty(empty),
		       .wrfull(full)
		       );
        end else begin
	    fifo_ft_512_64_to_64_512
	      fifo_ft_512_64_to_64_512_i(
					 .rst(wr_rst),
					 .wr_clk(wr_clk),
					 .rd_clk(rd_clk),
					 .din(din),
					 .wr_en(we),
					 .rd_en(1'b1), // through
					 .dout(q64),
					 .valid(valid64),
					 .full(),
					 .empty(),
					 .rd_data_count(),
					 .wr_data_count(wr_count[6:0]),
					 .wr_rst_busy(),
					 .rd_rst_busy()
					 );
	    fifo_ft_64_512_to_32_1024
	      fifo_ft_64_512_to_32_1024_i(
					  .rst(wr_rst),
					  .wr_clk(wr_clk),
					  .rd_clk(rd_clk),
					  .din(q64),
					  .wr_en(valid64),
					  .rd_en(re),
					  .dout(q),
					  .full(),
					  .empty(),
					  .valid(),
					  .rd_data_count(rd_count[10:0]),
					  .wr_data_count(),
					  .wr_rst_busy(),
					  .rd_rst_busy()
					  );
	    assign wr_count[31:7] = 0;
	    assign rd_count[31:11] = 0;
	end
    endgenerate

endmodule // sink_fifo

`default_nettype wire
