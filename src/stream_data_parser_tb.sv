`default_nettype none

module stream_data_parser_tb#(parameter CORES=4);

    logic clk;
    logic reset;
    
    logic recv_fifo_rdreq;
    logic [511:0] recv_fifo_q;
    logic [10:0] recv_fifo_rdusedw;
    logic recv_fifo_valid;

    logic core_valid;
    logic [$clog2(CORES)-1:0] core_id;

    logic [$clog2(CORES)-1:0] target_core;
    logic target_core_valid;
    logic target_snk_sop;
    logic target_snk_eop;
    logic target_snk_valid;
    logic [511:0] target_snk_data;

    logic loader_kick;
    logic [63:0] loader_memory_base_addr;

    initial begin
	clk = 0;
    end

    always begin
	clk = ~clk;
	#5;
    end

    logic [31:0] counter = 0;

    always_ff @(posedge clk) begin

	case(counter)
	    
	    0: begin
		counter <= counter + 1;
		reset <= 1;
		recv_fifo_q <= 0;
		recv_fifo_rdusedw <= 0;
		recv_fifo_valid <= 0;
		core_valid <= 0;
		core_id <= 0;
	    end

	    9: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    10: begin
		counter <= counter + 1;
		core_valid <= 1;
		core_id <= 1;
	    end

	    11: begin
		counter <= counter + 1;
		recv_fifo_q[31:0] <= 4; // data length
		recv_fifo_q[63:32] <= 3; // id
		recv_fifo_rdusedw <= 4;
		recv_fifo_valid <= 1;
	    end

	    21: begin
		counter <= counter + 1;
		recv_fifo_q[31:0] <= 1; // data length
		recv_fifo_q[63:32] <= 0; // id
		recv_fifo_rdusedw <= 1;
		recv_fifo_valid <= 1;
	    end
	    
	    31: begin
		counter <= counter + 1;
		recv_fifo_q[31:0] <= 6; // data length
		recv_fifo_q[63:32] <= 2; // id
		recv_fifo_rdusedw <= 6;
		recv_fifo_valid <= 1;
	    end

	    default: begin
		counter <= counter + 1;
	    end

	endcase // case (counter)

	if(target_core_valid == 1) begin
	    core_id <= core_id + 1;
	end
	if(recv_fifo_rdreq == 1)begin
	    recv_fifo_rdusedw <= recv_fifo_rdusedw - 1;
	end

    end

    stream_data_parser#(.CORES(CORES))
    stream_data_parser_i(
			 .clk(clk),
			 .reset(reset),

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

			 .loader_kick(loader_kick),
			 .loader_memory_base_addr(loader_memory_base_addr)
			 );

endmodule // stream_data_parser_tb

`default_nettype wire

