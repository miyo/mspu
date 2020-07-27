`default_nettype none

module datawidthconv_512_to_32_tb;

    
    logic clk;
    logic reset;

    logic snk_sop;
    logic snk_eop;
    logic snk_valid;
    logic [511:0] snk_din;
    logic [31:0] data_addr;
    logic [31:0] data_din;
    logic data_we;

    initial begin
	clk = 0;
    end

    always begin
	clk = ~clk;
	#5;
    end

    logic [31:0] counter = 0;
    logic [31:0] data = 0;

    always_ff @(posedge clk) begin
	data <= data + 1;
	snk_din <= {data+32'h00000000, data+32'h10000000, data+32'h20000000, data+32'h30000000,
                    data+32'h40000000, data+32'h50000000, data+32'h60000000, data+32'h70000000,
                    data+32'h80000000, data+32'h90000000, data+32'hA0000000, data+32'hB0000000,
                    data+32'hC0000000, data+32'hD0000000, data+32'hE0000000, data+32'hF0000000};
	case(counter)
	    0: begin
		counter <= counter + 1;
		reset <= 1;
		snk_sop <= 0;
		snk_eop <= 0;
		snk_valid <= 0;
	    end

	    9: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    10: begin
		counter <= counter + 1;
		snk_sop <= 1;
		snk_valid <= 1;
	    end
	    
	    11: begin
		counter <= counter + 1;
		snk_sop <= 0;
	    end

	    41: begin
		counter <= counter + 1;
		snk_eop <= 1;
	    end

	    42: begin
		counter <= counter + 1;
		snk_eop <= 0;
		snk_valid <= 0;
	    end

	    43: begin
		if(data_we == 1)
		  counter <= counter + 1;
	    end

	    44: begin
		if(data_we == 0)
		  counter <= counter + 1;
	    end

	    50: begin
		$finish;
	    end

	    default: begin
		counter <= counter + 1;
	    end
	endcase // case (counter)
    end

    datawidthconv_512_to_32 datawidthconv_512_to_32_i(.clk(clk),
						      .reset(reset),
						      .snk_sop(snk_sop),
						      .snk_eop(snk_eop),
						      .snk_valid(snk_valid),
						      .snk_din(snk_din),
						      .data_addr(data_addr),
						      .data_din(data_din),
						      .data_we(data_we));

endmodule // datawidthconv_32_to_512_tb

`default_nettype wire
