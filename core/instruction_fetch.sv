module instruction_fetch#(parameter START_ADDR = 32'h8000_0000)
  (
   // system
   input wire clk,
   input wire reset,
   input wire run,
   input wire stall,
   input wire stall_mem,
   input wire stall_div,
   input wire div_ready,
   input wire stall_shift,
   input wire shift_ready,
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

    logic [1:0] state;
    logic stall_mem_d, stall_div_d, stall_shift_d;
    logic [1:0] stall_mem_cnt;

    always_ff @(posedge clk) begin

	if(reset == 1) begin
    	    run_out <= 1'b0;
	    pc_out <= 0;
	    stall_div_d <= 0;
	    stall_shift_d <= 0;
	    stall_mem_d <= 0;
	    stall_mem_cnt <= 0;
	    state <= 0;
	    pc <= START_ADDR;
	    pc_prev <= START_ADDR;
	end else begin
	    case(state)
		0: begin
		    if(run) begin
			state <= state +1;
    			//run_out <= 1'b1;
		    end
		    pc <= START_ADDR;
		    pc_prev <= START_ADDR;
    		    run_out <= 1'b0;
		end
		1: begin
    		    run_out <= 1'b1;
		    stall_mem_d <= stall_mem;
		    stall_div_d <= stall_div;
		    stall_shift_d <= stall_shift;
		    if(!stall & !stall_mem & !stall_div & !stall_shift) begin
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
		    end else if(stall_div_d) begin
			if(div_ready) begin
			    stall_div_d <= 0;
			    state <= 1;
			    pc <= npc;
			    pc_out <= pc;
			end
		    end else if(stall_shift_d) begin
			if(shift_ready) begin
			    stall_shift_d <= 0;
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
	    
	end // else: !if(reset == 1)

    end

    always_comb begin
	if(reset == 1 || run_out == 0)
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
