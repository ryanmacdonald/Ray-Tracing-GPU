
// TODO Found some potential bugs here...
/*
  -shader_to_sint stall should depend on v0 and if it is valid
*/


module scene_int(
		 input logic v0, v1, v2,
		 input AABB_t sceneAABB,
		 input clk, rst, 
		 
     // shader_to_sint
			input logic shader_to_sint_valid,
			input shader_to_sint_t shader_to_sint_data,
			output logic shader_to_sint_stall,
			
      // sint_to_shader
			output logic sint_to_shader_valid,
			output sint_to_shader_t sint_to_shader_data,
			input logic sint_to_shader_stall,
    
			// sint_to_ss
			output logic sint_to_ss_valid,
			output sint_to_ss_t sint_to_ss_data,
			input logic sint_to_ss_stall,
    
			// sint_to_tarb
			output logic sint_to_tarb_valid,
			output tarb_t sint_to_tarb_data,
			input logic sint_to_tarb_stall 

      );    

	float_t tmin_scene, tmax_scene;
	
	`ifndef SYNTH
		shortreal ox,oy,oz,dx,dy,dz;
		assign ox = $bitstoshortreal(shader_to_sint_data.ray_vec.origin.x);
		assign oy = $bitstoshortreal(shader_to_sint_data.ray_vec.origin.y);
		assign oz = $bitstoshortreal(shader_to_sint_data.ray_vec.origin.z);
		assign dx = $bitstoshortreal(shader_to_sint_data.ray_vec.dir.x);
		assign dy = $bitstoshortreal(shader_to_sint_data.ray_vec.dir.y);
		assign dz = $bitstoshortreal(shader_to_sint_data.ray_vec.dir.z);

	`endif

	shader_to_sint_t ray;
	ff_ar_en #($bits(shader_to_sint_t),0) rr(.q(ray),.d(shader_to_sint_data),.en(shader_to_sint_valid),.clk,.rst);

	

	logic isShadow, miss;
	scene_int_pl pl(.ray(ray),.v0(v0),.v1(v1),.v2(v2),
			.xmin(sceneAABB.xmin),.xmax(sceneAABB.xmax),
			.ymin(sceneAABB.ymin),.ymax(sceneAABB.ymax),
			.zmin(sceneAABB.zmin),.zmax(sceneAABB.zmax),
			.isShadow(isShadow), .clk, .rst,
			.tmin_scene(tmin_scene),.tmax_scene(tmax_scene),
			.miss(miss));

	logic ds_valid, ds_stall, us_stall;
	logic[$bits(rayID_t):0] us_data, ds_data;
	logic[4:0] num_left_in_fifo;
	assign us_data = {shader_to_sint_data.rayID,shader_to_sint_data.is_shadow};
	assign isShadow = ds_data[0];
	pipe_valid_stall #(.WIDTH($bits(rayID_t)+1),.DEPTH(18)) pvs
			     (.clk,.rst,.us_valid(shader_to_sint_valid),.us_data(us_data),.us_stall(us_stall),
			      .ds_valid(ds_valid),.ds_data(ds_data),.ds_stall(ds_stall),
			      .num_left_in_fifo(num_left_in_fifo));

	assign ds_stall = sint_to_tarb_stall || sint_to_ss_stall || sint_to_shader_stall;

	assign shader_to_sint_stall = us_stall & shader_to_sint_valid;

	/* TARB FIFO */	

	sint_entry_t tf_data_in, tf_data_out;
	logic tf_we, tf_re, tf_full, tf_empty;
	logic[4:0] tf_num_left_in_fifo;
	assign tf_we = ds_valid && ~miss;
	assign tf_re = sint_to_tarb_valid && ~sint_to_tarb_stall;
	assign sint_to_tarb_valid = ~tf_empty;

	// fifo data_in assigns
	assign tf_data_in.rayID = ds_data[9:1];
	assign tf_data_in.tmin = tmin_scene;
	assign tf_data_in.tmax = tmax_scene;
	assign tf_data_in.is_shadow = isShadow;
	assign tf_data_in.miss = miss;
	
	// fifo data_out assigns
	assign sint_to_tarb_data.ray_info.ss_wptr = 'h0;
	assign sint_to_tarb_data.ray_info.ss_num = 'h0;
	assign sint_to_tarb_data.ray_info.is_shadow = tf_data_out.is_shadow;
	assign sint_to_tarb_data.ray_info.rayID = tf_data_out.rayID;
	assign sint_to_tarb_data.nodeID = 'h0;
	assign sint_to_tarb_data.restnode_search = 1'b1;
	assign sint_to_tarb_data.t_max = tf_data_out.tmax;
	assign sint_to_tarb_data.t_min = tf_data_out.tmin;
	fifo #(.WIDTH($bits(sint_entry_t)),.DEPTH(18))
	     tf(.clk,.rst,.data_in(tf_data_in),.we(tf_we),.re(tf_re),
		.full(tf_full),.exists_in_fifo(),.empty(tf_empty),.data_out(tf_data_out),
		.num_left_in_fifo(tf_num_left_in_fifo));		


	/* SS FIFO */
	

	sint_to_ss_t ssf_data_in, ssf_data_out;
	logic ssf_we, ssf_re, ssf_full, ssf_empty;
	logic[4:0] ssf_num_left_in_fifo;
	assign ssf_we = ds_valid && ~miss; 
	assign ssf_re = sint_to_ss_valid && ~sint_to_ss_stall;
	assign sint_to_ss_valid = ~ssf_empty;

	// SS fifo data_in assigns
	assign ssf_data_in.rayID = ds_data[9:1]; 
	assign ssf_data_in.t_max_scene = tmax_scene;

	// SS fifo data_out assigns
	assign sint_to_ss_data.rayID = ssf_data_out.rayID;
	assign sint_to_ss_data.t_max_scene = ssf_data_out.t_max_scene;

	fifo #(.WIDTH($bits(sint_to_ss_t)),.DEPTH(18))
	     ssf(.clk,.rst,.data_in(ssf_data_in),.we(ssf_we),.re(ssf_re),
		 .full(ssf_full),.exists_in_fifo(),
		 .empty(ssf_empty),.data_out(ssf_data_out),
		 .num_left_in_fifo(ssf_num_left_in_fifo));




	/* SHADER FIFO */

	sint_to_shader_t ssh_data_in, ssh_data_out;
	logic ssh_we, ssh_re, ssh_full, ssh_empty;
	logic[4:0] ssh_num_left_in_fifo;
	assign ssh_we = ds_valid && miss;
	assign ssh_re = sint_to_shader_valid && ~sint_to_shader_stall;
	assign sint_to_shader_valid = ~ssh_empty;

	// Sh fifo data_in assigns
	assign ssh_data_in.rayID = ds_data[9:1];

	// Sh fifo data_out assigns
	assign sint_to_shader_data.rayID = ssh_data_out.rayID;

	fifo #(.WIDTH($bits(sint_to_shader_t)),.DEPTH(18))
	     ssh(.clk,.rst,.data_in(ssh_data_in),.we(ssh_we),.re(ssh_re),
		 .full(ssh_full),.exists_in_fifo(),.empty(ssh_empty),
		 .data_out(ssh_data_out),.num_left_in_fifo(ssh_num_left_in_fifo));

	
	// Need to give stall unit the minimum of num_lefts
	minimum3 #(5) min(num_left_in_fifo,ssh_num_left_in_fifo,
			  ssf_num_left_in_fifo,tf_num_left_in_fifo);


endmodule: scene_int

