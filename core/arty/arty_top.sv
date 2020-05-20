`default_nettype none

module arty_top
  (
   input wire clk,
   input wire reset,

   input wire sw0,
   input wire sw1,

   input wire uart_rxi,
   output wire uart_txo
   );

    (* mark_debug *) logic [31:0] uart_dout;
    (* mark_debug *) logic uart_we;

    logic [31:0] run_counter = 32'd100;
    (* mark_debug *) logic run = 0;

    (* mark_debug *) logic [31:0] insn_addr;
    (* mark_debug *) logic [31:0] insn_din;
    (* mark_debug *) logic insn_we;

    (* mark_debug *) logic [31:0] data_addr;
    (* mark_debug *) logic [31:0] data_din;
    (* mark_debug *) logic data_we;

    logic rd_en = 1'b0;
    logic [31:0] dout;
    logic full, empty, valid;

    logic serial_send_kick = 1'b0;
    logic uart_ready;

    (* mark_debug *) logic uart_rx_rd;
    (* mark_debug *) logic uart_rx_rd_d;
    (* mark_debug *) logic [7:0] uart_rx_dout;

    logic [31:0] insn_counter = 32'd0;
    logic [31:0] data_counter = 32'd0;

    logic [31:0] data_buf;
    logic [31:0] insn_buf;

    (* mark_debug *) logic run_d;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    run <= 0;
	    run_d <= 0;
	    insn_we <= 0;
	    data_we <= 0;
	    uart_rx_rd_d <= 0;
	end else begin
	    run_d <= run;
	    uart_rx_rd_d <= uart_rx_rd;

	    if(sw0 == 0) begin
		insn_we <= 0;
		data_we <= 0;
		insn_counter <= 0;
		data_counter <= 0;
		if(run_counter > 0)
		  run_counter <= run_counter - 1;
		else
		  run <= 1;
	    end else begin
	     	run_counter <= 32'd100;
		run <= 0;
		if(~uart_rx_rd_d && uart_rx_rd) begin
		    if(sw1 == 1) begin
			data_buf <= {uart_rx_dout, data_buf[31:8]};
			data_counter <= data_counter + 1;
			if(data_counter[1:0] == 2'b11) begin
			    data_we <= 1'b1;
			    data_addr <= data_counter;
			    data_din <= {uart_rx_dout, data_buf[31:8]};
			end else begin
			    data_we <= 1'b0;
			end
		    end else begin
			insn_buf <= {uart_rx_dout, insn_buf[31:8]};
			insn_counter <= insn_counter + 1;
			if(insn_counter[1:0] == 2'b11) begin
			    insn_we <= 1'b1;
			    insn_addr <= insn_counter;
			    insn_din <= {uart_rx_dout, insn_buf[31:8]};
			end else begin
			    insn_we <= 1'b0;
			end
		    end
		end else begin
		    data_we <= 1'b0;
		    insn_we <= 1'b0;
		end
	    end
	end
    end

   
    core core_i(.clk(clk),
		.reset(reset),
		.run(run),
   
		.insn_addr(insn_addr),
		.insn_din(insn_din),
		.insn_we(insn_we),

		.data_addr(data_addr),
		.data_din(data_din),
		.data_we(data_we),

		.uart_dout(uart_dout),
		.uart_we(uart_we)
		);

    fifo_generator_0 fifo_i (.clk(clk),       // input wire clk
			     .srst(reset),    // input wire srst
			     .din(uart_dout), // input wire [31 : 0] din
			     .wr_en(uart_we), // input wire wr_en
			     .rd_en(rd_en),   // input wire rd_en
			     .dout(dout),     // output wire [31 : 0] dout
			     .full(full),     // output wire full
			     .empty(empty),   // output wire empty
			     .valid(valid)
			     );

    uart_tx#(.sys_clk(100000000), .rate(115200))
    uart_tx_i(.clk(clk),
	      .reset(reset),
	      .wr(serial_send_kick),
	      .din(dout),
	      .dout(uart_txo),
	      .ready(uart_ready));

    always_ff @(posedge clk) begin
	if(valid == 1'b1 && uart_ready == 1'b1 && serial_send_kick == 1'b0) begin
	    serial_send_kick <= 1'b1;
	    rd_en <= 1'b1;
	end else begin
	    serial_send_kick <= 1'b0;
	    rd_en <= 1'b0;
	end
    end

    uart_rx#(.sys_clk(100000000), .rate(115200))
    uart_rx_i(.clk(clk),
	      .reset(reset),
	      .din(uart_rxi),
	      .rd(uart_rx_rd),
	      .dout(uart_rx_dout));

endmodule // arty_top

`default_nettype wire
