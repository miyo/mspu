module registers
  (
   input wire clk,
   input wire reset,
   input wire run,

   input  wire [4:0]  raddr_a,
   input  wire [4:0]  raddr_b,
   output logic [31:0] rdata_a,
   output logic [31:0] rdata_b,
   
   input wire [4:0]  waddr,
   input wire [31:0] wdata,
   input wire reg_we
   );

    logic [31:0] mem [31:0];

    integer i;
    initial begin
	for(i = 0; i < 32; i=i+1) begin
	    mem[i] = 32'd0;
	end
    end

    always_comb begin
	rdata_a = mem[raddr_a];
	rdata_b = mem[raddr_b];
    end

    always @(posedge clk) begin
	if(reset == 0 && run == 1) begin
	    if((reg_we == 1) && (waddr != 0)) begin
		mem[waddr] <= wdata;
	    end
	end
    end

    /* verilator lint_off UNUSED */
    logic [31:0] ra = mem[1]; // Return address
    logic [31:0] sp = mem[2]; // Stack pointer
    logic [31:0] gp = mem[3]; // Global pointer
    logic [31:0] tp = mem[4]; // Thread pointer
    logic [31:0] t0 = mem[5]; // Temporaries
    logic [31:0] t1 = mem[6]; // Temporaries
    logic [31:0] t2 = mem[7]; // Temporaries
    logic [31:0] s0 = mem[8]; // s0/fp saved register/frame pointer
    logic [31:0] s1 = mem[9]; // s1 saved register
    logic [31:0] a0 = mem[10]; // Function arguments/return values
    logic [31:0] a1 = mem[11]; // Function arguments/return values
    logic [31:0] a2 = mem[12]; // Function arguments
    logic [31:0] a3 = mem[13]; // Function arguments
    logic [31:0] a4 = mem[14]; // Function arguments
    logic [31:0] a5 = mem[15]; // Function arguments
    logic [31:0] a6 = mem[16]; // Function arguments
    logic [31:0] a7 = mem[17]; // Function arguments
    logic [31:0] s2 = mem[18]; // Saved register
    logic [31:0] s3 = mem[19]; // Saved register
    logic [31:0] s4 = mem[20]; // Saved register
    logic [31:0] s5 = mem[21]; // Saved register
    logic [31:0] s6 = mem[22]; // Saved register
    logic [31:0] s7 = mem[23]; // Saved register
    logic [31:0] s8 = mem[24]; // Saved register
    logic [31:0] s9 = mem[25]; // Saved register
    logic [31:0] s10 = mem[26]; // Saved register
    logic [31:0] s11 = mem[27]; // Saved register
    logic [31:0] t3 = mem[28]; // Temporaries
    logic [31:0] t4 = mem[29]; // Temporaries
    logic [31:0] t5 = mem[30]; // Temporaries
    logic [31:0] t6 = mem[31]; // Temporaries
    /* verilator lint_on UNUSED */

endmodule // registers

/*
f0–7 ft0–7 FP temporaries Caller
f8–9 fs0–1 FP saved registers Callee
f10–11 fa0–1 FP arguments/return values Caller
f12–17 fa2–7 FP arguments Caller
f18–27 fs2–11 FP saved registers Callee
f28–31 ft8–11 FP temporaries Caller
 */
