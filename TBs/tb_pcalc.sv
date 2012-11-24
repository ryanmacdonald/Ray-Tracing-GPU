



module tb_pcalc;

	
	ray_vec_t vec;
	float_t t;
	logic v0, v1, v2;
	logic clk, rst;
	vector_t pos;

	logic test;


	pcalc pc(.*);

	logic[1:0] cnt, ncnt;
	assign ncnt = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(ncnt),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

	initial begin

	
		rst <= 0; clk <= 1;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		@(posedge clk);

		pqwop($shortrealtobits(0.0),$shortrealtobits(0.0),$shortrealtobits(0.0), //org
		      $shortrealtobits(1.0),$shortrealtobits(1.0),$shortrealtobits(1.0), //dir
		      $shortrealtobits(1.0));						 //t

		pqwop($shortrealtobits(1.0),$shortrealtobits(1.0),$shortrealtobits(1.0),
		      $shortrealtobits(1.0),$shortrealtobits(1.0),$shortrealtobits(1.0),
		      $shortrealtobits(1.0));

		pqwop($shortrealtobits(3.0),$shortrealtobits(2.0),$shortrealtobits(1.0),
		      $shortrealtobits(1.0),$shortrealtobits(1.0),$shortrealtobits(1.0),
		      $shortrealtobits(0.0));

		pqwop($shortrealtobits(1.0),$shortrealtobits(2.0),$shortrealtobits(3.0),
		      $shortrealtobits(1.0),$shortrealtobits(2.0),$shortrealtobits(3.0),
		      $shortrealtobits(2.0));

		$finish;
	end

	always #5 clk = ~clk;


	task pqwop(float_t or_x, or_y, or_z,
		   float_t dr_x, dr_y, dr_z,
		   float_t tm);

		@(posedge clk) begin
		vec.origin.x <= or_x; vec.origin.y <= or_y; vec.origin.z <= or_z;
		vec.dir.x <= dr_x; vec.dir.y <= dr_y; vec.dir.z <= dr_z;
		t <= tm;
		test <= 1;
		end

		@(posedge clk);
		test <= 0;

		repeat(50) @(posedge clk);

	endtask


endmodule: tb_pcalc
