`default_nettype none

module mspe#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14, DEVICE="ARTIX7")
    (
     input wire clk,
     input wire reset,

     input wire [1:0]    csr_address,
     input wire [31:0]   csr_writedata,
     input wire          csr_write,
     output logic [31:0] csr_readdata,
     input wire          csr_read,
     input wire [3:0]    csr_byteenable,
    
     input wire [$clog2(CORES)+INSN_DEPTH+2-1:0] insn_addr,
     input wire [31:0] insn_din,
     input wire        insn_we,

     input wire [$clog2(CORES)+DMEM_DEPTH+2-1:0] data_addr,
     input wire [31:0] data_din,
     input wire        data_we,

     output logic [31:0] uart_dout,
     output logic        uart_we,

     input wire [511:0] snk_data,
     input wire snk_valid,
     input wire snk_sop,
     input wire snk_eop,
     output logic snk_ready,

     output logic [511:0] src_data,
     output logic src_valid,
     output logic src_sop,
     output logic src_eop,
     input wire src_ready
     );

    logic [31:0] core_run;
    logic [31:0] core_status;
    always @ (posedge clk) begin
	if (reset == 1) begin
	    core_run <= 32'h00000000;
	end else begin
	    if ((csr_address == 2'b00) & (csr_write == 1) & (csr_byteenable[0] == 1))
              core_run[7:0] <= csr_writedata[7:0];
	    if ((csr_address == 2'b00) & (csr_write == 1) & (csr_byteenable[1] == 1))
              core_run[15:8] <= csr_writedata[15:8];
	    if ((csr_address == 2'b00) & (csr_write == 1) & (csr_byteenable[2] == 1))
              core_run[23:16] <= csr_writedata[23:16];
	    if ((csr_address == 2'b00) & (csr_write == 1) & (csr_byteenable[3] == 1))
              core_run[31:24] <= csr_writedata[31:24];
	end
    end // always @ (posedge clk)

    always @ (posedge clk) begin
	if (reset == 1) begin
	    csr_readdata <= 32'h00000000;
	end else if (csr_read == 1) begin
	    case (csr_address)
		2'b00: csr_readdata <= core_run;
		2'b01: csr_readdata <= core_status;
		default:  csr_readdata <= 32'hDEADBEEF;
	    endcase
	end
    end
    
    logic [31:0]      core_insn_addr;
    logic [31:0]      core_insn_din;
    logic [CORES-1:0] core_insn_we;
    
    logic [31:0]      core_data_addr;
    logic [31:0]      core_data_din;
    logic [CORES-1:0] core_data_we;
    
    logic [31:0]      core_uart_dout[CORES-1:0];
    logic [CORES-1:0] core_uart_we;

    logic [31:0]      core_fifo_count[CORES-1:0];
    logic [31:0]      core_fifo_din[CORES-1:0];
    logic [CORES-1:0] core_fifo_re;

    logic [31:0]      core_fifo_dout[CORES-1:0];
    logic [CORES-1:0] core_fifo_we;

    logic [511:0]     snk_fifo_data [CORES-1:0];
    logic [CORES-1:0] snk_fifo_we;

    logic [CORES-1:0] src_fifo_re;
    logic [511:0]     src_fifo_data[CORES-1:0];
    logic [31:0]      src_fifo_count[CORES-1:0];

    integer j;
    always_comb begin
	core_insn_addr[31:INSN_DEPTH+2] = 0;
	core_insn_addr[INSN_DEPTH+2-1:2] = insn_addr;
	core_insn_din = insn_din;
	core_data_addr[31:DMEM_DEPTH+2] = 0;
	core_data_addr[DMEM_DEPTH+2-1:2] = data_addr;
	core_data_din = data_din;

	for(j = 0; j < CORES; j = j + 1) begin
	    if(insn_addr[$clog2(CORES)+INSN_DEPTH+2-1:INSN_DEPTH+2] == j) begin
		core_insn_we[j] = insn_we;
	    end else begin
		core_insn_we[j] = 1'b0;
	    end
	    if(data_addr[$clog2(CORES)+DMEM_DEPTH+2-1:DMEM_DEPTH+2] == j) begin
		core_data_we[j] = data_we;
	    end else begin
		core_data_we[j] = 1'b0;
	    end

	    snk_fifo_data[j] = snk_data;
	    snk_fifo_we[j] = snk_valid;
	    
	    uart_we = 1'b0;
	    uart_dout = 32'h0000_0000;
	    if(core_uart_we[j]) begin
		uart_we = core_uart_we[j];
		uart_dout = core_uart_dout[j];
	    end
	end
    end

    genvar i;
    generate
	for(i = 0; i < CORES; i = i + 1) begin : mspe_cores
	    core core_i(
			.clk(clk),
			.reset(reset),
			.run(core_run[i]),
		
			.insn_addr(core_insn_addr),
			.insn_din(core_insn_din),
			.insn_we(core_insn_we[i]),

			.data_addr(core_data_addr),
			.data_din(core_data_din),
			.data_we(core_data_we[i]),

			.uart_dout(core_uart_dout[i]),
			.uart_we(core_uart_we[i]),

			.fifo_count(core_fifo_count[i]),
			.fifo_din(core_fifo_din[i]),
			.fifo_re(core_fifo_re[i]),
			.fifo_dout(core_fifo_dout[i]),
			.fifo_we(core_fifo_we[i])
			);

	    // to core
	    sink_fifo#(.DEVICE(DEVICE))
	    sink_fifo_i(
			.wr_clk(clk),
			.wr_rst(reset),
			.rd_clk(clk),
			.rd_rst(reset),
			.din(snk_fifo_data[i]),
			.we(snk_fifo_we[i]),
			.re(core_fifo_re[i]),
			.q(core_fifo_din[i]),
			.rd_count(core_fifo_count[i]),
			.wr_count(),
			.empty(),
			.full()
			);
	    
	    // from core
            src_fifo#(.DEVICE(DEVICE))
	    src_fifo_i(
		       .wr_clk(clk),
		       .wr_rst(reset),
		       .rd_clk(clk),
		       .rd_rst(reset),
		       .din(core_fifo_dout[i]),
		       .we(core_fifo_we[i]),
		       .re(src_fifo_re[i]),
		       .q(src_fifo_data[i]),
		       .rd_count(src_fifo_count[i]),
		       .wr_count(),
		       .empty(),
		       .full()
		       );

	end // block: mspe_cores
    endgenerate

    assign snk_ready = 1'b1;

    logic [31:0] output_core;
    logic [7:0] 	state_counter = 8'd0;
    logic [7:0] 	prev_state_counter = 8'd0;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state_counter <= 8'd0;
	    src_valid <= 0;
	end else begin
	    prev_state_counter <= state_counter;
	    case(state_counter)
		0: begin
		    src_valid <= 0;
		    if(src_fifo_count[output_core] >= src_fifo_data[output_core]) begin
			state_counter <= state_counter + 1;
		    end else begin
			output_core <= (output_core == CORES-1) ? 0 : output_core+1;
		    end
		end
		1: begin
		    if(src_fifo_count[output_core] == 0) begin
			src_fifo_re[output_core] <= 0;
			state_counter <= 0;
			output_core <= (output_core == CORES-1) ? 0 : output_core+1;
			src_valid <= 0;
		    end else begin
			src_fifo_re[output_core] <= 1;
			src_data <= src_fifo_data[output_core];
			src_eop <= src_fifo_count[output_core] == 1 ? 1 : 0;
			src_sop <= prev_state_counter == 0 ? 1 : 0;
			src_valid <= 1;
		    end
		end
	    endcase // case (state_counter)
	end
    end

endmodule // mspe

`default_nettype wire
