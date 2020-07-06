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
    logic [31:0] ra;
    logic [31:0] sp;
    logic [31:0] gp;
    logic [31:0] tp;
    logic [31:0] t0,t1,t2,t3,t4,t5,t6;
    logic [31:0] s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11;
    logic [31:0] a0,a1,a2,a3,a4,a5,a6,a7;

    always_comb begin
	ra = mem[1]; // Return address
	sp = mem[2]; // Stack pointer
	gp = mem[3]; // Global pointer
	tp = mem[4]; // Thread pointer
	t0 = mem[5]; // Temporaries
	t1 = mem[6]; // Temporaries
	t2 = mem[7]; // Temporaries
	s0 = mem[8]; // s0/fp saved register/frame pointer
	s1 = mem[9]; // s1 saved register
	a0 = mem[10]; // Function arguments/return values
	a1 = mem[11]; // Function arguments/return values
	a2 = mem[12]; // Function arguments
	a3 = mem[13]; // Function arguments
	a4 = mem[14]; // Function arguments
	a5 = mem[15]; // Function arguments
	a6 = mem[16]; // Function arguments
	a7 = mem[17]; // Function arguments
	s2 = mem[18]; // Saved register
	s3 = mem[19]; // Saved register
	s4 = mem[20]; // Saved register
	s5 = mem[21]; // Saved register
	s6 = mem[22]; // Saved register
	s7 = mem[23]; // Saved register
	s8 = mem[24]; // Saved register
	s9 = mem[25]; // Saved register
	s10 = mem[26]; // Saved register
	s11 = mem[27]; // Saved register
	t3 = mem[28]; // Temporaries
	t4 = mem[29]; // Temporaries
	t5 = mem[30]; // Temporaries
	t6 = mem[31]; // Temporaries
    end
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
