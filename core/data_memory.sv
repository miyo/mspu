`default_nettype none

module data_memory#(parameter DEPTH = 12)
  (
   // system
   input wire clk,
   input wire reset,
   input wire run,
   /* verilator lint_off UNUSED */
   input wire stall,
   /* verilator lint_on UNUSED */

   /* verilator lint_off UNUSED */
   input wire [31:0] addr_b,
   /* verilator lint_on UNUSED */
   input wire [31:0]  din_b,
   input wire         we_b,
   input wire         oe_b,
   output logic [31:0] dout_b,
   // input
   input wire [31:0] addr,
   input wire [1:0]  bytes,
   input wire [31:0] wdata,
   input wire        we,
   /* verilator lint_off UNUSED */
   input wire        re,
   /* verilator lint_on UNUSED */
   input wire        mem_to_reg_in,
   input wire [31:0] alu_result,
   input wire [4:0]  rd_in,
   input wire        reg_we_in,
   input wire        unsigned_flag,
   // output
   output logic [31:0] reg_wdata,
   output logic        reg_we_out,
   output logic [4:0]  reg_rd,
   // peripheral
   output logic [31:0] uart_dout,
   output logic        uart_we
   );

    localparam UART_ADDR = 32'h1000_0000;

    logic [DEPTH-2-1:0] mem_raddr[3:0], mem_waddr[3:0];
    logic [31:0] mem_din, mem_dout;
    logic [3:0] mem_we, mem_oe;

    /* verilator lint_off PINCONNECTEMPTY */
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_0(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr[0]), .dout(mem_dout[7:0]), .oe(mem_oe[0]),
	    .waddress(mem_waddr[0]), .din(mem_din[7:0]), .we(mem_we[0]));
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_1(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr[1]), .dout(mem_dout[15:8]), .oe(mem_oe[1]),
	    .waddress(mem_waddr[1]), .din(mem_din[15:8]), .we(mem_we[1]));
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_2(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr[2]), .dout(mem_dout[23:16]), .oe(mem_oe[2]),
	    .waddress(mem_waddr[2]), .din(mem_din[23:16]), .we(mem_we[2]));
    simple_dualportram#(.WIDTH(8), .DEPTH(DEPTH-2))
    mem_i_3(.clk(clk), .reset(reset), .length(),
	    .raddress(mem_raddr[3]), .dout(mem_dout[31:24]), .oe(mem_oe[3]),
	    .waddress(mem_waddr[3]), .din(mem_din[31:24]), .we(mem_we[3]));
    /* verilator lint_on PINCONNECTEMPTY */

    logic [31:0] rd0, rd1, wd0, wd1;
    logic [3:0] we0, we1;

    logic [31:0] alu_result_r;
    logic mem_to_reg_in_r;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    reg_rd <= 0;
	    mem_to_reg_in_r <= 0;
	    alu_result_r <= 0;
	    reg_we_out <= 0;
	end else begin
    	    if(run)
    	      reg_we_out <= reg_we_in;
    	    else
    	      reg_we_out <= 1'b0;
    	    reg_rd <= rd_in;
	    mem_to_reg_in_r <= mem_to_reg_in;
	    alu_result_r <= alu_result;
	end
    end
    assign reg_wdata = ~mem_to_reg_in_r ? alu_result_r :
		       rd1;

    logic [23:0] L24 = 24'h000000;
    logic [23:0] H24 = 24'hFFFFFF;
    logic [23:0] pa0, pa1;

    always_comb begin
	if(oe_b == 1) begin
	    mem_raddr[3] = addr_b[DEPTH-1:2];
	    mem_raddr[2] = addr_b[DEPTH-1:2];
	    mem_raddr[1] = addr_b[DEPTH-1:2];
	    mem_raddr[0] = addr_b[DEPTH-1:2];
	end else begin
	    mem_raddr[3] = addr[DEPTH-1:2];
	    mem_raddr[2] = addr[DEPTH-1:2];
	    mem_raddr[1] = addr[DEPTH-1:2];
	    mem_raddr[0] = addr[DEPTH-1:2];
	end
	mem_oe = 4'b1111;
	dout_b = mem_dout;

	pa0 = unsigned_flag ? L24 : mem_dout[31] ? H24 : L24;

	if(addr == UART_ADDR) begin
	    rd0 = 32'h0;
	end else begin
	    case(addr[1:0])
		2'b00:   rd0 = mem_dout;
		2'b01:   rd0 = {pa0[ 7:0], mem_dout[31:8]};
		2'b10:   rd0 = {pa0[15:0], mem_dout[31:16]};
		2'b11:   rd0 = {pa0[23:0], mem_dout[31:24]};
		default: rd0 = mem_dout;
	    endcase // case (addr[1:0])
	end
	
	case(bytes)
	    2'b00: begin
		rd1 = rd0;
		pa1 = 0;
	    end
	    2'b01: begin
		pa1 = unsigned_flag ? L24 : rd0[7] ? H24 : L24;
		rd1 = {pa1[23:0], rd0[ 7: 0]};
	    end
	    2'b10: begin
		pa1 = unsigned_flag ? L24 : rd0[15] ? H24 : L24;
		rd1 = {pa1[15:0], rd0[15: 0]};
	    end
	    default: begin
		rd1 = rd0;
		pa1 = 0;
	    end
	endcase // case (bytes)
    end

    always_comb begin

	case(bytes)
	    2'b00: begin
		wd0 = wdata;
		we0 = 4'b1111;
	    end
	    2'b01: begin
		wd0 = {24'h0,wdata[7:0]};
		we0 = 4'b0001;
	    end
	    2'b10: begin
		wd0 = {16'h0,wdata[15:0]};
		we0 = 4'b0011;
	    end
	    default: begin
		wd0 = wdata;
		we0 = 4'b1111;
	    end
	endcase // case (bytes)

	case(addr[1:0])
	    2'b00: begin
		wd1 = wd0;
		we1 = we0;
	    end
	    2'b01: begin
		wd1 = {wd0[23:0], 8'h00};
		we1 = {we0[2:0], 1'b0};
	    end
	    2'b10: begin
		wd1 = {wd0[15:0], 16'h0000};
		we1 = {we0[1:0], 2'b00};
	    end
	    2'b11: begin
		wd1 = {wd0[7:0], 24'h000000};
		we1 = {we0[0], 3'b000};
	    end
	    default: begin
		wd1 = wd0;
		we1 = we0;
	    end
	endcase

    end

    always_comb begin
	if(we && addr != UART_ADDR) begin
	    mem_waddr[3] = addr[DEPTH-1:2];
	    mem_waddr[2] = addr[DEPTH-1:2];
	    mem_waddr[1] = addr[DEPTH-1:2];
	    mem_waddr[0] = addr[DEPTH-1:2];
	    mem_din = wd1;
	    mem_we = we1;
	end else if(we_b) begin
	    mem_waddr[3] = addr_b[DEPTH-1:2];
	    mem_waddr[2] = addr_b[DEPTH-1:2];
	    mem_waddr[1] = addr_b[DEPTH-1:2];
	    mem_waddr[0] = addr_b[DEPTH-1:2];
	    mem_din = din_b;
	    mem_we = 4'b1111;
	end else begin
	    mem_we = 4'b0000;
	    mem_waddr[3] = 0;
	    mem_waddr[2] = 0;
	    mem_waddr[1] = 0;
	    mem_waddr[0] = 0;
	    mem_din = 0;
	end
    end

    // Peripheral
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    uart_dout <= 0;
	    uart_we <= 0;
	end else begin
	    if(we == 1 && addr == UART_ADDR) begin
		uart_dout <= wd1;
		uart_we <= 1'b1;
	    end else begin
		uart_we <= 1'b0;
	    end
	end
    end

endmodule // data_memory

`default_nettype wire
