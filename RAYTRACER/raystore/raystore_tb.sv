`default_nettype none

module raystore_tb;

	rs_to_trav_t rstt1;
	logic rstt1_valid,
	      rstt1_stall;

	rs_to_trav_t rstt2;
	logic rstt2_valid,
	      rstt2_stall;

	rs_to_icache_t rstic;
	logic rstic_valid,
	      rstic_stall;

	trav_to_rs_t ttrs1;
	logic ttrs1_re,
	      ttrs1_stall;

	trav_to_rs_t ttrs2;
	logic ttrs2_re,
	      ttrs2_stall;

	lcache_to_rs_t lctrs;
	logic lctrs_re,
	      lctrs_stall;

	logic clk, rst;

	raystore rs(.*);

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		#1;
		forever #1 clk = ~clk;
	end

	integer i;

	assign {ttrs1_re, ttrs2_re, lctrs_re} = i;

	initial begin
		ttrs1 <= 'b0;
		ttrs2 <= 'b0;
		lctrs <= 'b0;

		$monitor("{ttrs1_re, ttrs2_re, lctrs_re}: %b%b%b {rstt1_valid, rstt2_valid, rstic_valid}: %b%b%b rr: %b",
		ttrs1_re, ttrs2_re, lctrs_re, rstt1_valid, rstt2_valid, rstic_valid, rs.rr);

		for(i=0; i<8; i++)
			@(posedge clk);

		@(posedge clk);
		i = 3'b111;
		@(posedge clk);
		i = 3'b111;
		@(posedge clk);
		i = 3'b111;

//		repeat(10) @(posedge clk);
		@(posedge clk);
		$finish;
	end

endmodule: raystore_tb
