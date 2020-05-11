module instruction_fetch#(parameter START_ADDR = 32'h8000_0000)
  (
   // system
   input wire clk,
   input wire reset,
   input wire run,
   input wire stall,
   input wire stall_mem,
   input wire [31:0] insn_addr,
   input wire [31:0] insn_din,
   input wire        insn_we,

   // input
   input wire [31:0] pc_in,
   input wire pc_in_en,
   // output
   output logic [31:0] pc_out,
   output wire [31:0] insn,
   output logic run_out
   );

    // program counter
    logic [31:0] pc = START_ADDR;
    /* verilator lint_off UNUSED */
    logic [31:0] pc_prev = START_ADDR;
    /* verilator lint_on UNUSED */
    logic [31:0] npc;

    logic [1:0] state = 0;
    logic stall_mem_d;
    logic [1:0] stall_mem_cnt = 0;

    always_ff @(posedge clk) begin

	case(state)
	    0: begin
		if(run)
		  state <= state +1;
	    end
	    1: begin
    		run_out <= 1'b1;
		stall_mem_d <= stall_mem;
		if(!stall & !stall_mem) begin
		    pc_out <= pc;
		    pc <= npc;
		    pc_prev <= pc;
		end else begin
		    if(stall_mem)
		      stall_mem_cnt <= 1;
		    state <= state + 1;
		end
	    end

	    2: begin
		if(stall_mem_d) begin
		    if(stall_mem_cnt > 0) begin
			stall_mem_cnt <= stall_mem_cnt - 1;
		    end else begin
			stall_mem_d <= 0;
			state <= 1;
			pc <= npc;
			pc_out <= pc;
		    end
		end else if(pc_in_en == 1) begin
		    state <= state + 1;
		    pc <= npc;
		end
	    end

	    3: begin
		state <= 1;
		pc_out <= pc;
	    end

	    default: begin
		state <= 0;
	    end

	endcase // case (state)

    end

    always_comb begin
	if(reset == 1 || run == 0)
	  npc = START_ADDR;
	else if(pc_in_en == 1)
	  npc = pc_in;
	else
	  npc = pc + 4;
    end

    
    instruction_memory#(.DEPTH(12))
    imem_i(.clk(clk),
	   .reset(reset),
	   .pc(pc),
	   .insn(insn),
	   .addr(insn_addr),
	   .din(insn_din),
	   .we(insn_we)
	   );

endmodule // instruction_fetch
