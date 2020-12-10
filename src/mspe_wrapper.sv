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
    logic recv_fifo_empty;
     
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
    logic recv_fifo_valid;

    logic send_fifo_rdreq;
    logic send_fifo_clear;
    logic [511:0] send_fifo_q;
    logic [10:0] send_fifo_usedw;
    logic send_fifo_empty;
    logic [63:0] send_fifo_counter;
    logic send_fifo_wrreq;
    logic [511:0] send_fifo_data;
    logic send_fifo_valid;
    logic send_fifo_almost_empty;

    logic [CORES-1:0] core_status;
    logic all_core_reset;

    logic [63:0] data_count;
    logic [63:0] src_addr_offset;
    logic [63:0] dst_addr_offset;

    mspe#(.CORES(CORES), .INSN_DEPTH(INSN_DEPTH), .DMEM_DEPTH(DMEM_DEPTH), .DEVICE("CYCLONEV"))
    mspe_i(
	   .clk(clk),
	   .reset(reset),

	   // to access DRAM to read insn/data
	   .m0_waitrequest(m1_waitrequest), 
	   .m0_readdata(m1_readdata),
	   .m0_readdatavalid(m1_readdatavalid),
	   .m0_burstcount(m1_burstcount),
	   .m0_writedata(m1_writedata),
	   .m0_address(m1_address),
	   .m0_write(m1_write),
	   .m0_read(m1_read),
	   .m0_byteenable(m1_byteenable),
	   .m0_debugaccess(),
	   
	   .recv_fifo_rdreq(recv_fifo_rdreq),
	   .recv_fifo_q(recv_fifo_q),
	   .recv_fifo_rdusedw(recv_fifo_rdusedw),
	   .recv_fifo_valid(recv_fifo_valid),
	   
	   .src_data(src_data),
	   .src_valid(src_valid),
	   .src_sop(src_sop),
	   .src_eop(src_eop),
	   .src_ready(src_ready),

	   .core_status(core_status),
	   .all_core_reset(all_core_reset)
	   );
    assign send_fifo_wrreq = src_valid;
    assign send_fifo_data = src_data;

    /////////////////////////////////////////////////////////////////
    // for pass-through
    /////////////////////////////////////////////////////////////////
    //assign recv_fifo_rdreq = recv_fifo_valid;
    //assign send_fifo_wrreq = recv_fifo_valid;
    //assign send_fifo_data = recv_fifo_q;
    /////////////////////////////////////////////////////////////////

    fifo_ft_512_256 fifo_ft_512_256_recv(
					 .data(recv_fifo_din),
					 .wrreq(recv_fifo_wrreq),
					 .rdreq(recv_fifo_rdreq),
					 .clock(clk),
					 .sclr(recv_fifo_clear | reset),
					 .q(recv_fifo_q), 
					 .usedw(recv_fifo_rdusedw),
					 .empty(recv_fifo_empty),
					 .full(),
					 .almost_full(recv_fifo_full)
					 );
    assign recv_fifo_valid = (recv_fifo_rdusedw > 0) && (recv_fifo_empty == 0);
    
    fifo_ft_512_256 fifo_ft_512_256_send(
					 .data(send_fifo_data),
					 .wrreq(send_fifo_wrreq),
					 .rdreq(send_fifo_rdreq),
					 .clock(clk),
					 .sclr(send_fifo_clear | reset),
					 .q(send_fifo_q), 
					 .usedw(send_fifo_usedw),
					 .empty(send_fifo_empty),
					 .full(),
					 .almost_full(src_ready)
					 );
    assign send_fifo_valid = (send_fifo_usedw > 0) && (send_fifo_empty == 0);
    assign send_fifo_almost_empty = (send_fifo_usedw == 1) && (send_fifo_wrreq == 0) && (send_fifo_rdreq == 1);

    ////////////////////////////////////////////////////////////////////////
    // DRAM -> FIFO
    ////////////////////////////////////////////////////////////////////////
    always_ff @(posedge clk) begin
	if(reset | recv_fifo_clear) begin
	    m2_burstcount <= 1;
	    m2_writedata <= 0;
	    m2_address <= 0;
	    m2_write <= 0;
	    m2_read <= 0;
	    m2_byteenable <= 64'hFFFFFFFF_FFFFFFFF;
	    recv_fifo_counter <= 0;
	end else begin

	    if((m2_waitrequest == 1) && (m2_read == 1)) begin
		// signal should be kept
	    end else begin
		if(recv_fifo_kick == 1 && recv_fifo_counter < data_count) begin
		    if(recv_fifo_full == 0) begin
			m2_read <= 1;
			m2_address <= src_addr_offset + {recv_fifo_counter[57:0], 6'b000000}; // byte-addressable
			recv_fifo_counter <= recv_fifo_counter + 1;
		    end else begin
			m2_read <= 0;
		    end
		end else begin
		    m2_read <= 0;
		end
	    end

	    recv_fifo_wrreq <= m2_readdatavalid;
	    recv_fifo_din <= m2_readdata;
	end
    end

    ////////////////////////////////////////////////////////////////////////
    // FIFO->DRAM
    ////////////////////////////////////////////////////////////////////////
    logic [511:0] send_fifo_q_d;
    logic m3_waitrequest_d;
    always_ff @(posedge clk) begin
	if(reset | send_fifo_clear) begin
	    m3_burstcount <= 1;
	    m3_address <= 0;
	    m3_write <= 0;
	    m3_read <= 0;
	    m3_byteenable <= 64'hFFFFFFFF_FFFFFFFF;
	    send_fifo_counter <= 0;
	    m3_waitrequest_d <= 1;
	end else begin
	    m3_waitrequest_d <= m3_waitrequest;
	    if((m3_waitrequest == 1) && (m3_write == 1)) begin
		// signal should be kept
		send_fifo_rdreq <= 0;
	    end else begin
		if((send_fifo_valid == 1) && (send_fifo_almost_empty == 0)) begin
		    m3_address <= dst_addr_offset + {send_fifo_counter[57:0], 6'b000000}; // byte-addressable
		    m3_write <= 1;
		    send_fifo_rdreq <= 1;
		    send_fifo_counter <= send_fifo_counter + 1;
		    send_fifo_q_d <= send_fifo_q;
		end else begin
		    m3_write <= 0;
		    send_fifo_rdreq <= 0;
		end
	    end
	end
    end
    always_comb begin
	if(m3_waitrequest_d == 1) begin
	    m3_writedata = send_fifo_q_d;
	end else begin
	    m3_writedata = send_fifo_q;
	end
    end
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Ctrl/Status interface
    ////////////////////////////////////////////////////////////////////////
    localparam VERSION = 32'h3434_0005;

    logic [512-1:0] m0_readdata_reg;

    logic [3-1:0] csr_burstcount_reg;
    logic [512-1:0] csr_writedata_reg;
    logic [64-1:0]  csr_address_reg;
    logic csr_write_reg;
    logic csr_read_reg;
    logic [63:0] csr_byteenable_reg;
    logic csr_debugaccess_reg;
    
    //assign m0_burstcount  = csr_burstcount_reg;
    //assign m0_writedata   = csr_writedata_reg;
    //assign m0_address     = csr_address_reg;
    //assign m0_write       = csr_write_reg;
    //assign m0_read        = csr_read_reg;
    //assign m0_byteenable  = csr_byteenable_reg;

    assign m0_burstcount  = 0;
    assign m0_writedata   = 0;
    assign m0_address     = 0;
    assign m0_write       = 0;
    assign m0_read        = 0;
    assign m0_byteenable  = 0;

    logic csr_write_kick;
    logic csr_write_kick_d;
    logic csr_read_kick;
    logic csr_read_kick_d;

    always_ff @(posedge clk) begin
	if (reset == 1) begin
	    csr_burstcount_reg  <= 1;
	    csr_writedata_reg   <= 0;
	    csr_address_reg     <= 0;
	    csr_write_reg       <= 0;
	    csr_read_reg        <= 0;
	    csr_byteenable_reg  <= 64'hFFFFFFFFFFFFFFFF;
	    csr_debugaccess_reg <= 0;
	    csr_write_kick      <= 0;
	    csr_read_kick       <= 0;
	    csr_write_kick_d    <= 0;
	    csr_read_kick_d     <= 0;
	    recv_fifo_kick      <= 0;
	    recv_fifo_clear     <= 0;
	    send_fifo_clear     <= 0;
	    all_core_reset      <= 0;
	    data_count          <= 0;
	    src_addr_offset     <= 0;
	    dst_addr_offset     <= 0;
	end else begin
	    csr_write_kick_d <= csr_write_kick;
	    if(csr_write_kick == 1 && csr_write_kick_d == 0)
	      csr_write_reg <= 1;
	    else if(csr_write_reg == 1 && m0_waitrequest == 0)
	      csr_write_reg <= 0;

	    csr_read_kick_d  <= csr_read_kick;
	    if(csr_read_kick == 1 && csr_read_kick_d == 0)
	      csr_read_reg  <= 1;
	    else if(csr_read_reg == 1 && m0_waitrequest == 0)
	      csr_read_reg  <= 0;

	    if(csr_write == 1)begin
		case (csr_address)
		    //5'd0: VERSION
		    5'd1:begin
			all_core_reset  <= csr_writedata[3];
			recv_fifo_kick  <= csr_writedata[2];
			recv_fifo_clear <= csr_writedata[1];
			send_fifo_clear <= csr_writedata[0];
		    end
		    //5'd2: core_status;
		    //5'd3: recv_fifo_counter[63:32];
		    //5'd4: recv_fifo_counter[31:0];
		    //5'd5: send_fifo_counter[63:32];
		    //5'd6: send_fifo_counter[31:0];
		    5'd7: data_count[63:32] <= csr_writedata;
		    5'd8: data_count[31:0]  <= csr_writedata;
		    5'd9:  src_addr_offset[63:32] <= csr_writedata;
		    5'd10: src_addr_offset[31:0]  <= csr_writedata;
		    5'd11:  dst_addr_offset[63:32] <= csr_writedata;
		    5'd12: dst_addr_offset[31:0]  <= csr_writedata;

		    // 5'd13: begin
		    // 	csr_read_kick  <= csr_writedata[1];
		    // 	csr_write_kick <= csr_writedata[0];
		    // end
		    // 5'd14: csr_address_reg[63:32] <= csr_writedata;
		    // 5'd15: csr_address_reg[31: 0] <= csr_writedata;
		    // 5'd16: csr_writedata_reg[511:480] <= csr_writedata;
		    // 5'd17: csr_writedata_reg[479:448] <= csr_writedata;
		    // 5'd18: csr_writedata_reg[447:416] <= csr_writedata;
		    // 5'd19: csr_writedata_reg[415:384] <= csr_writedata;
		    // 5'd20: csr_writedata_reg[383:352] <= csr_writedata;
		    // 5'd21: csr_writedata_reg[351:320] <= csr_writedata;
		    // 5'd22: csr_writedata_reg[319:288] <= csr_writedata;
		    // 5'd23: csr_writedata_reg[287:256] <= csr_writedata;
		    // 5'd24: csr_writedata_reg[255:224] <= csr_writedata;
		    // 5'd25: csr_writedata_reg[223:192] <= csr_writedata;
		    // 5'd26: csr_writedata_reg[191:160] <= csr_writedata;
		    // 5'd27: csr_writedata_reg[159:128] <= csr_writedata;
		    // 5'd28: csr_writedata_reg[127: 96] <= csr_writedata;
		    // 5'd29: csr_writedata_reg[ 95: 64] <= csr_writedata;
		    // 5'd30: csr_writedata_reg[ 63: 32] <= csr_writedata;
		    // 5'd31: csr_writedata_reg[ 31:  0] <= csr_writedata;
		    default: begin
			csr_write_kick <= 0;
			csr_read_kick <= 0;
		    end
		endcase
	    end
	end
    end // always @ (posedge clk)
    
    always_ff @(posedge clk) begin
	if (reset == 1) begin
	    m0_readdata_reg <= -1;
	end else begin
	    if(m0_readdatavalid)
	      m0_readdata_reg <= m0_readdata;
	end
    end

    always_ff @ (posedge clk) begin
	if (reset == 1) begin
	    csr_readdata <= 32'h00000000;
	end else if (csr_read == 1) begin
	    case (csr_address)
		5'd0: csr_readdata <= VERSION;
		5'd1: begin
		    csr_readdata[31:4] <= 0;
		    csr_readdata[3] <= all_core_reset;
		    csr_readdata[2] <= recv_fifo_kick;
		    csr_readdata[1] <= recv_fifo_clear;
		    csr_readdata[0] <= send_fifo_clear;
		end
		5'd2: begin
		    csr_readdata[31:CORES] <= 0;
		    csr_readdata[CORES-1:0] <= core_status;
		end
		5'd3: csr_readdata <= recv_fifo_counter[63:32];
		5'd4: csr_readdata <= recv_fifo_counter[31:0];
		5'd5: csr_readdata <= send_fifo_counter[63:32];
		5'd6: csr_readdata <= send_fifo_counter[31:0];

		5'd7: csr_readdata <= data_count[63:32];
		5'd8: csr_readdata <= data_count[31:0];
		5'd9: csr_readdata <= src_addr_offset[63:32];
		5'd10: csr_readdata <= src_addr_offset[31:0];
		5'd11: csr_readdata <= dst_addr_offset[63:32];
		5'd12: csr_readdata <= dst_addr_offset[31:0];

		// 5'd16: csr_readdata <= m0_readdata_reg[511:480];
		// 5'd17: csr_readdata <= m0_readdata_reg[479:448];
		// 5'd18: csr_readdata <= m0_readdata_reg[447:416];
		// 5'd19: csr_readdata <= m0_readdata_reg[415:384];
		// 5'd20: csr_readdata <= m0_readdata_reg[383:352];
		// 5'd21: csr_readdata <= m0_readdata_reg[351:320];
		// 5'd22: csr_readdata <= m0_readdata_reg[319:288];
		// 5'd23: csr_readdata <= m0_readdata_reg[287:256];
		// 5'd24: csr_readdata <= m0_readdata_reg[255:224];
		// 5'd25: csr_readdata <= m0_readdata_reg[223:192];
		// 5'd26: csr_readdata <= m0_readdata_reg[191:160];
		// 5'd27: csr_readdata <= m0_readdata_reg[159:128];
		// 5'd28: csr_readdata <= m0_readdata_reg[127: 96];
		// 5'd29: csr_readdata <= m0_readdata_reg[ 95: 64];
		// 5'd30: csr_readdata <= m0_readdata_reg[ 63: 32];
		// 5'd31: csr_readdata <= m0_readdata_reg[ 31:  0];
		default: csr_readdata <= 32'hDEADBEEF;
	    endcase // case (csr_address)
	end
    end

endmodule // mspe_wrapper

`default_nettype wire
