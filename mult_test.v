`default_nettype none

// meant to test how many multiplies we can fit on the board

module mult_pipeline #(parameter W=24, S=10) (
	output wire [23:0] cOut,
	input wire [23:0] inA,
	input wire clk, rst
);

	wire [W-1:0] c [S-1:0];

	mult_stage #(W) first_mult(.c(c[0]), .a(inA), .b(inA), .clk(clk), .rst(rst));

	genvar i;

	generate
		for(i=1; i<S; i = i+1) begin
			mult_stage #(W) mults (.c(c[i]), .a(c[i-1]), .b(inA), .clk(clk), .rst(rst));
		end
	endgenerate
		


endmodule

module mult_stage #(parameter W=8) (
	output wire [W-1:0] c,
	input wire [W-1:0] a, b,
	input wire clk, rst
);
	wire [W-1:0] a_mult_b;

	assign a_mult_b = a * b;
	register #(W) regC (.q(c), .d(a_mult_b), .clk(clk), .rst(rst), .en(1'b1));

endmodule

module register #(parameter W=8) (
	output reg [W-1:0] q,
	input wire [W-1:0] d,
	input wire clk, rst, en
);

	always @(posedge clk, posedge rst) begin
		if(rst)
			q <= 0;
		else if(en)
			q <= d;
	end

endmodule
