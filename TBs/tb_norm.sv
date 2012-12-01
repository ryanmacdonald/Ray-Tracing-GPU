



module tb_norm;

	vector_t in;
	logic v0, v1, v2;
	logic clk, rst;
	vector_t norm;

	norm n(.*);

	shortreal nx, ny, nz;
	assign nx = $bitstoshortreal(norm.x);
	assign ny = $bitstoshortreal(norm.y);
	assign nz = $bitstoshortreal(norm.z);

	logic[1:0] cnt, ncnt;
	assign ncnt = (cnt == 2'b10) ? 2'b00 : cnt + 1;
	ff_ar #(2,0) cr(.q(cnt),.d(ncnt),.clk,.rst);	

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);


	initial begin

		clk <= 1; rst <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;

		test(1.0,0.0,0.0);	
		test(0.0,1.0,0.0);
		test(0.0,0.0,1.0);

		test(1.0,1.0,1.0);
		test(2.0,2.0,2.0);


		test(1.0,2.0,3.0);
		test(100.0,50.0,50.0);

		
		$finish;


	end

	
	always #10 clk = ~clk;


	task test(float_t x, float_t y, float_t z); 

		@(posedge clk) begin
			in.x <= $shortrealtobits(x);
			in.y <= $shortrealtobits(y);
			in.z <= $shortrealtobits(z);
		end

		repeat(60) @(posedge clk);

	endtask


endmodule: tb_norm
