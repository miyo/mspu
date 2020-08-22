module div
  (
   input wire clk,
   input wire reset,
   input wire kick,
   input wire unsigned_flag,
   input wire [31:0] dividend,
   input wire [31:0] divider,
   output logic ready,
   output logic ready_pre,
   output logic [31:0] quotient,
   output logic [31:0] remainder
   );

    logic [31:0] quotient_r;
    logic [63:0] dividend_r, divider_r;
    logic [5:0] bits;
    logic negative_flag;
   
    always_comb begin
	quotient = quotient_r;
	remainder = negative_flag ? ~dividend_r[31:0] + 1 : dividend_r[31:0];
	ready = (bits == 6'd0) ? 1'b1 : 1'b0;
	ready_pre = (bits == 6'd1) ? 1'b1 : 1'b0;
    end

    logic [31:0] quotient_tmp;
    logic [63:0] dividend_tmp;
    logic [63:0] diff;
    always_ff @(posedge clk) begin
	if(reset == 1) begin
	    bits <= 6'd0;
	    negative_flag <= 1'b0;
            quotient_r <= 32'd0;
            dividend_r <= 0;
            divider_r <= 0;
	end else if(ready && kick) begin
            bits <= 6'd32;
            quotient_r <= 32'd0;
            dividend_r <= unsigned_flag        ? {32'd0,dividend} :
			  dividend[31] == 1'b0 ? {32'd0,dividend} :
			  {32'd0,~dividend + 1};
            divider_r <= unsigned_flag       ? {1'b0, divider, 31'd0} :
			 divider[31] == 1'b0 ? {1'b0, divider, 31'd0} :
			 {1'b0, ~divider + 1, 31'd0};
	    
            negative_flag <= ~unsigned_flag && (divider[31] ^ dividend[31]);
        
	end else if(bits > 6'd0) begin
            quotient_r <= negative_flag ? ~quotient_tmp + 1 : quotient_tmp;
	    dividend_r <= dividend_tmp;
            divider_r <= {1'b0, divider_r[63:1]}; //  >> 1
            bits <= bits - 1;
	end
    end

    always_comb begin
        diff = dividend_r - divider_r;
        quotient_tmp = {quotient_r[30:0], 1'b0}; // << 1
        if(~diff[63]) begin
	    dividend_tmp = diff;
	    quotient_tmp[0] = 1'd1;
	end else begin
	  dividend_tmp = dividend_r;
        end
    end


endmodule // div

