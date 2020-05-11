module dummy_top_tb();

    logic clk;
    logic reset = 1'b1;
    logic uart_tx;

    initial begin
	clk <= 1'b0;
    end

    always 
      #5  clk = ~clk;

    logic [7:0] counter = 8'd0;
    always_ff @(posedge clk) begin
	counter <= counter + 1;
	if(counter == 20)
	  reset <= 1'b0;
    end


    dummy_top dummy_top_i(.clk(clk),
			  .reset(reset),
			  .uart_tx(uart_tx)
			  );

endmodule // dummy_top
