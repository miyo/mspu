`default_nettype none

module stream_data_parser#(parameter CORES=4)
  (
   input wire clk,
   input wire reset,

   input wire [511:0] snk_data,
   input wire snk_valid,
   output wire snk_ready,

   input wire core_valid,
   input wire [$clog2(CORES)-1:0] core_id,

   output logic [$clog2(CORES)-1:0] target_core,
   output logic target_core_valid,
   output logic target_snk_sop,
   output logic target_snk_eop,
   output logic target_snk_valid,
   output logic [511:0] target_snk_data,

   output logic loader_kick,
   output logic [63:0] loader_memory_base_addr
   );

    logic [511:0] recv_fifo_data;
    logic recv_fifo_wrreq;
    logic recv_fifo_rdreq;
    logic [511:0] recv_fifo_q;
    logic [10:0] recv_fifo_rdusedw;
    logic [10:0] recv_fifo_wrusedw;
    logic recv_fifo_rdempty;
    logic recv_fifo_wrfull;

    assign recv_fifo_data = snk_data;
    assign recv_fifo_wrreq = snk_valid;
    assign snk_ready = ~recv_fifo_wrfull;
    
    fifo_ft_512_64 recv_fifo(.data(recv_fifo_data),
			     .wrreq(recv_fifo_wrreq),
			     .rdreq(recv_fifo_rdreq),
			     .wrclk(clk),
			     .rdclk(clk),
			     .q(recv_fifo_q), 
			     .rdusedw(recv_fifo_rdusedw),
			     .wrusedw(recv_fifo_wrusedw),
			     .rdempty(recv_fifo_rdempty),
			     .wrfull(recv_fifo_wrfull)
			     );

    logic [31:0] data_id;

    logic [7:0] state_counter;
    logic [31:0] read_counter;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state_counter <= 0;
	    read_counter <= 0;
	    target_snk_sop <= 0;
	    target_snk_eop <= 0;
	    target_snk_valid <= 0;
	    recv_fifo_rdreq <= 0;
	    loader_kick <= 0;
	    target_core_valid <= 0;
	end else begin
	    case(state_counter)
		0: begin // wait for streaming data
		    if(core_valid == 1 && recv_fifo_rdusedw > recv_fifo_q[31:0]) begin // recv_fifo_q[31:0] = data_length
			// read and send streaming data
			recv_fifo_rdreq <= 1;
			if(recv_fifo_q[31:0] > 1) begin
			    read_counter <= recv_fifo_q[31:0] - 1;
			    state_counter <= state_counter + 1;
			end else begin
			    read_counter <= 0;
			    target_snk_eop <= 0;
			    state_counter <= state_counter + 2;
			end
			target_snk_sop <= 1;
			target_snk_valid <= 1;
			data_id <= recv_fifo_q[63:32];
			target_snk_data <= recv_fifo_q;
			target_core <= core_id;
			target_core_valid <= 1;
		    end else begin
			recv_fifo_rdreq <= 0;
			target_snk_sop <= 0;
			target_snk_valid <= 0;
			data_id <= 0;
			target_snk_data <= 0;
			target_core <= 0;
			target_core_valid <= 0;
		    end
		    loader_kick <= 0;
		end
		1: begin // read and send streaming data
		    if(read_counter == 1) begin
			target_snk_eop <= 1;
			state_counter <= state_counter + 1;
		    end
		    target_snk_sop <= 0;
		    target_snk_valid <= 1;
		    target_snk_data <= recv_fifo_q;
		    read_counter <= read_counter - 1;
		    recv_fifo_rdreq <= 1;
		    target_core_valid <= 0;
		end
		2: begin
		    // stop to read and send streaming data
		    target_snk_sop <= 0;
		    target_snk_eop <= 0;
		    target_snk_valid <= 0;
		    recv_fifo_rdreq <= 0;

		    loader_kick <= 1;
		    loader_memory_base_addr <= {17'b0, data_id, 15'b0};
		    target_core_valid <= 0;
		end
		default: begin
		    state_counter <= 0;
		    read_counter <= 0;
		    target_snk_sop <= 0;
		    target_snk_eop <= 0;
		    target_snk_valid <= 0;
		    recv_fifo_rdreq <= 0;
		    loader_kick <= 0;
		    target_core_valid <= 0;
		end
	    endcase // case (state_counter)
	end
    end

endmodule // stream_data_parser

`default_nettype wire
