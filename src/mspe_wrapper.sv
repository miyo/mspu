`default_nettype none

module mspe_wrapper#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14)
    (
     input wire clk,
     input wire reset,

     input wire [4:0]    csr_address,
     input wire [31:0]   csr_writedata,
     input wire          csr_write,
     output logic [31:0] csr_readdata,
     input wire          csr_read,
     input wire [3:0]    csr_byteenable,

     // to access DRAM with CSR
     input  wire           m0_waitrequest, 
     input  wire [512-1:0] m0_readdata,
     input  wire           m0_readdatavalid,
     output wire [3-1:0]   m0_burstcount,
     output wire [512-1:0] m0_writedata,
     output wire [64-1:0]  m0_address,
     output wire           m0_write,
     output wire           m0_read,
     output wire [63:0]    m0_byteenable,

     // to access DRAM to read insn/data
     input  wire           m1_waitrequest, 
     input  wire [512-1:0] m1_readdata,
     input  wire           m1_readdatavalid,
     output wire [3-1:0]   m1_burstcount,
     output wire [512-1:0] m1_writedata,
     output wire [64-1:0]  m1_address,
     output wire           m1_write,
     output wire           m1_read,
     output wire [63:0]    m1_byteenable,

     // data input
     input  wire           m2_waitrequest, 
     input  wire [512-1:0] m2_readdata,
     input  wire           m2_readdatavalid,
     output logic [3-1:0]   m2_burstcount,
     output logic [512-1:0] m2_writedata,
     output logic [64-1:0]  m2_address,
     output logic           m2_write,
     output logic           m2_read,
     output logic [63:0]    m2_byteenable,

     // data output
     input  wire           m3_waitrequest, 
     input  wire [512-1:0] m3_readdata,
     input  wire           m3_readdatavalid,
     output logic [3-1:0]   m3_burstcount,
     output logic [512-1:0] m3_writedata,
     output logic [64-1:0]  m3_address,
     output logic           m3_write,
     output logic           m3_read,
     output logic [63:0]    m3_byteenable
     );

    logic recv_fifo_rdreq;
    logic [511:0] recv_fifo_q;
    logic [10:0] recv_fifo_rdusedw;
     
    logic [511:0] src_data;
    logic src_valid;
    logic src_sop;
    logic src_eop;
    logic src_ready;

    logic [511:0] recv_fifo_din;
    logic recv_fifo_wrreq;
    logic recv_fifo_full;
    logic recv_fifo_kick;
    logic recv_fifo_clear;
    logic [63:0] recv_fifo_counter;

    logic send_fifo_rdreq;
    logic send_fifo_clear;
    logic [511:0] send_fifo_q;
    logic send_fifo_empty;
    logic [63:0] send_fifo_counter;

    mspe#(.CORES(CORES), .INSN_DEPTH(INSN_DEPTH), .DMEM_DEPTH(DMEM_DEPTH), .DEVICE("CYCLONEV"))
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
	   .m0_debugaccess(),
	   
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
	   .m1_debugaccess(),
	   
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

    fifo_ft_512_256 fifo_ft_512_256_recv(
				       .data(recv_fifo_din),
				       .wrreq(recv_fifo_wrreq),
				       .rdreq(recv_fifo_rdreq),
				       .clock(clk),
				       .sclr(recv_fifo_clear | reset),
				       .q(recv_fifo_q), 
				       .usedw(recv_fifo_rdusedw),
				       .empty(),
				       .full(),
				       .almost_full(recv_fifo_full)
				       );
    
    fifo_ft_512_256 fifo_ft_512_256_send(
				       .data(src_data),
				       .wrreq(src_valid),
				       .rdreq(send_fifo_rdreq),
				       .clock(clk),
				       .sclr(send_fifo_clear | reset),
				       .q(send_fifo_q), 
				       .usedw(),
				       .empty(send_fifo_empty),
				       .full(),
				       .almost_full(src_ready)
				       );

    always_ff @(posedge clk) begin
	if(reset | recv_fifo_clear) begin
	    m2_burstcount <= 1;
	    m2_writedata <= 0;
	    m2_address <= 0;
	    m2_write <= 0;
	    m2_read <= 0;
	    m2_byteenable <= 0;
	    recv_fifo_counter <= 0;
	end else begin
	    if(recv_fifo_kick == 1) begin
		if(recv_fifo_full == 0) begin
		    m2_read <= 1;
		    m2_address <= recv_fifo_counter;
		    recv_fifo_counter <= recv_fifo_counter + 1;
		end else begin
		    m2_read <= 0;
		end
		recv_fifo_wrreq <= m2_readdatavalid;
		recv_fifo_din <= m2_readdata;
	    end else begin
		m2_read <= 0;
		recv_fifo_wrreq <= 0;
	    end
	end
    end

    always_ff @(posedge clk) begin
	if(reset | send_fifo_clear) begin
	    m3_burstcount <= 1;
	    m3_writedata <= 0;
	    m3_address <= 0;
	    m3_write <= 0;
	    m3_read <= 0;
	    m3_byteenable <= 64'hFFFFFFFF_FFFFFFFF;
	    send_fifo_counter <= 0;
	end else begin
	    if(send_fifo_empty == 0) begin
		m3_address <= send_fifo_counter;
		m3_write <= 1;
		m3_writedata <= send_fifo_q;
	    end else begin
		m3_write <= 0;
	    end
	    if(m3_waitrequest | m3_write) begin
		send_fifo_rdreq <= 1;
		send_fifo_counter <= send_fifo_counter + 1;
	    end else begin
		send_fifo_rdreq <= 0;
	    end
	end
    end

endmodule // mspe_wrapper

`default_nettype wire
