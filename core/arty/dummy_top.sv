`default_nettype none

module dummy_top
  (
   input wire clk,
   input wire reset,

   output wire uart_tx
   );

    (* mark_debug *) logic [31:0] uart_dout;
    (* mark_debug *) logic uart_we;

    logic rd_en = 1'b0;
    logic [31:0] dout;
    logic full, empty, valid;

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

    logic serial_send_kick = 1'b0;
    logic uart_busy;
    serial_send serial_send_i(.CLK(clk),
			      .RST(reset),
			      .DATA_OUT(uart_tx),
			      .BUSY(uart_busy),
			      .DATA_IN(dout[7:0]),
			      .WE(serial_send_kick));

    always_ff @(posedge clk) begin
	if(valid == 1'b1 && uart_busy == 1'b0 && serial_send_kick == 1'b0) begin
	    serial_send_kick <= 1'b1;
	    rd_en <= 1'b1;
	end else begin
	    serial_send_kick <= 1'b0;
	    rd_en <= 1'b0;
	end
    end

    logic run = 0;
   
    logic [31:0] insn_addr;
    logic [31:0] insn_din;
    logic insn_we;

    logic [31:0] data_addr;
    logic [31:0] data_din;
    logic data_we;

    logic [7:0] state = 8'd0;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state <= 0;
	    run <= 0;
	    insn_we <= 0;
	    data_we <= 0;
	end else begin

	    case(state)
		0: state <= state + 1;
		1: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h40000417; // auipc s0,0x0
		    insn_addr <= 0;
		    data_we   <= 1;
		    data_din  <= 32'h6c6c6548;
		    data_addr <= 0;
		end
		2: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00040413; // mv    s0,s0
		    insn_addr <= 4;
		    data_we   <= 1;
		    data_din  <= 32'h52202c6f;
		    data_addr <= 4;
		end
		3: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00040503; // lb    a0,0(s0)
		    insn_addr <= 8;
		    data_we   <= 1;
		    data_din  <= 32'h2d435349;
		    data_addr <= 8;
		end
		4: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00140413; // addi  s0,s0,1
		    insn_addr <= 12;
		    data_we   <= 1;
		    data_din  <= 32'h00000a56;
		    data_addr <= 12;
		end
		5: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00050c63; // beqz  a0,80000028 <halt>
		    insn_addr <= 16;
		    data_we   <= 0;
		end
		6: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h008000ef; // jal   ra,8000001c <putchar>
		    insn_addr <= 20;
		end
		7: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'hff1ff06f; // j     80000008 <loop>
		    insn_addr <= 24;
		end
		8: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h100002b7; // lui   t0,0x10000
		    insn_addr <= 28;
		end
		9: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00a28023; // sb    a0,0(t0)
		    insn_addr <= 32;
		end
		10: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00008067; // ret
		    insn_addr <= 36;
		end
		11: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h0000006f;  // j halt
		    insn_addr <= 40;
		end
		12 :begin
		    insn_we   <= 0;
		    state <= state + 1;
		end
		100: begin
		    run <= 1;
		    state <= state + 1;
		end
		101: begin
		end
		default:
		  state <= state + 1;
	    endcase // case (state)
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
		.uart_we(uart_we),

		.fifo_count(32'd0),
		.fifo_din(32'd0),
		.fifo_re(),
		.fifo_dout(),
		.fifo_we()
		);

endmodule // dummy_top

module serial_send (
		    input  wire       CLK, RST,
		    output logic       DATA_OUT,
		    output logic       BUSY,
		    input wire [7:0] DATA_IN,
		    input wire WE
		    );

    parameter  WAIT_DIV = 868; // 100 MHz / 115.2 kbps
    localparam WAIT_LEN = $clog2(WAIT_DIV);

    typedef enum {
        STATE_IDLE,
        STATE_SEND
    } state_type;
    state_type           state, n_state;
    logic          [9:0] data_reg, n_data_reg;
    logic [WAIT_LEN-1:0] wait_cnt, n_wait_cnt;
    logic          [3:0] bit_cnt, n_bit_cnt;

    assign DATA_OUT = data_reg[0];

    always_comb begin
        BUSY       = 1'b0;
        n_state    = state;
        n_wait_cnt = wait_cnt;
        n_bit_cnt  = bit_cnt;
        n_data_reg = data_reg;
        if (state == STATE_IDLE) begin
            if (WE) begin
                n_state    = STATE_SEND;
                n_data_reg = {1'b1, DATA_IN, 1'b0};
            end
        end else if (state == STATE_SEND) begin
            BUSY       = 1'b1;
            if (wait_cnt == WAIT_DIV - 1) begin
                if (bit_cnt == 4'd9) begin
                    n_state    = STATE_IDLE;
                    n_wait_cnt = 0;
                    n_bit_cnt  = 4'd0;
                end else begin
                    n_data_reg = {1'b1, data_reg[9:1]};
                    n_wait_cnt = 0;
                    n_bit_cnt  = bit_cnt + 1'b1;
                end
            end else begin
                n_wait_cnt = wait_cnt + 1'b1;
            end
        end
    end

    always_ff @ (posedge CLK) begin
        if (RST) begin
            state    <= STATE_IDLE;
            wait_cnt <= 0;
            bit_cnt  <= 4'd0;
            data_reg <= 10'h3ff;
        end else begin
            state    <= n_state;
            wait_cnt <= n_wait_cnt;
            bit_cnt  <= n_bit_cnt;
            data_reg <= n_data_reg;
        end
    end
    
endmodule

`default_nettype wire
