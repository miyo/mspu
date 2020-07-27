`default_nettype none

module mspe#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14, DEVICE="ARTIX7")
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
     output wire           m0_debugaccess,

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
     output wire           m1_debugaccess,

     output wire recv_fifo_rdreq,
     input wire [511:0] recv_fifo_q,
     input wire [10:0] recv_fifo_rdusedw,
     
     output logic [511:0] src_data,
     output logic src_valid,
     output logic src_sop,
     output logic src_eop,
     input logic src_ready
     );

    localparam VERSION = 32'h3434_0002;

    logic [CORES-1:0] core_reset;
    logic [CORES-1:0] core_run;
    logic [CORES-1:0] core_status;

    logic [512-1:0] m0_readdata_reg;

    logic [3-1:0] csr_burstcount_reg;
    logic [512-1:0] csr_writedata_reg;
    logic [64-1:0]  csr_address_reg;
    logic csr_write_reg;
    logic csr_read_reg;
    logic [63:0] csr_byteenable_reg;
    logic csr_debugaccess_reg;
    
    assign m0_burstcount  = csr_burstcount_reg;
    assign m0_writedata   = csr_writedata_reg;
    assign m0_address     = csr_address_reg;
    assign m0_write       = csr_write_reg;
    assign m0_read        = csr_read_reg;
    assign m0_byteenable  = csr_byteenable_reg;
    assign m0_debugaccess = csr_debugaccess_reg;

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
		    5'd13: begin
			csr_write_kick <= csr_writedata[0];
			csr_read_kick <= csr_writedata[1];
		    end
		    5'd14: csr_address_reg[63:32] <= csr_writedata;
		    5'd15: csr_address_reg[31: 0] <= csr_writedata;
		    5'd16: csr_writedata_reg[511:480] <= csr_writedata;
		    5'd17: csr_writedata_reg[479:448] <= csr_writedata;
		    5'd18: csr_writedata_reg[447:416] <= csr_writedata;
		    5'd19: csr_writedata_reg[415:384] <= csr_writedata;
		    5'd20: csr_writedata_reg[383:352] <= csr_writedata;
		    5'd21: csr_writedata_reg[351:320] <= csr_writedata;
		    5'd22: csr_writedata_reg[319:288] <= csr_writedata;
		    5'd23: csr_writedata_reg[287:256] <= csr_writedata;
		    5'd24: csr_writedata_reg[255:224] <= csr_writedata;
		    5'd25: csr_writedata_reg[223:192] <= csr_writedata;
		    5'd26: csr_writedata_reg[191:160] <= csr_writedata;
		    5'd27: csr_writedata_reg[159:128] <= csr_writedata;
		    5'd28: csr_writedata_reg[127: 96] <= csr_writedata;
		    5'd29: csr_writedata_reg[ 95: 64] <= csr_writedata;
		    5'd30: csr_writedata_reg[ 63: 32] <= csr_writedata;
		    5'd31: csr_writedata_reg[ 31:  0] <= csr_writedata;
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
		    csr_readdata[31:CORES] <= 0;
		    csr_readdata[CORES-1:0] <= core_run;
		end
		5'd2: begin
		    csr_readdata[31:CORES] <= 0;
		    csr_readdata[CORES-1:0] <= core_status;
		end
		5'd16: csr_readdata <= m0_readdata_reg[511:480];
		5'd17: csr_readdata <= m0_readdata_reg[479:448];
		5'd18: csr_readdata <= m0_readdata_reg[447:416];
		5'd19: csr_readdata <= m0_readdata_reg[415:384];
		5'd20: csr_readdata <= m0_readdata_reg[383:352];
		5'd21: csr_readdata <= m0_readdata_reg[351:320];
		5'd22: csr_readdata <= m0_readdata_reg[319:288];
		5'd23: csr_readdata <= m0_readdata_reg[287:256];
		5'd24: csr_readdata <= m0_readdata_reg[255:224];
		5'd25: csr_readdata <= m0_readdata_reg[223:192];
		5'd26: csr_readdata <= m0_readdata_reg[191:160];
		5'd27: csr_readdata <= m0_readdata_reg[159:128];
		5'd28: csr_readdata <= m0_readdata_reg[127: 96];
		5'd29: csr_readdata <= m0_readdata_reg[ 95: 64];
		5'd30: csr_readdata <= m0_readdata_reg[ 63: 32];
		5'd31: csr_readdata <= m0_readdata_reg[ 31:  0];
		default: csr_readdata <= 32'hDEADBEEF;
	    endcase // case (csr_address)
	end
    end

    logic [$clog2(CORES)+INSN_DEPTH+2-1:0] loader_insn_addr;
    logic [31:0] loader_insn_dout;
    logic loader_insn_we;
    logic [$clog2(CORES)+DMEM_DEPTH+2-1:0] loader_data_addr;
    logic [31:0] loader_data_dout;
    logic loader_data_we;

    logic [31:0]      core_insn_addr;
    logic [31:0]      core_insn_din;
    logic [CORES-1:0] core_insn_we;
    
    logic [31:0]      core_data_addr;
    logic [31:0]      core_data_din;
    logic [CORES-1:0] core_data_we;
    logic [CORES-1:0] core_data_oe;
    logic [31:0]      core_data_q[CORES-1:0];
    logic [CORES-1:0] core_halt;

    assign core_status = core_halt;
    
    logic [31:0]      core_uart_dout[CORES-1:0];
    logic [CORES-1:0] core_uart_we;

    logic [CORES-1:0] core_snk_sop;
    logic [CORES-1:0] core_snk_eop;
    logic [CORES-1:0] core_snk_valid;
    logic [511:0] core_snk_din;

    logic [CORES-1:0] core_src_req;
    logic [CORES-1:0] core_src_sop;
    logic [CORES-1:0] core_src_eop;
    logic [CORES-1:0] core_src_valid;
    logic [511:0] core_src_q[CORES-1:0];

    genvar i;
    generate
	for(i = 0; i < CORES; i = i + 1) begin : mspe_cores

	    core_wrapper core_i(
				.clk(clk),
				.reset(reset | core_reset[i]),
				.run(core_run[i]),
				.insn_addr(core_insn_addr),
				.insn_din(core_insn_din),
				.insn_we(core_insn_we[i]),
				.data_addr(core_data_addr),
				.data_din(core_data_din),
				.data_we(core_data_we[i]),
				.data_oe(core_data_oe[i]),
				.data_q(core_data_q[i]),
				.uart_dout(core_uart_dout[i]),
				.uart_we(core_uart_we[i]),
				.emit_insn_mon(),
				.emit_pc_out_mon(),
				.halt_mon(core_halt[i]),

				.snk_sop(core_snk_sop[i]),
				.snk_eop(core_snk_eop[i]),
				.snk_valid(core_snk_valid[i]),
				.snk_din(core_snk_din),

				.src_req(core_src_req[i]),
				.src_sop(core_src_sop[i]),
				.src_eop(core_src_eop[i]),
				.src_valid(core_src_valid[i]),
				.src_q(core_src_q[i]));

	end // block: mspe_cores
    endgenerate

    logic core_manager_init_busy;
    logic core_valid;
    logic [$clog2(CORES)-1:0] core_id;
    logic core_request;
    logic core_release;
    logic [$clog2(CORES)-1:0] released_core_id;

`ifdef CORE_OoO_ASSIGNMENT
    core_manager(.CORES(4)) core_manager_i(.clk(clk),
					   .reset(reset),
					   .init_busy(core_manager_init_busy),
					   .core_valid(core_valid),
					   .core_id(core_id),
					   .core_request(core_request),
					   .core_release(core_release),
					   .released_core_id(released_core_id));
