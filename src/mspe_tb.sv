`default_nettype none

module mspe_tb#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14, DEVICE="ARTIX7");

    logic clk;
    logic reset;

     // to access DRAM to read insn/data
    logic           m0_waitrequest;
    logic [512-1:0] m0_readdata;
    logic           m0_readdatavalid;
    logic [3-1:0]   m0_burstcount;
    logic [512-1:0] m0_writedata;
    logic [64-1:0]  m0_address;
    logic           m0_write;
    logic           m0_read;
    logic [63:0]    m0_byteenable;
    logic           m0_debugaccess;

    logic recv_fifo_rdreq;
    logic [511:0] recv_fifo_q;
    logic [10:0]  recv_fifo_rdusedw;
    logic recv_fifo_valid;
     
    logic [511:0] src_data;
    logic src_valid;
    logic src_sop;
    logic src_eop;

    logic [CORES-1:0] core_status;

    initial begin
	clk = 0;
    end

    always begin
	clk = ~clk;
	#5;
    end

    logic [31:0] counter = 0;

    always @(posedge clk) begin

	case(counter)

	    0: begin
		counter <= counter + 1;
		reset <= 1;
		recv_fifo_q <= 512'd0;
		recv_fifo_rdusedw <= 0;
		recv_fifo_valid <= 0;
		m0_waitrequest <= 0;
		m0_readdata <= 0;
		m0_readdatavalid <= 0;
	    end

	    9: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    20: begin
		counter <= counter + 1;
		recv_fifo_q[31:0] <= 32;
		recv_fifo_q[63:32] <= 3;
		recv_fifo_rdusedw <= 64;
		recv_fifo_valid <= 1;
	    end
	    21: begin
		recv_fifo_q[479:448] <= 2;
	    end

	    default: begin
		counter <= counter + 1;
	    end

	endcase // case (counter)

	if(recv_fifo_rdreq == 1)begin
	    recv_fifo_rdusedw <= recv_fifo_rdusedw - 1;
	end
	if(m0_read == 1) begin
	    m0_readdatavalid <= 1;
	    m0_readdata <= {32'h0000006F, 32'h00000000, 32'h00000000, 32'h00000000,
                            32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                            32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                            32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
	end else begin
	    m0_readdatavalid <= 0;
	    m0_readdata <= 0;
	end

    end
    
    mspe#(.CORES(4), .INSN_DEPTH(12), .DMEM_DEPTH(14), .DEVICE("ARTIX7"))
    mspe_i(
	   .clk(clk),
	   .reset(reset),
	   
	   // to access DRAM to read insn/data
	   .m0_waitrequest(m0_waitrequest), 
	   .m0_readdata(m0_readdata),
	   .m0_readdatavalid(m0_readdatavalid),
	   .m0_burstcount(m0_burstcount),
	   .m0_writedata(m0_writedata),
	   .m0_address(m0_address),
	   .m0_write(m0_write),
	   .m0_read(m0_read),
	   .m0_byteenable(m0_byteenable),
	   .m0_debugaccess(m0_debugaccess),
	   
	   .recv_fifo_rdreq(recv_fifo_rdreq),
	   .recv_fifo_q(recv_fifo_q),
	   .recv_fifo_rdusedw(recv_fifo_rdusedw),
	   .recv_fifo_valid(recv_fifo_valid),
     
	   .src_data(src_data),
	   .src_valid(src_valid),
	   .src_sop(src_sop),
	   .src_eop(src_eop),
	   .src_ready(1'b1),

	   .core_status(core_status),
	   .all_core_reset(1'b0)
	   );

endmodule // mspe_tb

`default_nettype wire

