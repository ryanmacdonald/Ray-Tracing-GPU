
// Latency = 20 cycles

module dot_prod(input vector_t a, b,
		input logic v0, v1, v2,
		input logic clk, rst,
		output float_t result);

	`ifndef SYNTH
		shortreal a_sr, b_sr, r_sr;
		assign a_sr = $bitstoshortreal(dataa_mult);
		assign b_sr = $bitstoshortreal(datab_mult);
		assign r_sr = $bitstoshortreal(result);
	`endif

	float_t dataa_mult, datab_mult, result_mult;
	assign dataa_mult = v0 ? a.x : (v1 ? a.y : a.z);
	assign datab_mult = v0 ? b.x : (v1 ? b.y : b.z);
	altfp_mult mult(.dataa(dataa_mult),.datab(datab_mult),.result(result_mult),
			.nan(),.overflow(),.underflow(),.zero(),
			.clock(clk),.aclr(rst));


	float_t q_xaxb, d_xaxb;
	assign d_xaxb = result_mult;
	ff_ar #($bits(float_t),0) zr(.q(q_xaxb),.d(d_xaxb),.clk,.rst);


	float_t dataa_add1, datab_add1, result_add1;
	assign dataa_add1 = q_xaxb;
	assign datab_add1 = result_mult;
	altfp_add add1(.dataa(dataa_add1),.datab(datab_add1),.result(result_add1),
		       .nan(),.overflow(),.underflow(),.zero(),
		       .clock(clk),.aclr(rst));


	float_t zbuf_out, zbuf_in;
	assign zbuf_in = result_mult;
	buf_t3 #(6,$bits(float_t)) zbuf(.data_out(zbuf_out),.data_in(zbuf_in),.clk,.rst);


	float_t dataa_add2, datab_add2, result_add2;
	assign dataa_add2 = result_add1;
	assign datab_add2 = zbuf_out;
	altfp_add add2(.dataa(dataa_add2),.datab(datab_add2),.result(result_add2),
		       .nan(),.overflow(),.underflow(),.zero(),
		       .clock(clk),.aclr(rst));


	ff_ar_en #($bits(float_t),0) rr(.q(result),.d(result_add2),.en(v2),.clk,.rst);


endmodule: dot_prod
