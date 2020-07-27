module core_simple_queue_tb#(parameter CORES=4);

    logic clk;
    logic reset;

    logic [$clog2(CORES)-1:0] enqueue_id;
    logic enqueue_valid;

    logic [$clog2(CORES)-1:0] current_id;
    logic current_valid;

    logic current_consume;

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
		enqueue_valid <= 0;
		enqueue_id <= 0;
		current_consume <= 0;
	    end

	    9: begin
		counter <= counter + 1;
		reset <= 0;
	    end

	    10: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 0;
	    end
	    12: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 1;
	    end
	    14: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 2;
	    end

	    20: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end
	    22: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end

	    30: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 3;
	    end
	    32: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 0;
	    end
	    34: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 1;
	    end
	    
	    40: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end
	    42: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end
	    44: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end
	    46: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end

	    50: begin
		counter <= counter + 1;
		enqueue_valid <= 1;
		enqueue_id <= 2;
	    end
	    52: begin
		counter <= counter + 1;
		current_consume <= 1;
	    end

	    default: begin
		counter <= counter + 1;
		enqueue_valid <= 0;
		current_consume <= 0;
	    end

	endcase // case (counter)
    end


    core_simple_queue#(.CORES(CORES))
    core_simple_queue_i(
			.clk(clk),
			.reset(reset),
			.enqueue_id(enqueue_id),
			.enqueue_valid(enqueue_valid),
			.current_id(current_id),
			.current_valid(current_valid),
			.current_consume(current_consume));

endmodule // core_simple_queue_tb
