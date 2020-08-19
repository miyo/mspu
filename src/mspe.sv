`default_nettype none

module mspe#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14, DEVICE="ARTIX7")
    (
     input wire clk,
     input wire reset,

     // to access DRAM to read insn/data
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

     output wire recv_fifo_rdreq,
     input wire [511:0] recv_fifo_q,
     input wire [10:0] recv_fifo_rdusedw,
     input wire recv_fifo_valid,
     
     output logic [511:0] src_data,
     output logic src_valid,
     output logic src_sop,
     output logic src_eop,
     input wire src_ready,

     output logic [CORES-1:0] core_status,
     input wire all_core_reset
    );

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

    logic [CORES-1:0] core_reset;
    logic [CORES-1:0] core_run;

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
    logic [$clog2(CORES)-1:0] released_core_id = 0;

`ifdef CORE_OoO_ASSIGNMENT
    core_manager(.CORES(4)) core_manager_i(.clk(clk),
					   .reset(reset | all_core_reset),
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
			     .reset(reset | all_core_reset),
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
		  .reset(reset | all_core_reset),
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
		  .m0_waitrequest(m0_waitrequest), 
		  .m0_readdata(m0_readdata),
		  .m0_readdatavalid(m0_readdatavalid),
		  .m0_burstcount(m0_burstcount),
		  .m0_writedata(m0_writedata),
		  .m0_address(m0_address),
		  .m0_write(m0_write),
		  .m0_read(m0_read),
		  .m0_byteenable(m0_byteenable),
		  .m0_debugaccess(m0_debugaccess)
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
			 .reset(reset | all_core_reset),

			 .recv_fifo_rdreq(recv_fifo_rdreq),
			 .recv_fifo_q(recv_fifo_q),
			 .recv_fifo_rdusedw(recv_fifo_rdusedw),
			 .recv_fifo_valid(recv_fifo_valid),

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
						  .reset(reset | all_core_reset),
						  .enqueue_id(target_core),
						  .enqueue_valid(enqueue_loader_kick),
						  .current_id(cur_loader_id),
						  .current_valid(cur_loader_valid),
						  .current_consume(cur_loader_consume)
						  );

    core_task_queue#(.CORES(4)) run_task_queue(
					       .clk(clk),
					       .reset(reset | all_core_reset),
					       .enqueue_id(run_enqueue_id),
					       .enqueue_valid(run_enqueue_valid),
					       .current_id(cur_run_id),
					       .current_valid(cur_run_valid),
					       .current_consume(cur_run_consume)
					       );
`else // !`ifdef CORE_OoO_ASSIGNMENT

    core_simple_queue#(.CORES(4)) loader_task_queue(
						    .clk(clk),
						    .reset(reset | all_core_reset),
						    .enqueue_id(target_core),
						    .enqueue_valid(enqueue_loader_kick),
						    .current_id(cur_loader_id),
						    .current_valid(cur_loader_valid),
						    .current_consume(cur_loader_consume)
						    );
    core_simple_queue#(.CORES(4)) run_task_queue(
						 .clk(clk),
						 .reset(reset | all_core_reset),
						 .enqueue_id(run_enqueue_id),
						 .enqueue_valid(run_enqueue_valid),
						 .current_id(cur_run_id),
						 .current_valid(cur_run_valid),
						 .current_consume(cur_run_consume)
						 );
    
`endif // !`ifdef CORE_OoO_ASSIGNMENT

    logic [63:0] cur_loader_memory_base_addr;
    always_ff @(posedge clk) begin
	if(reset | all_core_reset) begin
	    loader_kick <= 0;
	    loader_target_core <= 0;
	    loader_memory_base_addr <= 0;
	    loader_busy_d1 <= 1;
	    loader_busy_d2 <= 1;
	    loader_busy_d3 <= 1;
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
    integer memory_base_addr_pool_i;
    always_ff @(posedge clk) begin
	if(reset | all_core_reset) begin
	    for(memory_base_addr_pool_i = 0;
		memory_base_addr_pool_i < CORES;
		memory_base_addr_pool_i = memory_base_addr_pool_i + 1) begin : memory_base_addr_pool_init
		memory_base_addr_pool[memory_base_addr_pool_i] <= 0;
	    end
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
	if(reset | all_core_reset) begin
	    loader_busy_d <= 0;
	    cur_loader_consume <= 0;
	    run_enqueue_valid <= 0;
	    run_enqueue_id <= 0;
	    cur_core_halt_d <= 0;
	    cur_run_consume <= 0;
	    core_release <= 0;
	    target_src_req <= 0;
	    target_src_eop_d <= 0;
	    cur_loader_consume_d <= 0;
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
	if(reset | all_core_reset) begin
	    core_reset <= 0;
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
