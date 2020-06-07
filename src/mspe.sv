
module mspe#(parameter CORES=4, INSN_DEPTH=12, DMEM_DEPTH=14)
  (
   input logic clk,
   input logic reset,

   input logic [1:0]    csr_address,
   input logic [31:0]   csr_writedata,
   input logic          csr_write,
   output logic [31:0] csr_readdata,
   input logic          csr_read,
   input logic [3:0]    csr_byteenable,
   
   input logic [CORES+INSN_DEPTH+2-1:0] insn_addr,
   input logic [31:0] insn_din,
   input logic        insn_we,

   input logic [CORES+DMEM_DEPTH+2-1:0] data_addr,
   input logic [31:0] data_din,
   input logic        data_we,

   output logic [31:0] uart_dout,
   output logic       uart_we,

   input logic [31:0] fifo_count,
   input logic [31:0] fifo_din,
   output logic fifo_re,
   output logic [31:0] fifo_dout,
   output logic fifo_we
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

   integer j, k, l;
   always_comb begin
      core_insn_addr[31:INSN_DEPTH+2] = 0;
      core_insn_addr[INSN_DEPTH+2-1:2] = insn_addr;
      core_insn_din = insn_din;
      for(j = 0; j < CORES; j = j + 1) begin
	 if(core_insn_addr[CORES+INSN_DEPTH+2-1:INSN_DEPTH+2] == j) begin
	    core_insn_we[j] = insn_we;
	 end else begin
	    core_insn_we[j] = 1'b0;
	 end
      end

      core_data_addr[31:DMEM_DEPTH+2] = 0;
      core_data_addr[DMEM_DEPTH+2-1:2] = data_addr;
      core_data_din = data_din;
      for(k = 0; k < CORES; k = k+ 1) begin
	 if(core_data_addr[CORES+DMEM_DEPTH+2-1:DMEM_DEPTH+2] == k) begin
	    core_data_we[k] = data_we;
	 end else begin
	    core_data_we[k] = 1'b0;
	 end
      end

      for(l = 0; l < CORES; l = l + 1) begin
	 uart_we = 1'b0;
	 uart_dout = 32'h0000_0000;
	 if(core_uart_we[l]) begin
	    uart_we = core_uart_we[l];
	    uart_dout = core_uart_dout[l];
	 end
      end
   end

   genvar i;
   generate
      for(i = 0; i < CORES; i = i + 1) begin : mspe_cores
	 core(
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
      end
   endgenerate

endmodule // mspe
   
