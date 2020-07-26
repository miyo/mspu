`default_nettype none

module core_manager(parameter CORES=4)
  (
   input wire clk,
   input wire reset,

   output wire init_busy,

   output wire core_valid,
   output wire [$clog2(CORES)-1:0] core_id,
   input wire core_request,
   input wire core_release,
   input wire [$clog2(CORES)-1:0] released_core_id
   );

    logic [$clog2(CORES)+1-1:0] mem_raddr, mem_waddr;
    logic [$clog2(CORES)-1:0] mem_dout, mem_din;
    logic mem_we;
    
    simple_dualportram#(.WIDTH($clog2(CORES)), .DEPTH($clog2(CORES)+1))
    mem_i(.clk(clk), .reset(reset), .length(),
	  .raddress(mem_raddr), .dout(mem_dout), .oe(1),
	  .waddress(mem_waddr), .din(mem_din), .we(mem_we));

    logic [7:0] state_counter = 0;
    logic [$clog2(CORES)+1-1:0] core_counter = 0;
    logic core_request_d;
    logic core_release_d;

    logic core_valid_i = mem_raddr != mem_waddr;
    assign core_valid == core_valid_i;
    assign core_id = mem_dout;

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    state_counter <= 0;
	    init_busy <= 1;
	    mem_raddr <= 0;
	    mem_we <= 0;
	    core_request_d <= 0;
	    core_release_d <= 0;
	end else begin
	    core_request_d <= core_request;
	    core_release_d <= core_release;
	    case(state_counter)
		0: begin
		    init_busy <= 1;
		    state_counter <= state_counter + 1;
		    core_counter <= 0;
		    mem_we <= 0;
		end
		1: begin
		    mem_waddr <= core_counter;
		    mem_din <= core_counter;
		    if(core_counter == CORES) begin
			state_counter <= state_counter + 1;
			mem_we <= 0;
			init_busy <= 0;
		    end else begin
			mem_we <= 1;
			init_busy <= 1;
			core_counter <= core_counter + 1;
		    end
		end
		2: begin
		    if(core_valid_i == 1 && core_request == 1 && core_request_d == 0) begin
			mem_raddr <= mem_raddr + 1;
		    end
		    if(core_release == 1 && core_release_d == 0) begin
			mem_we <= 1;
			mem_waddr <= core_counter;
			mem_din <= released_core_id;
			core_counter <= core_counter + 1;
		    end else begin
			mem_we <= 1;
		    end
		end
	    endcase // case (state_counter)
	end
    end


endmodule // core_manager

`default_nettype wire
