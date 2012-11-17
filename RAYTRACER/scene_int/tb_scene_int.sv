




module tb_scene_int();

	prg_ray_t ray;
	logic v0, v1, v2;
	logic clk, rst, isShadow, miss;
	float_t xmin, xmax, ymin, ymax, zmin, zmax;
	float_t tmin_scene, tmax_scene;
	
	scene_int si(.*);

	shortreal tmin, tmax;
	assign tmin = $bitstoshortreal(tmin_scene);
	assign tmax = $bitstoshortreal(tmax_scene);
	

	initial begin
		
		clk <= 1; rst <= 0;
		ray <= 'h1; 

		fire_ray($shortrealtobits(0.5),$shortrealtobits(0.5),$shortrealtobits(0.5),
			 $shortrealtobits(0),$shortrealtobits(0.25),$shortrealtobits(0));
		xmin <= `FP_0; xmax <= `FP_1;
		ymin <= `FP_0; ymax <= `FP_1;
		zmin <= `FP_0; zmax <= `FP_1;
		isShadow <= 1;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;

		repeat(100) @(posedge clk);

		$finish;

	end

	always #5 clk = ~clk;

	logic[1:0] cnt, ncnt;
	
	assign ncnt = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(ncnt),.clk(clk),.rst(rst));

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

	task fire_ray(input float_t origin_x, origin_y, origin_z,
		      input float_t dir_x, dir_y, dir_z);

		ray.origin.x <= origin_x;
		ray.origin.y <= origin_y;
		ray.origin.z <= origin_z;

		ray.dir.x <= dir_x;
		ray.dir.y <= dir_y;
		ray.dir.z <= dir_z;

	endtask: fire_ray


endmodule: tb_scene_int
