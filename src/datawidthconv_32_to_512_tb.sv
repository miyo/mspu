`default_nettype none

module datawidthconv_32_to_512_tb;

    
    logic clk;
    logic reset;
    logic src_req;
    logic [31:0] data_addr;
    logic data_oe;
    logic [31:0] data_q = 0;
    logic src_sop;
    logic src_eop;
    logic src_valid;
    logic [511:0] src_q;

    initial begin
	clk = 0;
    end

    always begin
	clk = ~clk;
	#5;
    end

    logic [31:0] counter = 0;

    always_ff @(posedge clk) begin
	data_q <= data_q + 1;
	case(counter)
	    0: begin
		counter <= counter + 1;
		reset <= 1;
		src_req <= 0;
	    end

	    10: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    11: begin
		counter <= counter + 1;
		src_req <= 1;
	    end
	    
	    12: begin
		if(src_eop == 1) begin
		    counter <= counter + 1;
		end
	    end

	    20: begin
		$finish;
	    end

	    default: begin
		counter <= counter + 1;
	    end
	endcase // case (counter)
    end


    datawidthconv_32_to_512 datawidthconv_32_to_512_i
      (
       .clk(clk),
       .reset(reset),
       .src_req(src_req),
       .data_addr(data_addr),
       .data_oe(data_oe),
       .data_q(data_q),
       .src_sop(src_sop),
       .src_eop(src_eop),
       .src_valid(src_valid),
       .src_q(src_q));

endmodule // datawidthconv_32_to_512_tb

`default_nettype wire
