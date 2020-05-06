`default_nettype none

module data_memory#(parameter DEPTH = 12)
  (
   input wire clk,
   input wire reset,

   input wire [31:0]  addr,
   input wire [1:0]   bytes,
   input wire [31:0]  wdata,
   input wire         we,
   input wire         re,
   output wire [31:0] rdata,

   input wire [31:0]  addr_b,
   input wire [31:0]  din_b,
   input wire         we_b,

   output wire [31:0] uart_dout,
   output wire        uart_we
   );

    localparam UART_ADDR = 32'h1000_0000;

    //(* ram_style = "block" *) logic [31:0] mem [2**DEPTH];
    logic [31:0] mem [2**DEPTH];
    reg [31:0] dout;

    assign rdata = dout;
    
    logic [31:0] rd0, rd1, rd2, wd0, wd1, wd2, wm0, wm1;
    always_comb begin

	if(addr == UART_ADDR) begin
	    rd0 = 32'h0;
	end else begin
	    rd0 = mem[addr[DEPTH-1+2:2]];
	end

	case(addr[1:0])
	    2'b00:   rd1 = rd0;
	    2'b01:   rd1 = { 8'h0, rd0[31: 8]};
	    2'b10:   rd1 = {16'h0, rd0[31:16]};
	    2'b11:   rd1 = {24'h0, rd0[31:24]};
	    default: rd1 = rd0;
	endcase // case (addr[1:0])
	
	case(bytes)
	    2'b00:   rd2 = rd1;
	    2'b01:   rd2 = {24'h0, rd1[ 7: 0]};
	    2'b10:   rd2 = {16'h0, rd1[15: 0]};
	    default: rd2 = rd1;
	endcase // case (bytes)

	case(bytes)
	    2'b00: begin
		wd0 = wdata;
		wm0 = 32'h00000000;
	    end
	    2'b01: begin
		wd0 = {24'h0,wdata[7:0]};
		wm0 = 32'hFFFFFF00;
	    end
	    2'b10: begin
		wd0 = {16'h0,wdata[15:0]};
		wm0 = 32'hFFFF0000;
	    end
	    default: begin
		wd0 = wdata;
		wm0 = 32'h00000000;
	    end
	endcase // case (bytes)

	case(addr[1:0])
	    2'b00: begin
		wd1 = wd0;
		wm1 = wm0;
	    end
	    2'b01: begin
		wd1 = {wd0[23:0], 8'h00};
		wm1 = {wm0[23:0], 8'hFF};
	    end
	    2'b10: begin
		wd1 = {wd0[15:0], 16'h0000};
		wm1 = {wm0[15:0], 16'hFFFF};
	    end
	    2'b11: begin
		wd1 = {wd0[7:0], 24'h000000};
		wm1 = {wm0[7:0], 24'hFFFFFF};
	    end
	    default: begin
		wd1 = wd0;
		wm1 = wm0;
	    end
	endcase

	wd2 = (rd0 & wm1) | wd1;
    end

    assign dout = rd2;

    always @(posedge clk) begin
	if(we && addr != UART_ADDR) begin
	    mem[addr[DEPTH-1+2:2]] <= wd2;
	end
	if(we_b) begin
	    mem[addr_b[DEPTH-1+2:2]] <= din_b;
	end
    end

    // Peripheral
    always_ff @(posedge clk) begin
	if(we == 1 && addr == UART_ADDR) begin
	    uart_dout <= wd2;
	    uart_we <= 1'b1;
	end else begin
	    uart_we <= 1'b0;
	end
    end

endmodule // data_memory

`default_nettype wire
