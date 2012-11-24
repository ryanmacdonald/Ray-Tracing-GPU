


module tb_refl;


	vector_t N, raydir;
	logic v0, v1, v2;
	logic clk, rst;
	vector_t reflected;

	logic[1:0] cnt, ncnt;
	assign ncnt = (cnt == 2'd2) ? 2'd0 : cnt + 2'd1;
	ff_ar #(2,0) v(.q(cnt),.d(ncnt),.clk,.rst);

	assign v0 = (cnt == 2'd0);
	assign v1 = (cnt == 2'd1);
	assign v2 = (cnt == 2'd2);

	reflector refl(.*);


	initial begin

		clk <= 1; rst <= 0;
	 	@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;

		// Expecting a reflection of (1,1,0)
		rr(0.0,1.0,0.0,			//N
		   1.0,-1.0,0.0);		//ray

		// Same thing, only (2,2,0)
		rr(0.0,1.0,0.0,
		   2.0,-2.0,0.0);

		// Expecting a reflection of (1,-1)
		rr(1.0,0.0,0.0,
		   -1.0,-1.0,0.0);

		// Expecting a reflection of (-1,-2)
		rr(1.0,1.0,0.0,
		   1.0,0.0,0.0);

		// Expecting a reflection of (y,z) = (0,1)
		rr(0.0,0.0,1.0,
		   0.0,0.0,-1.0);

		$finish;

	end


	always #5 clk = ~clk;


	task rr(shortreal nx, ny, nz,
		shortreal rx, ry, rz);

		N.x <= $shortrealtobits(nx);
		N.y <= $shortrealtobits(ny); 
		N.z <= $shortrealtobits(nz);
		raydir.x <= $shortrealtobits(rx); 
		raydir.y <= $shortrealtobits(ry); 
		raydir.z <= $shortrealtobits(rz);

		repeat(100) @(posedge clk);
	
	endtask





endmodule: tb_refl
