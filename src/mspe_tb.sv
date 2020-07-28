module mspe_tb#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14, DEVICE="ARTIX7");

    logic clk;
    logic reset;

    logic [4:0]  csr_address;
    logic [31:0] csr_writedata;
    logic        csr_write;
    logic [31:0] csr_readdata;
    logic        csr_read;
    logic [3:0]  csr_byteenable;

     // to access DRAM with CSR
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

     // to access DRAM to read insn/data
    logic           m1_waitrequest;
    logic [512-1:0] m1_readdata;
    logic           m1_readdatavalid;
    logic [3-1:0]   m1_burstcount;
    logic [512-1:0] m1_writedata;
    logic [64-1:0]  m1_address;
    logic           m1_write;
    logic           m1_read;
    logic [63:0]    m1_byteenable;
    logic           m1_debugaccess;

    logic recv_fifo_rdreq;
    logic [511:0] recv_fifo_q;
    logic [10:0]  recv_fifo_rdusedw;
    logic recv_fifo_kick;
    logic recv_fifo_clear;
    logic [63:0] recv_fifo_counter;
     
    logic [511:0] src_data;
    logic src_valid;
    logic src_sop;
    logic src_eop;
    logic src_ready;
    logic send_fifo_clear;
    logic [63:0] send_fifo_counter;

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
		csr_address <= 0;
		csr_writedata <= 0;
		csr_write <= 0;
		csr_read <= 0;
		csr_byteenable <= 0;
		m0_waitrequest <= 0;
		m0_readdata <= 0;
		m0_readdatavalid <= 0;
		m1_waitrequest <= 0;
		m1_readdata <= 0;
		m1_readdatavalid <= 0;
		src_ready <= 0;
	    end

	    9: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    20: begin
		counter <= counter + 1;
		recv_fifo_q[511:480] <= 32;
		recv_fifo_q[479:448] <= 3;
		recv_fifo_rdusedw <= 64;
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
	if(m1_read == 1) begin
	    m1_readdatavalid <= 1;
	    m1_readdata <= {32'h0000006F, 32'h00000000, 32'h00000000, 32'h00000000,
                            32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                            32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                            32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000};
	end else begin
	    m1_readdatavalid <= 0;
	    m1_readdata <= 0;
	end

    end
    


    mspe#(.CORES(4), .INSN_DEPTH(12), .DMEM_DEPTH(14), .DEVICE("ARTIX7"))
    mspe_i(
	   .clk(clk),
	   .reset(reset),
	   
	   .csr_address(csr_address),
	   .csr_writedata(csr_writedata),
	   .csr_write(csr_write),
	   .csr_readdata(csr_readdata),
	   .csr_read(csr_read),
	   .csr_byteenable(csr_byteenable),
	   
	   // to access DRAM with CSR
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
	   
	   // to access DRAM to read insn/data
	   .m1_waitrequest(m1_waitrequest), 
	   .m1_readdata(m1_readdata),
	   .m1_readdatavalid(m1_readdatavalid),
	   .m1_burstcount(m1_burstcount),
	   .m1_writedata(m1_writedata),
	   .m1_address(m1_address),
	   .m1_write(m1_write),
	   .m1_read(m1_read),
	   .m1_byteenable(m1_byteenable),
	   .m1_debugaccess(m1_debugaccess),
	   
	   .recv_fifo_rdreq(recv_fifo_rdreq),
	   .recv_fifo_q(recv_fifo_q),
	   .recv_fifo_rdusedw(recv_fifo_rdusedw),
	   .recv_fifo_kick(recv_fifo_kick),
	   .recv_fifo_clear(recv_fifo_clear),
	   .recv_fifo_counter(recv_fifo_counter),
     
	   .src_data(src_data),
	   .src_valid(src_valid),
	   .src_sop(src_sop),
	   .src_eop(src_eop),
	   .src_ready(src_ready),
	   .src_clear(send_fifo_clear),
	   .src_counter(send_fifo_counter)
	   );

endmodule // mspe_tb
