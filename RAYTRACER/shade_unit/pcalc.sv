
// Latency of 16

module pcalc(input ray_vec_t vec,
	     input float_t t,
	     input logic v0, v1, v2,
	     input logic clk, rst,
	     output vector_t pos);

	`ifndef SYNTH
		shortreal posx, posy, posz;
		shortreal drx, dry, drz;
		shortreal orx, ory, orz;
		shortreal tsr;
		shortreal res_add;
		shortreal res_mult;
		shortreal res_t3;
		assign res_add = $bitstoshortreal(result_add);
		assign res_mult = $bitstoshortreal(result_mult);
		assign res_t3 = $bitstoshortreal(or_buf_out);
		assign posx = $bitstoshortreal(x_q);
		assign posy = $bitstoshortreal(y_q);
		assign posz = $bitstoshortreal(z_q);
		assign drx = $bitstoshortreal(dir_q.x);
		assign dry = $bitstoshortreal(dir_q.y);
		assign drz = $bitstoshortreal(dir_q.z);
		assign orx = $bitstoshortreal(org_q.x);
		assign ory = $bitstoshortreal(org_q.y);
		assign orz = $bitstoshortreal(org_q.z);
		assign tsr = $bitstoshortreal(t_q);
	`endif


	vector_t dir_q, dir_d;
	assign dir_d = vec.dir;
	ff_ar_en #($bits(vector_t),0) dir_r(.q(dir_q),.d(dir_d),.en(v0),.clk,.rst);


	float_t t_q, t_d;
	assign t_d = t;
	ff_ar_en #($bits(float_t),0) t_r(.q(t_q),.d(t_d),.en(v0),.clk,.rst);

	
	vector_t org_q, org_d;
	assign org_d = vec.origin;
	ff_ar_en #($bits(vector_t),0) org_r(.q(org_q),.d(org_d),.en(v0),.clk,.rst);


	float_t dataa_mult, datab_mult, result_mult;
	assign dataa_mult = v1 ? dir_q.x : (v2 ? dir_q.y : dir_q.z);
	assign datab_mult = t_q;
	altfp_mult mult(.dataa(dataa_mult),.datab(datab_mult),.result(result_mult),
			.nan(),.overflow(),.underflow(),.zero(),
			.clock(clk),.aclr(rst));


	float_t or_buf_in, or_buf_out;
	assign or_buf_in = v1 ? org_q.x : (v2 ? org_q.y : org_q.z);
	buf_t3 #(5,$bits(float_t)) or_buf(.data_out(or_buf_out),.data_in(or_buf_in),.clk,.rst);


	float_t dataa_add, datab_add, result_add;
	assign dataa_add = result_mult;
	assign datab_add = or_buf_out;
	altfp_add add(.dataa(dataa_add),.datab(datab_add),.result(result_add),
		      .nan(),.overflow(),.underflow(),.zero(),
		      .clock(clk),.aclr(rst));


	float_t x_q, x_d;
	logic x_en;
	assign x_d = result_add;
	assign x_en = v1;
	ff_ar_en #($bits(float_t),0) xposr(.q(x_q),.d(x_d),.en(x_en),.clk,.rst);
	

	float_t y_q, y_d;
	logic y_en;
	assign y_d = result_add;
	assign y_en = v2;
	ff_ar_en #($bits(float_t),0) yposr(.q(y_q),.d(y_d),.en(y_en),.clk,.rst);


	float_t z_q, z_d;
	logic z_en;
	assign z_d = result_add;
	assign z_en = v0;
	ff_ar_en #($bits(float_t),0) zposr(.q(z_q),.d(z_d),.en(z_en),.clk,.rst);


	assign pos.x = x_q;
	assign pos.y = y_q;
	assign pos.z = z_q;


endmodule: pcalc
