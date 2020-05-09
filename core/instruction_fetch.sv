module instruction_fetch#(parameter START_ADDR = 32'h8000_0000)
  (
   // system
   input wire clk,
   input wire reset,
   input wire run,
   input wire stall,
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
    logic [31:0] pc_prev = START_ADDR;
    logic [31:0] npc;

    always_ff @(posedge clk) begin
	if(run && !stall) begin
	    pc_out <= pc;
	    pc <= npc;
    	    run_out <= 1'b1;
	end else begin
    	    run_out <= 1'b0;
	end
    end

    always_comb begin
	if(reset == 1 || run == 0)
	  npc = START_ADDR;
	else if(pc_in_en)
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