`else

    assign core_manager_init_busy = 0;
    core_simple_assignment#(.CORES(4))
    core_simple_assignment_i(
			     .clk(clk),
			     .reset(reset),
			     .core_valid(core_valid),
			     .core_id(core_id),
			     .core_request(core_request),
			     .core_release(core_release),
			     .released_core_id(released_core_id));

`endif


    logic loader_kick, loader_busy, loader_busy_d1, loader_busy_d2, loader_busy_d3;
    logic [63:0] loader_memory_base_addr;
    logic [$clog2(CORES)-1:0] loader_target_core;

    data_loader#(.CORES(CORES), .INSN_DEPTH(INSN_DEPTH), .DMEM_DEPTH(DMEM_DEPTH))
    data_loader_i(.clk(clk),
		  .reset(reset),
		  .kick(loader_kick),
		  .busy(loader_busy),
		  .memory_base_addr(loader_memory_base_addr),
		  .target_core(loader_target_core),
		  .insn_addr(loader_insn_addr),
		  .insn_dout(loader_insn_dout),
		  .insn_we(loader_insn_we),
		  .data_addr(loader_data_addr),
		  .data_dout(loader_data_dout),
		  .data_we(loader_data_we),
		  .m0_waitrequest(m1_waitrequest), 
		  .m0_readdata(m1_readdata),
		  .m0_readdatavalid(m1_readdatavalid),
		  .m0_burstcount(m1_burstcount),
		  .m0_writedata(m1_writedata),
		  .m0_address(m1_address),
		  .m0_write(m1_write),
		  .m0_read(m1_read),
		  .m0_byteenable(m1_byteenable),
		  .m0_debugaccess(m1_debugaccess)
		  );

    logic [$clog2(CORES)-1:0] target_core;
    logic target_core_valid;
    logic target_snk_sop;
    logic target_snk_eop;
    logic target_snk_valid;
    logic [511:0] target_snk_data;
    logic enqueue_loader_kick;
    logic [63:0] enqueue_loader_memory_base_addr;

    stream_data_parser#(.CORES(CORES))
    stream_data_parser_i(
			 .clk(clk),
			 .reset(reset),

			 .recv_fifo_rdreq(recv_fifo_rdreq),
			 .recv_fifo_q(recv_fifo_q),
			 .recv_fifo_rdusedw(recv_fifo_rdusedw),

			 .core_valid(core_valid),
			 .core_id(core_id),

			 .target_core(target_core),
			 .target_core_valid(target_core_valid),
			 .target_snk_sop(target_snk_sop),
			 .target_snk_eop(target_snk_eop),
			 .target_snk_valid(target_snk_valid),
			 .target_snk_data(target_snk_data),

			 .loader_kick(enqueue_loader_kick),
			 .loader_memory_base_addr(enqueue_loader_memory_base_addr)
			 );

    //assign loader_target_core = target_core;
    assign core_request = target_core_valid;

    logic [$clog2(CORES)-1:0] cur_loader_id;
    logic cur_loader_valid;
    logic cur_loader_consume;

    logic [$clog2(CORES)-1:0] run_enqueue_id;
    logic run_enqueue_valid;
    logic [$clog2(CORES)-1:0] cur_run_id;
    logic cur_run_valid;
    logic cur_run_consume;

