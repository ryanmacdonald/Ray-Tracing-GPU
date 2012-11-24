


module tb_dp();

	
	logic v0, v1, v2;
	logic clk, rst;
	float_t result;
	vector_t a, b;

	dot_prod dp(.*);


	initial begin

		rst <= 0;
		clk <= 1;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		@(posedge clk);

		dotproduct($shortrealtobits(1.0),$shortrealtobits(0.0),$bitstoshortreal(0.0),
			   $shortrealtobits(1.0),$shortrealtobits(0.0),$shortrealtobits(0.0));

		dotproduct($shortrealtobits(1.0),$shortrealtobits(0.0),$shortrealtobits(0.0),
			   $shortrealtobits(2.0),$shortrealtobits(0.0),$shortrealtobits(0.0));

		dotproduct($shortrealtobits(3.0),$shortrealtobits(0.0),$shortrealtobits(0.0),
			   $shortrealtobits(3.0),$shortrealtobits(0.0),$shortrealtobits(0.0));

		$finish;

	end

	always #5 clk = ~clk;

	task dotproduct(float_t ax,ay,az,bx,by,bz);

		@(posedge clk);

		a.x <= ax; a.y <= ay; a.z <= az;
		b.x <= bx; b.y <= by; b.z <= bz;

		repeat(50) @(posedge clk);

	endtask


	logic[1:0] cnt, ncnt;
	assign ncnt = (cnt == 2'd2) ? 2'd0 : cnt + 2'd1;
	ff_ar #(2,0) vr(.q(cnt),.d(ncnt),.clk,.rst);

	assign v0 = (cnt == 2'd0);
	assign v1 = (cnt == 2'd1);
	assign v2 = (cnt == 2'd2);
	

endmodule: tb_dp
