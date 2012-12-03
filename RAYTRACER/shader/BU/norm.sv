
// Latency = 55

module norm(input vector_t in,
	    input logic v0, v1, v2,
	    input logic clk, rst,
	    output vector_t norm);


	vector_t vr_q, vr_d;
	logic vr_en;
	assign vr_d = in;
	assign vr_en = v0;
	ff_ar_en #($bits(vector_t),0) vr(.q(vr_q),.d(vr_d),.en(vr_en),.clk,.rst);


	vector_t dp_a, dp_b;
	float_t dp_res;
	assign dp_a = vr_q;
	assign dp_b = vr_q;
	dot_prod dp(.a(dp_a),.b(dp_b),.v0,.v1,.v2,.clk,.rst,.result(dp_res));


	float_t b_in, b_out;
	assign b_in = v1 ? vr_q.x : (v2 ? vr_q.y : vr_q.z); 
	buf_t3 #(46,$bits(float_t)) b(.data_out(b_out),.data_in(b_in),.clk,.rst);


	float_t is_in, is_out;
	assign is_in = dp_res;
	altfp_inv_sqra is(.data(is_in),.clock(clk),.aclr(rst),.result(is_out));


	float_t dataa_m, datab_m, result_m;
	assign dataa_m = b_out;
	assign datab_m = is_out;
	altfp_mult m(.dataa(dataa_m),.datab(datab_m),
		     .zero(),.nan(),
		     .overflow(),.underflow(),
		     .clock(clk),.aclr(rst),.result(result_m));


	float_t nrx_d;
	logic nrx_en;
	assign nrx_d = result_m;
	assign nrx_en = v1;	
	ff_ar_en #($bits(float_t),0) nrx(.q(norm.x),.d(nrx_d),.en(nrx_en),.clk,.rst);

	float_t nry_d;
	logic nry_en;
	assign nry_d = result_m;
	assign nry_en = v2;
	ff_ar_en #($bits(float_t),0) nry(.q(norm.y),.d(nry_d),.en(nry_en),.clk,.rst);


	float_t nrz_d;
	logic nrz_en;
	assign nrz_d = result_m;
	assign nrz_en = v0;
	ff_ar_en #($bits(float_t),0) nrz(.q(norm.z),.d(nrz_d),.en(nrz_en),.clk,.rst);


endmodule: norm
