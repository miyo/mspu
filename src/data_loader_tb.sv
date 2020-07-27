`default_nettype none

module data_loader_tb();

    localparam CORES = 4;
    localparam INSN_DEPTH = 12;
    localparam DMEM_DEPTH = 14;

    logic clk;
    logic reset;

    logic kick;
    logic busy;
    logic [63:0] memory_base_addr;
    logic [$clog2(CORES)-1:0] target_core;

    logic [$clog2(CORES)+INSN_DEPTH+2-1:0] insn_addr;
    logic [31:0] insn_dout;
    logic insn_we;
     
    logic [$clog2(CORES)+DMEM_DEPTH+2-1:0] data_addr;
    logic [31:0] data_dout;
    logic data_we;

    logic           m0_waitrequest;
    logic [512-1:0] m0_readdata;
    logic           m0_readdatavalid;
    logic [3-1:0]   m0_burstcount;
    logic [512-1:0] m0_writedata;
    logic [64-1:0]  m0_address;
    logic           m0_write;
    logic           m0_read;
    logic [63:0]    m0_byteenable;

    data_loader#(.CORES(CORES), .INSN_DEPTH(INSN_DEPTH), .DMEM_DEPTH(DMEM_DEPTH))
    data_loader_i(.clk(clk),
		  .reset(reset),
		  .kick(kick),
		  .busy(busy),
		  .memory_base_addr(memory_base_addr),
		  .target_core(target_core),
		  .insn_addr(insn_addr),
		  .insn_dout(insn_dout),
		  .insn_we(insn_we),
		  .data_addr(data_addr),
		  .data_dout(data_dout),
		  .data_we(data_we),
		  .m0_waitrequest(m0_waitrequest), 
		  .m0_readdata(m0_readdata),
		  .m0_readdatavalid(m0_readdatavalid),
		  .m0_burstcount(m0_burstcount),
		  .m0_writedata(m0_writedata),
		  .m0_address(m0_address),
		  .m0_write(m0_write),
		  .m0_read(m0_read),
		  .m0_byteenable(m0_byteenable),
		  .m0_debugaccess()
		  );

    logic [31:0] state_counter = 0;

    initial begin
	clk = 0;
    end

    always begin
	clk = ~clk;
	#5;
    end

    always_ff @(posedge clk) begin
	case(state_counter)

	    0: begin
		reset <= 0;
		state_counter <= state_counter + 1;
	    end
	    5: begin
		state_counter <= state_counter + 1;
		reset <= 1;
	    end
	    10: begin
		state_counter <= state_counter + 1;
		reset <= 0;
	    end
	    15: begin
		state_counter <= state_counter + 1;
		kick <= 1;
		memory_base_addr <= 64'h00000001_00000000;
		target_core <= 1;
	    end
	    16: begin
		state_counter <= state_counter + 1;
		kick <= 0;
	    end
	    17: begin
		if(busy == 0) begin
		    state_counter <= state_counter + 1;
		end
	    end

	    18: begin
		state_counter <= state_counter + 1;
		kick <= 1;
		memory_base_addr <= 64'h00000002_00000000;
		target_core <= 3;
	    end
	    19: begin
		state_counter <= state_counter + 1;
		kick <= 0;
	    end
	    20: begin
		if(busy == 0) begin
		    state_counter <= state_counter + 1;
		end
	    end

	    21: begin
		$finish;
	    end

	    default: begin
		state_counter <= state_counter + 1;
	    end

	endcase // case (state_counter)

    end

    assign m0_readdatavalid = 1;
    assign m0_waitrequest = 0;
    assign m0_readdata = {64'h01234567_89abcdef,
			  64'h01234567_89abcdef,
			  64'h01234567_89abcdef,
			  64'h01234567_89abcdef,
			  64'h01234567_89abcdef,
			  64'h01234567_89abcdef,
			  64'h01234567_89abcdef,
			  64'h01234567_89abcdef};

endmodule
