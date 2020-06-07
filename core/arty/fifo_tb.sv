`default_nettype none

module fifo_tb();

    logic clk;
    logic reset = 1'b1;

    initial begin
	clk <= 1'b0;
    end

    always 
      #5  clk = ~clk;

    logic [7:0] counter = 8'd0;
    always_ff @(posedge clk) begin
	counter <= counter + 1;
	if(counter == 20)
	  reset <= 1'b0;
    end

    logic rd_en, wr_en;
    logic [31:0] dout, din;
    logic full, empty, valid;

    fifo_generator_0 fifo_i (.clk(clk),     // input wire clk
			     .srst(reset),  // input wire srst
			     .din(din),     // input wire [31 : 0] din
			     .wr_en(wr_en), // input wire wr_en
			     .rd_en(rd_en), // input wire rd_en
			     .dout(dout),   // output wire [31 : 0] dout
			     .full(full),   // output wire full
			     .empty(empty), // output wire empty
			     .valid(valid)
			     );

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
	    wr_en <= 0;
	    din <= 32'd0;
	end else begin
	    //80000000 <_start>:
	    //80000000:	f00002b7          	lui	t0,0xf0000
	    //80000004:	0002a503          	lw	a0,0(t0) # f0000000 <FIFO_DOUT_ADDR+0xfffffff8>
	    //80000008:	0002a503          	lw	a0,0(t0)
	    //8000000c:	0002a503          	lw	a0,0(t0)
	    //80000010:	f00002b7          	lui	t0,0xf0000
	    //80000014:	00828293          	addi	t0,t0,8 # f0000008 <FIFO_DOUT_ADDR+0x0>
	    //80000018:	00a2a023          	sw	a0,0(t0)
	    //8000001c:	00a2a023          	sw	a0,0(t0)
	    //80000020:	00a2a023          	sw	a0,0(t0)
	    //80000024 <halt>:
	    //80000024:	0000006f          	j	80000024 <halt>

	    case(state)
		0: state <= state + 1;
		1: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'hf00002b7;
		    insn_addr <= 0;
		    data_we   <= 0;
		    wr_en <= 1;
		    din <= 32'hdeadbeef;
		end
		2: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h0002a503;
		    insn_addr <= 4;
		    wr_en <= 1;
		    din <= 32'habadcafe;
		end
		3: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h0002a503;
		    insn_addr <= 8;
		    wr_en <= 1;
		    din <= 32'h34343434;
		end
		4: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h0002a503;
		    insn_addr <= 12;
		    wr_en <= 1;
		    din <= 32'ha5a5a5a5;
		end
		5: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'hf00002b7;
		    insn_addr <= 16;
		    wr_en <= 0;
		end
		6: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00828293;
		    insn_addr <= 20;
		end
		7: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00a2a023;
		    insn_addr <= 24;
		end
		8: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00a2a023;
		    insn_addr <= 28;
		end
		9: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h00a2a023;
		    insn_addr <= 32;
		end
		10: begin
		    state <= state + 1;
		    insn_we   <= 1;
		    insn_din  <= 32'h0000806f; // j halt
		    insn_addr <= 36;
		end
		11 :begin
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

    logic fifo_we;
    logic [31:0] fifo_dout;
   
    core core_i(.clk(clk),
		.reset(reset),
		.run(run),
   
		.insn_addr(insn_addr),
		.insn_din(insn_din),
		.insn_we(insn_we),

		.data_addr(data_addr),
		.data_din(data_din),
		.data_we(data_we),

		.uart_dout(),
		.uart_we(),

		.fifo_count(32'd0),
		.fifo_din(dout),
		.fifo_re(rd_en),
		.fifo_dout(fifo_dout),
		.fifo_we(fifo_we)
		);

endmodule // fifo_tb

`default_nettype wire
