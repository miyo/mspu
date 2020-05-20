module shift
  (
   input wire clk,
   input wire reset,
   input wire kick,
   input wire unsigned_flag,
   input wire lshift,
   input wire [31:0] a,
   input wire [31:0] b,
   output logic ready,
   output logic done,
   output logic [31:0] q
   );

    logic [31:0] b_r;
    logic lshift_r;

    assign ready = (b_r == 0);

    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    b_r <= 0;
	    done <= 0;
	end else begin
	    if(b_r == 0 && kick) begin
		q <= a;
		b_r <= b;
		lshift_r <= lshift;
		done <= 0;
	    end else if(b_r > 0) begin
		b_r <= b_r - 1;
		if(b_r == 1) begin
		    done <= 1;
		end
		if(lshift_r) begin
		    q <= {q[30:0], 1'b0};
		end else begin
		    if(unsigned_flag) begin
			q <= {1'b0, q[31:1]};
		    end else begin
			q <= {q[31], q[31:1]};
		    end
		end
	    end
	end
    end 

endmodule // shift
