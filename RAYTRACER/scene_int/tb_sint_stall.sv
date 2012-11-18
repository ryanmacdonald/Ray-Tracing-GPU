


module tb_sint_stall;


	shader_to_sint_t ray_in;
	logic v0, v1, v2;
	float_t xmin, xmax, ymin, ymax, zmin, zmax;
	logic ds_stall, us_valid;
	logic clk, rst;
	tarb_t ray_out_sint_to_tarb;
	logic us_stall, valid;	

	scene_int si(.*);


	initial begin

		rst <= 0;
		xmin <= 0; xmax <= `FP_1;
		ymin <= 0; ymax <= `FP_1;
		zmin <= 0; zmax <= `FP_1;
		ds_stall <= 0;
		us_valid <= 0;	
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		
		@(posedge clk);


		$finish;

	end
	
	always #5 clk = ~clk;

	logic[1:0] cnt, ncnt;

	assign ncnt = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(ncnt),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

	
	task send_ray(input float_t x_origin, y_origin, z_origin,
		      input float_t x_direct, y_direct, z_direct);

		wait(v0);

		ray_in.origin.x <= x_origin; 
		ray_in.origin.y <= y_origin;
		ray_in.origin.z <= z_origin;
		
		ray_in.direct.x <= x_direct;
		ray_in.direct.y <= y_direct;
		ray_in.direct.z <= z_direct;

		us_valid <= 1;

		@(posedge clk);
		us_valid <= 0;

	endtask: send_ray


endmodule: tb_sint_stall
