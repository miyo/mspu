module addr_calc
  (
   input wire [31:0] pc,
   input wire [31:0] imm,
   input wire [31:0] alu_result,
   input wire branch_en,
   input wire jal_en,
   input wire jalr_en,

   output logic [31:0] addr_out,
   output logic        addr_out_en
   );

    logic [31:0] npc;
    logic npc_en;

    always_comb begin
	addr_out = npc;
	addr_out_en = npc_en;
    end
    
    always_comb begin
	if(branch_en) begin
	    npc_en = 1'b1;
	    if(alu_result[0])
	      npc = pc + imm;
	    else
	      npc = pc + 4;
	end else if(jal_en) begin
	    npc = pc + imm;
	    npc_en = 1'b1;
	end else if(jalr_en) begin
	    npc = alu_result + 4;
	    npc_en = 1'b1;
	end else begin
	    npc_en = 1'b0;
	    npc = 0;
	end
    end

endmodule // addr_calc
