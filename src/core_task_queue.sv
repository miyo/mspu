`default_nettype none

module core_task_queue(parameter CORES=4)
  (
   input wire clk,
   input wire reset,

   input wire [$clog2(CORES)-1:0] enqueue_id,
   input wire enqueue_valid,

   output wire [$clog2(CORES)-1:0] current_id,
   output wire current_valid,

   input wire current_consume
   );

    logic [$clog2(CORES)+1-1:0] mem_raddr, mem_waddr;
    logic [$clog2(CORES)-1:0] mem_dout, mem_din;
    logic mem_we;
    
    simple_dualportram#(.WIDTH($clog2(CORES)), .DEPTH($clog2(CORES)+1))
    mem_i(.clk(clk), .reset(reset), .length(),
	  .raddress(mem_raddr), .dout(mem_dout), .oe(1),
	  .waddress(mem_waddr), .din(mem_din), .we(mem_we));

    logic enqueue_valid_d;
    logic current_consume_d;

    logic current_valid_i = mem_raddr != mem_waddr;
    assign current_valid == current_valid_i;

    assign current_id = mem_dout;

    logic [$clog2(CORES)+1-1:0] cur_waddr;
    
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    mem_raddr <= 0;
	    mem_waddr <= 0;
	    cur_waddr <= 0;
	    mem_we <= 0;
	    enqueue_valid_d <= 0;
	    current_consume_d <= 0;
	end else begin
	    enqueue_valid_d <= enqueue_valid;
	    current_consume_d <= current_consume;
	    if(current_valid_i == 1 && current_consume == 1 && current_consume_d == 0) begin
		mem_raddr <= mem_raddr + 1;
	    end
	    if(enqueue_valid == 1 && enqueue_valid_d == 0) begin
		mem_we <= 1;
		mem_waddr <= cur_waddr;
		mem_din <= enqueue_id;
		cur_waddr <= cur_waddr + 1;
	    end else begin
		mem_we <= 0;
	    end
	end
    end

endmodule // core_task_queue

`default_nettype wire
