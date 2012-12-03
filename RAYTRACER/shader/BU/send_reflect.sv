




module send_reflect(input logic clk, rst,
		    input logic v0, v1, v2,
		    
		    input logic dirpint_to_sendreflect_valid,
		    input dirpint_to_sendreflect_t dirpint_to_sendreflect_data,
		    output logic dirpint_to_sendreflect_stall,

		    output logic shader_to_sint_valid,
		    output shader_to_sint_t shader_to_sint_data,
		    input logic shader_to_sint_stall);

	`ifndef SYNTH
		shortreal refdirx, refdiry, refdirz;
		shortreal reforgx, reforgy, reforgz;
		
		assign refdirx = $bitstoshortreal(shader_to_sint_data.ray_vec.dir.x);
		assign refdiry = $bitstoshortreal(shader_to_sint_data.ray_vec.dir.y);
		assign refdirz = $bitstoshortreal(shader_to_sint_data.ray_vec.dir.z);

		assign reforgx = $bitstoshortreal(shader_to_sint_data.ray_vec.origin.x);
		assign reforgy = $bitstoshortreal(shader_to_sint_data.ray_vec.origin.y);
		assign reforgz = $bitstoshortreal(shader_to_sint_data.ray_vec.origin.z);
		
	`endif


	vector_t N_rpl, raydir_rpl, reflected_rpl;
	assign N_rpl = dirpint_to_sendreflect_data.normal;
	assign raydir_rpl = dirpint_to_sendreflect_data.dir;
	reflector rpl(.N(N_rpl),.raydir(raydir_rpl),
		      .reflected(reflected_rpl),
		      .v0,.v1,.v2,.clk,.rst);

	
	logic us_valid, us_stall;
	logic ds_valid, ds_stall;
	sr_pvs_entry_t us_data, ds_data;
	logic[3:0] f_num_left_in_fifo;
	assign us_valid = dirpint_to_sendreflect_valid && ~dirpint_to_sendreflect_stall;
	assign us_data.rayID = dirpint_to_sendreflect_data.rayID;
	assign us_data.p_int = dirpint_to_sendreflect_data.p_int;
	assign dirpint_to_sendreflect_stall = dirpint_to_sendreflect_valid && (us_stall || ~v0);
	pipe_valid_stall3 #($bits(sr_pvs_entry_t),42) pvs(.us_valid,.us_data,.us_stall,
					     .ds_valid,.ds_data,.ds_stall,
					     .num_left_in_fifo(f_num_left_in_fifo),
					     .v0,.v1,.v2,
					     .clk,.rst);


	shader_to_sint_t f_in, f_out;
	logic f_we, f_re, f_full, f_empty;
	assign ds_stall = f_full;
	assign f_in.rayID = ds_data.rayID;
	assign f_in.ray_vec.origin = ds_data.p_int;
	assign f_in.ray_vec.dir = reflected_rpl;
	assign f_in.is_shadow = 1'b0;
	assign f_we = ds_valid;
	assign shader_to_sint_valid = ~f_empty;
	assign f_re = shader_to_sint_valid && ~shader_to_sint_stall;
	assign shader_to_sint_data = f_out;
	fifo #($bits(shader_to_sint_t),14) f(.data_in(f_in),.we(f_we),.re(f_re),
					     .full(f_full),.empty(f_empty),
					     .exists_in_fifo(),.num_left_in_fifo(f_num_left_in_fifo),
					     .data_out(f_out),.clk,.rst);




endmodule: send_reflect

