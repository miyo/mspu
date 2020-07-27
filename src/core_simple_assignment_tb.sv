module core_simple_assignment_tb#(parameter CORES=4);

    logic clk;
    logic reset;

    logic core_valid;
    logic [$clog2(CORES)-1:0] core_id;
    logic core_request;
    logic core_release;
    logic [$clog2(CORES)-1:0] released_core_id;

    initial begin
	clk = 0;
    end

    always begin
	clk = ~clk;
	#5;
    end

    logic [31:0] counter = 0;

    always_ff @(posedge clk) begin

	case(counter)

	    0: begin
		counter <= counter + 1;
		reset <= 1;
		core_request <= 0;
		core_release <= 0;
		released_core_id <= 0;
	    end

	    9: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    20: begin
		counter <= counter + 1;
		core_request <= 1;
	    end
	    22: begin
		counter <= counter + 1;
		core_request <= 1;
	    end
	    24: begin
		counter <= counter + 1;
		core_request <= 1;
	    end

	    30: begin
		counter <= counter + 1;
		core_release <= 1;
	    end
	    32: begin
		counter <= counter + 1;
		core_release <= 1;
	    end

	    40: begin
		counter <= counter + 1;
		core_request <= 1;
	    end
	    42: begin
		counter <= counter + 1;
		core_request <= 1;
	    end
	    44: begin
		counter <= counter + 1;
		core_request <= 1;
	    end

	    50: begin
		counter <= counter + 1;
		core_release <= 1;
	    end
	    52: begin
		counter <= counter + 1;
		core_release <= 1;
	    end
	    54: begin
		counter <= counter + 1;
		core_release <= 1;
	    end
	    56: begin
		counter <= counter + 1;
		core_release <= 1;
	    end

	    60: begin
		counter <= counter + 1;
		core_request <= 1;
	    end

	    200: begin
		$finish;
	    end

	    default: begin
		counter <= counter + 1;
		core_request <= 0;
		core_release <= 0;
	    end
	endcase;

    end

    core_simple_assignment#(.CORES(4))
    core_simple_assignment_i(
			     .clk(clk),
			     .reset(reset),
			     .core_valid(core_valid),
			     .core_id(core_id),
			     .core_request(core_request),
			     .core_release(core_release),
			     .released_core_id(released_core_id));

endmodule // core_simple_assignment_tb

