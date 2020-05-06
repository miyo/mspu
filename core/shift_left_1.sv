`default_nettype none

module shift_left_1(
		    input wire [31:0] d,
		    output wire [31:0] q
		    );

    //assign q = {d[30:0], 1'b0};
    assign q = d;

endmodule // shift_left_1

`default_nettype wire
