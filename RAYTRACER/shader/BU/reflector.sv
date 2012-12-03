

// Latency of 42


module reflector(input vector_t N, raydir,
		 input logic v0, v1, v2,
		 input logic clk, rst,
		 output vector_t reflected);


	`ifndef SYNTH
		shortreal refx, refy, refz;
		assign refx = $bitstoshortreal(reflected.x);
		assign refy = $bitstoshortreal(reflected.y);
		assign refz = $bitstoshortreal(reflected.z);
	`endif


	vector_t norm_q, norm_d;
	assign norm_d = N;
	ff_ar_en #($bits(vector_t),0) nr(.q(norm_q),.d(norm_d),.en(v0),.clk,.rst);


	vector_t rdir_q, rdir_d;
	assign rdir_d = raydir;
	ff_ar_en #($bits(vector_t),0) rr(.q(rdir_q),.d(rdir_d),.en(v0),.clk,.rst);

	
	float_t n_buf_in, n_buf_out;
	assign n_buf_in = v1 ? norm_q.x : (v2 ? norm_q.y : norm_q.z);
	buf_t3 #(21,$bits(float_t)) n_buf(.data_out(n_buf_out),.data_in(n_buf_in),.clk,.rst);


	float_t r_buf_in, r_buf_out;
	assign r_buf_in = v1 ? rdir_q.x : (v2 ? rdir_q.y : rdir_q.z);
	buf_t3 #(31,$bits(float_t)) r_buf(.data_out(r_buf_out),.data_in(r_buf_in),.clk,.rst);

	
	vector_t a_dp, b_dp;
	float_t result_dp;
	assign a_dp = norm_q; 
	assign b_dp = rdir_q;
	dot_prod dp(.a(a_dp),.b(b_dp),.v0,.v1,.v2,.clk,.rst,.result(result_dp));	


	float_t dpr_q, dpr_d;
	assign dpr_d = result_dp;
	ff_ar_en #($bits(float_t),0) dpr(.q(dpr_q),.d(dpr_d),.en(v0),.clk,.rst);


	float_t dataa_mult1, datab_mult1, result_mult1;
	assign dataa_mult1 = n_buf_out;
	assign datab_mult1 = dpr_q;
	altfp_mult mult1(.dataa(dataa_mult1),.datab(datab_mult1),.result(result_mult1),
			.nan(),.zero(),.underflow(),.overflow(),
			.clock(clk),.aclr(rst));

	
	float_t dataa_mult2, datab_mult2, result_mult2;
	assign dataa_mult2 = result_mult1;
	assign datab_mult2 = `FP_2;
	altfp_mult mult2(.dataa(dataa_mult2),.datab(datab_mult2),.result(result_mult2),
			.nan(),.zero(),.underflow(),.overflow(),
			.clock(clk),.aclr(rst));


	float_t dataa_add_pos, dataa_add_neg, datab_add, result_add;
	assign dataa_add_pos = result_mult2;
	assign dataa_add_neg = {~result_mult2.sign,result_mult2[30:0]};
	assign datab_add = r_buf_out;	
	altfp_add add(.dataa(dataa_add_neg),.datab(datab_add),.result(result_add),
		      .nan(),.zero(),.underflow(),.overflow(),
		      .clock(clk),.aclr(rst));

	
	float_t rrx_q, rrx_d;
	logic rrx_en;
	assign rrx_en = v0;
	assign rrx_d = result_add;
	ff_ar_en #($bits(float_t),0) rrx(.q(rrx_q),.d(rrx_d),.en(rrx_en),.clk,.rst);


	float_t rry_q, rry_d;
	logic rry_en;
	assign rry_en = v1;
	assign rry_d = result_add;
	ff_ar_en #($bits(float_t),0) rry(.q(rry_q),.d(rry_d),.en(rry_en),.clk,.rst);

	
	float_t rrz_q, rrz_d;
	logic rrz_en;
	assign rrz_en = v2;
	assign rrz_d = result_add;
	ff_ar_en #($bits(float_t),0) rrz(.q(rrz_q),.d(rrz_d),.en(rrz_en),.clk,.rst);


	assign reflected.x = rrx_q;
	assign reflected.y = rry_q;
	assign reflected.z = rrz_q;


endmodule: reflector
