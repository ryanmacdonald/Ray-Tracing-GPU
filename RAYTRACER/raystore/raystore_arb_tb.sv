module raystore_arb_tb;

	parameter N = 4;

	logic clk, rst;

	logic [N-1:0] us_valid;
	logic [N-1:0] us_stall;

	logic [N-1:0] pipe_stall;
	logic [N-1:0] pipe_valid;
	logic [N-1:0] data_sel;

	logic [1:0] mux_sel0;
	logic [1:0] mux_sel1;
	logic [$clog2(N)-1:0] rrp;
	
	raystore_arb #(.N(N)) rsa(.*);

	integer i;

	assign {us_valid, pipe_stall} = i;

	initial begin

		for(i=0; i < (1<<8) ; i++) begin
			@(posedge clk);
		end

		$finish;
	end

	initial begin
		clk <= 1'b0;
		#1;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		forever #1 clk = ~clk;
	end

	assign rrp = 4'b0000;

/*	always_ff @(posedge clk, posedge rst) begin
		if(rst)
			rrp <= 4'b0000;
		else
			rrp <= rrp + 1'b1;
	end */

endmodule: raystore_arb_tb
