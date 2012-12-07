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
	assign us_data = pixstore_to_cc_data.pixelID;
	assign us_valid = pixstore_to_cc_valid && ~pixstore_to_cc_stall;
	assign pixstore_to_cc_stall = us_stall && pixstore_to_cc_valid;
	pvs3 #($bits(pixelID),13) pvs0(.);


	color_t color_int;
	color_convert_pl ccpl(.color_fp(color_in),
			      .clk,.rst,
			      .v0,.v1,.v2,
			      .color_int(color_int));


	pixstore_to_cc_t f_in, f_out;
	logic f_we, f_re, f_full, f_empty;
	logic[4:0] num_left_in_fifo;
	fifo #($bits(pixestore_to_cc_t),5) f(.);


endmodule






module color_convert_pl(input float_color_t color_fp,
			input logic clk, rst,
			input logic v0, v1, v2, 
			output color16_t color_int);



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



endmodule: color_convert_pl
