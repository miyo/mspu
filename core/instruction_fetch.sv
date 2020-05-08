module instruction_fetch
  (
   input wire clk,
   input wire reset,
   
   input wire run,
   input wire branch_en,
   input wire [31:0] alu_result,
   input wire jal_en,
   input wire jalr_en,
   input wire [31:0] shift_left_1,

   output wire [31:0] pc_out,
   output wire [31:0] insn,
   input wire [31:0] insn_addr,
   input wire [31:0] insn_din,
   input wire        insn_we
   );

    localparam START_ADDR = 32'h8000_0000;

    // program counter
    logic [31:0] pc = START_ADDR;
    logic [31:0] pc_prev = START_ADDR;

    logic [31:0] npc;
    logic pc_src;
    logic pc_stall;
    always_comb begin
	pc_src = (branch_en & alu_result[0]) | jal_en;
	if(reset == 1'b1 || run == 1'b0)
	  npc = START_ADDR;
	else if(pc_src)
	  npc = pc + shift_left_1;
	else if(jalr_en)
	  npc = alu_result + 4;
//	else if(pc_stall == 1'b1)
//	  npc = pc;
	else
	  npc = pc + 4;
    end

    always @(posedge clk) begin
	pc <= npc;
	pc_prev <= pc;
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
