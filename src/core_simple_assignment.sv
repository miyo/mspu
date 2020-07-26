`default_nettype none

module core_simple_assignment#(parameter CORES=4)
  (
   input wire clk,
   input wire reset,

   output wire core_valid,
   output wire [$clog2(CORES)-1:0] core_id,
   input wire core_request,
   input wire core_release,
   input wire [$clog2(CORES)-1:0] released_core_id
   );

    logic core_request_d;
    logic core_release_d;

    logic empty_flag;
    logic [$clog2(CORES)-1:0] next_core_id;
    logic [$clog2(CORES)-1:0] wait_core_id;

    logic core_valid_i = (next_core_id != wait_core_id) | empty_flag;
    assign core_valid = core_valid_i;
    assign core_id = next_core_id[$clog2(CORES)-1:0];

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    core_request_d <= 0;
	    core_release_d <= 0;
	    next_core_id <= 0;
	    wait_core_id <= 0;
	    empty_flag <= 1;
	end else begin
	    core_request_d <= core_request;
	    core_release_d <= core_release;
	    if(core_valid_i == 1 && core_request == 1 && core_request_d == 0) begin
		empty_flag <= 0;
		next_core_id <= next_core_id + 1;
	    end
	    if(core_release == 1 && core_release_d == 0) begin
		wait_core_id <= wait_core_id + 1;
		if(wait_core_id + 1 == next_core_id) begin
		    empty_flag <= 1;
		end
	    end
	end
    end

endmodule // core_simple_assignment

`default_nettype wire
