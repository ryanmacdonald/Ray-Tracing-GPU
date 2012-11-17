



module scene_int(input prg_ray_t ray_in,
		 input logic v0, v1, v2,
		 input float_t xmin, xmax,
		 input float_t ymin, ymax,
		 input float_t zmin, zmax,
		 input isShadow,
		 input ds_stall, us_valid.
		 input clk, rst, 
		 output scene_int_ray_t ray_out,
		 output logic us_stall);



	scene_int_pl pl(.ray(ray_in),.v0(v0),.v1(v1),.v2(v2),
			.xmin(xmin),.xmax(xmax),
			.ymin(ymin),.ymax(ymax),
			.zmin(zmin),.zmax(zmax),
			.isShadow(isShadow), .clk, .rst,
			.tmin_scene(tmin_scene),.tmax_scene(tmax_scene),
			.miss(miss));

	logic us_valid, ds_valid, ds_stall;
	logic[$bits(pixelID)] us_data, ds_data;
	logic[3:0] num_left_in_fifo;
	assign us_data = {ray.pixelID,us_valid};
	pipe_valid_stall pvs #(.WIDTH($bits(pixelID)+1),.DEPTH(17))
			     (.clk,.rst,.us_valid(us_valid),.us_data(us_data),.us_stall(us_stall),
			      .ds_valid(ds_valid),.ds_data(ds_data),.ds_stall,
			      .num_left_in_fifo(num_left_in_fifo));


	logic[$bits(prg_ray_t)] data_in, data_out;
	logic tf_we, tf_re, tf_full, exists_in_fifo, tf+empty;
	logic[3:0] num_left_in_fifo;
	assign tf_we = ds_valid;
	assign data_in = {tmin_scene,tmax_scene,miss,ds_data,ray_vec};
	fifo #(.WIDTH($bits(ray_t)),.K(3),.EARLY_BY(0))
	     tf(.clk,.rst,data_in(data_in),we(tf_we),re(tf_re),
		full(tf_full),exists_in_fifo(),.empty(tf_empty),data_out(data_out),
		num_left_in_fifo(num_left_in_fifo));		

endmodule: scene_int


