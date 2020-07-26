`default_nettype none

module datawidthconv_32_to_512
  (
   input wire clk,
   input wire reset,

   input wire src_req,

   output wire [31:0] data_addr,
   output wire        data_oe,
   input wire [31:0]  data_q,

   output wire src_sop,
   output wire src_eop,
   output wire src_valid,
   output wire [511:0] src_q
   );

    logic [4:0] mem_raddr, mem_waddr;
    logic mem_we;
    logic [511:0] mem_din, mem_dout;

    genvar i;
    generate // 16 * 32 * 4Bytes = 2048Bytes
	for(i = 0; i < 16; i = i + 1) begin : interface_memories
	    simple_dualportram#(.WIDTH(32), .DEPTH(5)) // 32 * 4Bytes
	    mem_i(.clk(clk), .reset(reset), .length(),
		  .raddress(mem_raddr), .dout(mem_dout[32*i+31:32*i]), .oe(1),
		  .waddress(mem_waddr), .din(mem_din[32*i+31:32*i]), .we(mem_we));
	end
    endgenerate

    logic src_req_d;
    logic [7:0] state_counter;
    logic [479:0] data_buf;
    logic [8:0] read_counter;
    logic [4:0] write_counter;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state_counter <= 0;
	    src_req_d <= 0;
	    data_addr <= 0;
	    mem_we <= 0;
	    data_oe <= 0;
	    read_counter <= 0;
	    write_counter <= 0;
	    mem_raddr <= 0;
	    src_valid <= 0;
	    src_sop <= 0;
	    src_eop <= 0;
	end else begin
	    src_req_d <= src_req;
	    case(state_counter)
		0: begin
		    if(src_req == 1 && src_req_d == 0) begin
			state_counter <= state_counter + 1;
			data_addr <= 0;
			data_oe <= 1;
		    end else begin
			data_oe <= 0;
		    end
		    mem_we <= 0;
		    mem_raddr <= 0;
		    read_counter <= 0;
		    write_counter <= 0;
		    src_valid <= 0;
		    src_sop <= 0;
		    src_eop <= 0;
		end
		1 : begin
		    state_counter <= state_counter + 1;
		    data_addr <= data_addr + 1;
		    data_oe <= 1;
		end
		2 : begin
		    data_addr <= data_addr + 1;
		    data_buf <= {data_buf[447:0], data_q};
		    read_counter <= read_counter + 1;
		    if(read_counter[3:0] == 15) begin
			mem_waddr <= read_counter[8:4];
			mem_we <= 1;
			if(read_counter == 511) begin
			    state_counter <= state_counter + 1;
			    mem_raddr <= mem_raddr + 1; // for next next
			    write_counter <= 0;
			end
		    end else begin
			mem_raddr <= 0;
			mem_we <= 0;
		    end
		end
		3: begin
		    mem_we <= 0;
		    src_q <= mem_dout;
		    src_valid <= 1;
		    write_counter <= write_counter + 1;
		    if(write_counter == 0) begin
			src_sop <= 1;
			src_eop <= 0;
		    end else if(write_counter == 31) begin
			src_sop <= 0;
			src_eop <= 1;
			state_counter <= 0;
		    end else begin
			src_sop <= 0;
			src_eop <= 0;
		    end
		end
	    endcase // case (state_counter)
	end
    end

endmodule // datawidthconv_32_to_512

`default_nettype wire

