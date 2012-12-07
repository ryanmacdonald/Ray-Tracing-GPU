// OBVIOUSLY THIS FILE IS NOT NEAR COMPLETE




module color_convert(
	input logic clk, rst,
	input logic v0, v1, v2,

	output logic pixstore_to_cc_stall,
	input pixstore_to_cc_t pixstore_to_cc_data,
	input logic pixstore_to_cc_valid,

	output logic cc_to_pixel_buffer_valid,
	output pixel_buffer_entry_t cc_to_pixel_buffer_data,
	input logic cc_to_pixel_buffer_stall,);



	pixelID_t us_data, ds_data;
	logic us_valid, ds_valid;
	logic us_stall, ds_stall;
	logic[4:0] num_left_in_fifo;
	assign us_data = pixstore_to_cc_data.pixelID;
	assign us_valid = pixstore_to_cc_valid && ~pixstore_to_cc_stall;
	assign pixstore_to_cc_stall = us_stall && pixstore_to_cc_valid;
	pvs3 #($bits(pixelID),13) pvs0(.us_valid(us_valid),
				       .us_data(us_data),
				       .us_stall(us_stall),
				       .ds_valid(ds_valid),
				       .ds_data(ds_data),
				       .ds_stall(ds_stall),
				       .num_left_in_fifo(num_left_in_fifo));


	color_t color_int;
	color_convert_pl ccpl(.color_fp(color_in),
			      .clk,.rst,
			      .v0,.v1,.v2,
			      .color_int(color_int));


	pixel_buffer_entry_t f_in, f_out;
	assign f_in.pixelID = ds_data;
	assign f_in.color = color_int;
	assign f_we = ds_valid;
	assign f_re = cc_to_pixel_buffer_valid && ~cc_to_pixel_buffer_stall;
	assign cc_to_pixel_buffer_valid = ~f_empty;
	logic f_we, f_re, f_full, f_empty;
	fifo #($bits(pixel_buffer_entry_t),3) f(.data_in(f_in),	
						.we(f_we),
						.re(f_re),
						.full(f_full),
						.empty(f_empty),
						.data_out(f_out),
						.num_left_in_fifo(num_left_in_fifo)
						.clk,.rst);

	
	assign cc_to_pixel_buffer_data = f_out;


endmodule






module color_convert_pl(input float_color_t color_fp,
			input logic clk, rst,
			input logic v0, v1, v2, 
			output color_t color_int);



	float_color_t cfr_q, cfr_d;
	assign cfr_d = color_fp;
	ff_ar_en #($bits(float_color_t),0) cfr(.q(cfr_q),.d(cfr_d),.en(v0),.clk,.rst);



	float_t a_m0, b_m0, r_m0;
	assign a_m0 = v1 ? color_fp.red : (v2 ? color_fp.green : color_fp.blue);
	assign b_m0 = v2 ? `FP_64 : `FP_32;
	altfp_mult m0(.dataa(a_m0),.datab(b_m0),
		      .nan(),.zero(),.underflow(),.overflow(),
		      .clock(clk),.aclr(rst),
		      .result(r_m0));


	float_t in_fti;
	logic[31:0] out_fti;
	assign in_fti = r_m0;
	fp_to_int_convert conv(.dataa(in_fti),
			       .clock(clk),.aclr(rst),
			       .result(out_fti));


	logic[3:0] rr_q, rr_d;
	assign rr_d = out_fti[3:0];
	ff_ar_en #(4,0) rr(.q(rr_q),.d(rr_d),.en(v0),.clk,.rst);


	logic[4:0] rg_q, rg_d;
	assign rg_d = out_fti[4:0];
	ff_ar_en #(5,0) rg(.q(rg_q),.d(rg_d),.en(v1),.clk,.rst);


	logic[3:0] rb_q, rb_d;
	assign rb_d = out_fti[3:0];
	ff_ar_en #(4,0) rb(.q(rb_q),.d(rb_d),.en(v2),.clk,.rst);

	assign color_int.red = rr_q;
	assign color_int.green = rg_q;
	assign color_int.blue = rb_q;


endmodule: color_convert_pl
