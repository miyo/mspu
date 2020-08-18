`default_nettype none

module datawidthconv_512_to_32
  (
   input wire clk,
   input wire reset,

   input wire snk_sop,
   input wire snk_eop,
   input wire snk_valid,
   input wire [511:0] snk_din,

   output logic [31:0] data_addr,
   output logic [31:0] data_din,
   output logic        data_we
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

    logic [4:0] write_counter;
    logic snk_eop_flag;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    write_counter <= 0;
	    mem_waddr <= 0;
	    mem_we <= 0;
	    snk_eop_flag <= 0;
	end else begin
	    mem_din <= snk_din;
	    mem_we <= snk_valid;
	    snk_eop_flag <= snk_eop & snk_valid;
	    if(snk_valid == 1 && snk_sop == 1) begin
		mem_waddr <= 0;
		write_counter <= 1;
	    end else if(snk_valid == 1) begin
		mem_waddr <= write_counter;
		write_counter <= write_counter + 1;
	    end
	end
    end
    
    logic [15:0] state_counter;
    logic snk_eop_flag_d;
    logic [511:0] ifmem_buf;
    logic [15:0] ifmem_write_counter;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state_counter <= 0;
	    snk_eop_flag_d <= 0;
	    mem_raddr <= 0;
	    data_we <= 0;
	    data_addr <= 0;
	    data_din <= 0;
	    ifmem_write_counter <= 0;
	end else begin
	    snk_eop_flag_d <= snk_eop_flag;
	    case(state_counter)
		0: begin
		    if(snk_eop_flag == 1 && snk_eop_flag_d == 0) begin
			state_counter <= state_counter + 1;
			mem_raddr <= 0;
		    end
		    data_we <= 0;
		    ifmem_write_counter <= 0;
		end
		1 : begin
		    state_counter <= state_counter + 1;
		end
		2 : begin
		    mem_raddr <= mem_raddr + 1;
		    ifmem_buf[511:0] <= {32'h, mem_dout[511:32]};
		    data_we <= 1;
		    data_din <= mem_dout[31:0];
		    data_addr <= {14'd0, ifmem_write_counter, 2'b00};
		    ifmem_write_counter <= ifmem_write_counter + 1;
		    state_counter <= state_counter + 1;
		end
		3: begin
		    ifmem_buf[511:0] <= {32'h, ifmem_buf[511:32]};
		    data_we <= 1;
		    data_din <= ifmem_buf[31:0];
		    data_addr <= {14'd0, ifmem_write_counter, 2'b00};
		    if(ifmem_write_counter[3:0] == 15) begin
			if(ifmem_write_counter == 511) begin
			    state_counter <= 0;
			end else begin
			    state_counter <= 2;
			end
		    end
		    ifmem_write_counter <= ifmem_write_counter + 1;
		end
	    endcase // case (state_counter)
	end
    end

endmodule // datawidthconv_512_to_32

`default_nettype wire

