`default_nettype none

module decoder
  (
   // system
   input wire clk,
   input wire reset,
   input wire run,
   input wire stall,

   // input
   input wire [31:0] insn,
   input wire [31:0] pc,
   input wire reg_we_in,
   input wire [4:0] rd_in,
   input wire [31:0] reg_wdata,

   // output
   output logic branch_en, jal_en, jalr_en,
   output logic mem_re,
   output logic mem_we,
   output logic mem_to_reg_out,
   output logic [3:0] alu_op,
   output logic [3:0] mul_op,
   output logic [3:0] div_op,
   output logic [31:0] alu_a,
   output logic [31:0] alu_b,
   output logic [4:0] alu_rs1,
   output logic [4:0] alu_rs2,
   output logic [1:0] alu_bytes,
   output logic reg_we_out,
   output logic [31:0] imm,
   output logic [4:0] rd_out,
   output logic unsigned_flag,

   output logic [31:0] mem_dout,
   output logic [31:0] pc_out,

   output logic run_out,
   output logic mem_hazard,
   output logic div_hazard,
   input wire div_ready
   );

`include "core.svh"

    logic alu_src_a, alu_src_b;
    logic [4:0] rs1, rs2;
    logic [31:0] imm_value;
    logic [31:0] reg_a, reg_b;

    logic branch_en_i, jal_en_i, jalr_en_i;
    logic mem_re_i;
    logic mem_we_i;
    logic mem_to_reg_out_i;
    logic [3:0] alu_op_i;
    logic [3:0] mul_op_i;
    logic [3:0] div_op_i;
    logic [1:0] alu_bytes_i;
    logic reg_we_out_i;
    logic [4:0] rd_out_i;
    logic unsigned_flag_i;

    /* verilator lint_off UNUSED */
    (* mark_debug *) logic [31:0] emit_insn;
    (* mark_debug *) logic [31:0] emit_pc_out;
    /* verilator lint_on UNUSED */

    logic [1:0] state = 0;

    logic [1:0] stall_mem = 0;
    logic [1:0] stall_ctrl = 0;
    logic [1:0] stall_div = 0;

    assign mem_hazard = mem_to_reg_out_i && (state == 0);
    assign div_hazard = (div_op_i != DIV_NOP) && (state == 0);

    always_ff @(posedge clk) begin
	if(reset) begin
	    emit_insn      <= 32'h0;
    	    emit_pc_out    <= 32'h0;
    	    imm            <= 32'h0;
    	    pc_out         <= 32'h0;
    	    alu_a          <= 32'd0;
    	    alu_b          <= 32'd0;
    	    mem_dout       <= 32'h0;
	    alu_rs1        <= 5'd0;
	    alu_rs2        <= 5'd0;
    	    branch_en      <= 1'b0;
    	    jal_en         <= 1'b0;
    	    jalr_en        <= 1'b0;
    	    mem_re         <= 1'b0;
    	    mem_we         <= 1'b0;
    	    mem_to_reg_out <= 1'b0;
    	    alu_op         <= 4'b0000;
    	    mul_op         <= 4'b0000;
    	    div_op         <= 4'b0000;
    	    alu_bytes      <= 2'b00;
    	    reg_we_out     <= 1'b0;
    	    rd_out         <= 5'd0;
	    unsigned_flag  <= 1'b0;
	end else begin
    	    run_out <= run;
	    case(state)
		0: begin
		    if(run && !stall) begin
			emit_insn      <= insn;
    			imm            <= imm_value;
    			pc_out         <= pc;
    			emit_pc_out    <= pc;
    			alu_a          <= alu_src_a == 0 ? reg_a : pc;
    			alu_b          <= alu_src_b == 0 ? reg_b : imm_value;
    			mem_dout       <= reg_b;
			alu_rs1        <= alu_src_a == 0 ? rs1 : 0;
			alu_rs2        <= alu_src_b == 0 ? rs2 : 0;
    			branch_en      <= branch_en_i;
    			jal_en         <= jal_en_i;
    			jalr_en        <= jalr_en_i;
    			mem_re         <= mem_re_i;
    			mem_we         <= mem_we_i;
    			mem_to_reg_out <= mem_to_reg_out_i;
    			alu_op         <= alu_op_i;
    			mul_op         <= mul_op_i;
    			div_op         <= div_op_i;
    			alu_bytes      <= alu_bytes_i;
    			reg_we_out     <= reg_we_out_i;
    			rd_out         <= rd_out_i;
			unsigned_flag  <= unsigned_flag_i;
			
    			if(branch_en_i | jal_en_i | jalr_en_i) begin
			    state <= state + 1;
			    stall_ctrl <= 3;
    			end if(mem_to_reg_out_i) begin
			    state <= state + 1;
			    stall_mem <= 1;
    			end if(div_op_i != 0) begin
			    state <= state + 1;
			    stall_div <= 1;
			end
			
		    end else begin
			
		    end
		end
		1: begin
    		    rd_out         <= 0;
    		    mem_to_reg_out <= 0;
    		    branch_en      <= 0;
    		    jal_en         <= 0;
    		    jalr_en        <= 0;
		    unsigned_flag  <= 0;
		    if(stall_mem > 0) begin
			stall_mem <= stall_mem -1;
		    end else if(stall_ctrl > 0) begin
			stall_ctrl <= stall_ctrl - 1;
		    end else if(stall_div > 0) begin
			if(div_ready) begin
			    stall_div <= 0;
			    state <= 0;
			end
		    end else begin
			state <= 0;
		    end
		end
		
		default: begin
		    state <= 0;
		end
	    endcase // case (state)
	end
    end

    control control_i(.insn(insn),
		      .branch_en(branch_en_i),
		      .jal_en(jal_en_i),
		      .jalr_en(jalr_en_i),
		      .mem_re(mem_re_i),
		      .mem_we(mem_we_i),
		      .mem_to_reg(mem_to_reg_out_i),
		      .alu_op(alu_op_i),
		      .mul_op(mul_op_i),
		      .div_op(div_op_i),
		      .alu_src_a(alu_src_a),
		      .alu_src_b(alu_src_b),
		      .alu_bytes(alu_bytes_i),
		      .reg_we(reg_we_out_i),
		      .imm(imm_value),
		      .rs1(rs1),
		      .rs2(rs2),
		      .rd(rd_out_i),
		      .unsigned_flag(unsigned_flag_i)
		      );

    registers rf_i(.clk(clk),
		   .reset(reset),
		   .run(run),
		   .raddr_a(rs1),
		   .raddr_b(rs2),
		   .rdata_a(reg_a),
		   .rdata_b(reg_b),
		   .waddr(rd_in),
		   .wdata(reg_wdata),
		   .reg_we(reg_we_in)
		   );

endmodule // decoder

`default_nettype wire