`ifdef CORE_OoO_ASSIGNMENT

    core_task_queue#(.CORES(4)) loader_task_queue(
						  .clk(clk),
						  .reset(reset),
						  .enqueue_id(target_core),
						  .enqueue_valid(enqueue_loader_kick),
						  .current_id(cur_loader_id),
						  .current_valid(cur_loader_valid),
						  .current_consume(cur_loader_consume)
						  );

    core_task_queue#(.CORES(4)) run_task_queue(
					       .clk(clk),
					       .reset(reset),
					       .enqueue_id(run_enqueue_id),
					       .enqueue_valid(run_enqueue_valid),
					       .current_id(cur_run_id),
					       .current_valid(cur_run_valid),
					       .current_consume(cur_run_consume)
					       );
`else // !`ifdef CORE_OoO_ASSIGNMENT

    core_simple_queue#(.CORES(4)) loader_task_queue(
						    .clk(clk),
						    .reset(reset),
						    .enqueue_id(target_core),
						    .enqueue_valid(enqueue_loader_kick),
						    .current_id(cur_loader_id),
						    .current_valid(cur_loader_valid),
						    .current_consume(cur_loader_consume)
						    );
    core_simple_queue#(.CORES(4)) run_task_queue(
						 .clk(clk),
						 .reset(reset),
						 .enqueue_id(run_enqueue_id),
						 .enqueue_valid(run_enqueue_valid),
						 .current_id(cur_run_id),
						 .current_valid(cur_run_valid),
						 .current_consume(cur_run_consume)
						 );
    
