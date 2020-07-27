`default_nettype none

module core_simple_queue#(parameter CORES=4)
  (
   input wire clk,
   input wire reset,

   input wire [$clog2(CORES)-1:0] enqueue_id,
   input wire enqueue_valid,

   output wire [$clog2(CORES)-1:0] current_id,
   output wire current_valid,

   input wire current_consume
   );

    logic enqueue_valid_d;
    logic current_consume_d;

    logic [$clog2(CORES)-1:0] queued_id;
    logic [7:0] queued_num;

    logic current_valid_i;
    assign current_valid_i = queued_num > 0;
    assign current_valid = current_valid_i;

    assign current_id = queued_id - (queued_num - 1);

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    enqueue_valid_d <= 0;
	    current_consume_d <= 0;
	    queued_num <= 0;
	end else begin
	    enqueue_valid_d <= enqueue_valid;
	    current_consume_d <= current_consume;
	    if(enqueue_valid == 1 && enqueue_valid_d == 0) begin
		queued_id <= enqueue_id;
		queued_num <= queued_num + 1;
	    end
	    if(current_valid_i == 1 && current_consume == 1 && current_consume_d == 0) begin
		queued_num <= queued_num - 1;
	    end
	end
    end

endmodule // core_task_queue

`default_nettype wire
