`default_nettype none

module halt_detector
  (
   input wire clk,
   input wire reset,

   input wire run_if,
   input wire [31:0] emit_insn,

   output logic halt_flag
   );

    logic [3:0] halt_counter;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    halt_counter <= 4'b0000;
	    halt_flag <= 0;
	end else begin
	    if(run_if == 1 && emit_insn == 32'h0000006F) begin
		if(halt_counter == 4'b0111) begin
		    halt_flag <= 1; // detected 8-times
		end else begin
		    halt_counter <= halt_counter + 1;
		end
	    end else begin
		halt_counter <= 4'b0000; // cancel
		halt_flag <= 0;
	    end
	end
    end

endmodule // halt_detector

`default_nettype wire