`endif // !`ifdef CORE_OoO_ASSIGNMENT

    logic [63:0] cur_loader_memory_base_addr;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    loader_kick <= 0;
	end else begin
	    loader_busy_d1 <= loader_busy;
	    loader_busy_d2 <= loader_busy_d1;
	    loader_busy_d3 <= loader_busy_d2;
	    if((loader_busy | loader_busy_d1 | loader_busy_d2 | loader_busy_d3) == 0) begin
		loader_kick <= cur_loader_valid;
		loader_target_core <= cur_loader_id;
		loader_memory_base_addr <= cur_loader_memory_base_addr;
	    end else begin
		loader_kick <= 0;
	    end
	end
    end

    logic [63:0] memory_base_addr_pool[CORES-1:0];
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	end else begin
	    if(enqueue_loader_kick) begin
		memory_base_addr_pool[target_core] <= enqueue_loader_memory_base_addr;
	    end
	end
    end


    logic loader_busy_d;
    logic cur_core_halt, cur_core_halt_d;
    logic target_src_req;
    logic target_src_sop;
    logic target_src_eop;
    logic target_src_eop_d;
    logic target_src_valid;
    logic [511:0] target_src_q;
    logic cur_loader_consume_d;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    loader_busy_d <= 0;
	    cur_loader_consume <= 0;
	    run_enqueue_valid <= 0;
	    run_enqueue_id <= 0;
	    cur_core_halt_d <= 0;
	    cur_run_consume <= 0;
	    cur_run_id <= 0;
	    core_release <= 0;
	    target_src_req <= 0;
	    target_src_eop_d <= 0;
	end else begin
	    cur_loader_consume_d <= cur_loader_consume;
	    loader_busy_d <= loader_busy;
	    cur_core_halt_d <= cur_core_halt;
	    target_src_eop_d <= target_src_eop;
	    if(cur_loader_valid == 1 && loader_busy == 0 && loader_busy_d == 1) begin
		cur_loader_consume <= 1;
		run_enqueue_valid <= 1;
		run_enqueue_id <= cur_loader_id;
	    end else begin
		cur_loader_consume <= 0;
		run_enqueue_valid <= 0;
	    end
	    if(cur_run_valid == 1 && cur_core_halt == 1 && cur_core_halt_d == 0) begin
		target_src_req <= 1;
	    end else begin
		target_src_req <= 0;
	    end
	    if(cur_run_valid == 1 && target_src_eop == 1 && target_src_eop_d == 0) begin
		cur_run_consume <= 1;
		core_release <= 1;
	    end else begin
		cur_run_consume <= 0;
		core_release <= 0;
	    end
	end
    end

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    core_reset <= -1;
	end else begin
	    if(cur_run_consume == 1)
	      core_reset[cur_run_id] <= 1;
	    else
	      core_reset <= 0;
	end
    end


    integer j;
    always_comb begin
	core_insn_addr[31:INSN_DEPTH+2] = 0;
	core_insn_addr[INSN_DEPTH+2-1:0] = loader_insn_addr;
	core_insn_din = loader_insn_dout;
	core_data_addr[31:DMEM_DEPTH+2] = 0;
	core_data_addr[DMEM_DEPTH+2-1:0] = loader_data_addr;
	core_data_din = loader_data_dout;

	for(j = 0; j < CORES; j = j + 1) begin
	    if(loader_insn_addr[$clog2(CORES)+INSN_DEPTH+2-1:INSN_DEPTH+2] == j) begin
		core_insn_we[j] = loader_insn_we;
	    end else begin
		core_insn_we[j] = 1'b0;
	    end
	    if(loader_data_addr[$clog2(CORES)+DMEM_DEPTH+2-1:DMEM_DEPTH+2] == j) begin
		core_data_we[j] = loader_data_we;
	    end else begin
		core_data_we[j] = 1'b0;
	    end

	    core_data_oe[j] = 0;

	    if(target_core == j) begin
		core_snk_sop[j] = target_snk_sop;
	    end else begin
		core_snk_sop[j] = 0;
	    end

	    if(target_core == j) begin
		core_snk_eop[j] = target_snk_eop;
	    end else begin
		core_snk_eop[j] = 0;
	    end

	    if(target_core == j) begin
		core_snk_valid[j] = target_snk_valid;
	    end else begin
		core_snk_valid[j] = 0;
	    end

	    if(cur_run_id == j) begin
		cur_core_halt = core_halt[j];
	    end

	    if(j == run_enqueue_id) begin
		core_run[j] = run_enqueue_valid;
	    end else begin
		core_run[j] = 0;
	    end

	    if(cur_run_id == j) begin
		core_src_req[j] = target_src_req;
	    end else begin
		core_src_req[j] = 0;
	    end

	    if(cur_run_id == j) begin
		target_src_sop = core_src_sop[j];
	    end
	    if(cur_run_id == j) begin
		target_src_eop = core_src_eop[j];
	    end
	    if(cur_run_id == j) begin
		target_src_valid = core_src_valid[j];
	    end
	    if(cur_run_id == j) begin
		target_src_q = core_src_q[j];
	    end

	    if(cur_loader_id == j) begin
		cur_loader_memory_base_addr = memory_base_addr_pool[j];
	    end
	    
	end
	core_snk_din = target_snk_data;

	src_sop <= target_src_sop;
	src_eop <= target_src_eop;
	src_valid <= target_src_valid;
	src_data <= target_src_q;

    end // always_comb

endmodule // mspe

`default_nettype wire
