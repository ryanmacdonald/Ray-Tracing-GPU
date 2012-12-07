
module send_shadow(
       input logic clk, rst,
		   input logic v0, v1, v2,

		   input logic scache_to_sendshadow_valid,
  		 input scache_to_sendshadow_t scache_to_sendshadow_data,
		   output logic scache_to_sendshadow_stall,

		   output logic sendshadow_to_sint_valid,
		   output shader_to_sint_t sendshadow_to_sint_data,
		   input logic sendshadow_to_sint_stall,

		   output logic shadow_or_miss_valid,
		   output shadow_or_miss_t shadow_or_miss_data,
		   input logic shadow_or_miss_stall
       );


	`ifndef SYNTH

	`endif
  
  assign = ; // TODO the scache_to_sendshadow_stall needs to be independent of the valid

  
	vector_t norm, light, p_int;
	vector_t light_vec;
	logic miss;
	assign norm = scache_to_sendshadow_data.normal;
	assign light = scache_to_sendshadow_data.light;
	assign p_int = scache_to_sendshadow_data.p_int;
	send_shadow_pl pl(.clk,.rst,.v0,.v1,.v2,
			.norm,.light_pos(light),.p_int,
			.miss,.light_ds(light_vec));


	logic us_valid, us_stall;
	logic ds_valid, ds_stall;
	sr_pvs_entry_t us_data, ds_data;
	logic[3:0] num_left_in_fifo;
	assign us_valid = scache_to_sendshadow_valid && ~scache_to_sendshadow_stall;
	assign scache_to_sendshadow_stall = ~v0 || us_stall;
	assign us_data.rayID = scache_to_sendshadow_data.rayID;
	assign us_data.p_int = scache_to_sendshadow_data.p_int;
	pipe_valid_stall3 #($bits(sr_pvs_entry_t),31) 
			  pvs(.us_valid,.us_data,.us_stall,
			      .ds_valid,.ds_data,.ds_stall,
			      .num_left_in_fifo,
			      .clk,.rst,.v0,.v1,.v2);


	shader_to_sint_t miss_data_out, miss_data_in;
	logic miss_we, miss_re, miss_full, miss_empty;
	logic[3:0] miss_num_left_in_fifo;
	assign miss_data_in.rayID = ds_data.rayID;
	assign miss_data_in.is_shadow = 1'b1;
	assign miss_data_in.ray_vec.origin = ds_data.p_int;
	assign miss_data_in.ray_vec.dir = light_vec;
	assign miss_we = miss && ds_valid;
	assign miss_re = sendshadow_to_sint_valid && ~sendshadow_to_sint_stall;
	assign sendshadow_to_sint_valid = ~miss_empty;
	assign sendshadow_to_sint_data = miss_data_out;
	fifo #($bits(shader_to_sint_t),11) 
			miss_f(.data_out(miss_data_out),.data_in(miss_data_in),
			.we(miss_we),.re(miss_re),
			.full(miss_full),.empty(miss_empty),
			.exists_in_fifo(),.num_left_in_fifo(miss_num_left_in_fifo),
			.clk,.rst);


	shadow_or_miss_t hit_data_out, hit_data_in;
	logic hit_we, hit_re, hit_full, hit_empty;
	logic[3:0] hit_num_left_in_fifo;
	assign hit_data_in.rayID = ds_data.rayID;
	assign hit_data_in.is_shadow = 1'b1;
	assign hit_data_in.is_miss = 1'b0;
	assign hit_we = ~miss && ds_valid;
	assign hit_re = shadow_or_miss_valid && ~shadow_or_miss_stall;
	assign shadow_or_miss_valid = ~hit_empty;
	assign shadow_or_miss_data = hit_data_out; 
	fifo #($bits(shadow_or_miss_t),11)
			hit_f(.data_out(hit_data_out),.data_in(hit_data_in),
			.we(hit_we),.re(hit_re),
			.full(hit_full),.empty(hit_empty),
			.exists_in_fifo(),.num_left_in_fifo(hit_num_left_in_fifo),
			.clk,.rst);
	
	assign ds_stall = miss_full || hit_full;

	minimum2 #(4) min(num_left_in_fifo,
			  hit_num_left_in_fifo,
			  miss_num_left_in_fifo);

endmodule





// In this context, a miss means that the shadow ray
// will enter the pipeline. That is, a hit means it cannot receive
// contribution from the light
module send_shadow_pl(input logic clk, rst,
		      input logic v0, v1, v2,
		      input vector_t norm, light_pos, p_int,
		      output miss,
		      output vector_t light_ds);

	
	float_t dataa, datab_pos, datab, result;
	assign dataa = v0 ? light_pos.x : (v1 ? light_pos.y : light_pos.z);
	assign datab_pos = v0 ? p_int.x : (v1 ? p_int.y : p_int.z);
	assign datab = {~datab_pos.sign,datab_pos[30:0]};
	altfp_add add(.dataa,.datab,.result,.clock(clk),.aclr(rst),
		      .nan(),.overflow(),.underflow(),.zero());

	vector_t norm_us, norm_ds;
	assign norm_us = norm;
	buf_t1 #(10,$bits(vector_t)) buf0(.data_out(norm_ds),.data_in(norm_us),
					 .v0(v0),.clk,.rst);


	vector_t light_dir;
	ff_ar_en #($bits(float_t),0) lrx(.q(light_dir.x),.d(result),.en(v1),.clk,.rst);
	ff_ar_en #($bits(float_t),0) lry(.q(light_dir.y),.d(result),.en(v2),.clk,.rst);
	ff_ar_en #($bits(float_t),0) lrz(.q(light_dir.z),.d(result),.en(v0),.clk,.rst);

	vector_t light_us;
	buf_t1 #(21,$bits(vector_t)) buf1(.data_out(light_ds),.data_in(light_us),
					 .v0(v1),.clk,.rst);

	vector_t dp_a, dp_b;
	float_t dp_res;
	assign dp_a = norm_ds;
	assign dp_b = light_dir;
	dot_prod dp(.a(dp_a),.b(dp_b),
		    .v0(v1),.v1(v2),.v2(v0),
		    .clk,.rst,.result(dp_res));


	float_t cmp_a, cmp_b;
	logic cmp_aeb, cmp_agb;
	assign cmp_a = dp_res; 
	assign cmp_b = `FP_0;
	altfp_compare cmp(.dataa(cmp_a),.datab(cmp_b),
			  .aeb(cmp_aeb),.agb(cmp_agb),
			  .clock(clk),.aclr(rst));


	assign miss = cmp_agb;


endmodule: send_shadow_pl
