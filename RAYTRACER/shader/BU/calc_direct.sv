


// A --> Ambient light color
// K --> Color of triangle
// C --> Diffuse light color
// B --> Background color
// N --> Normal of triangle
// L --> Light Position
// TODO ryan, make A and C and B, L  be seperate inputs
// TODO also noticed that you have no fifos to go along with pipe valid stall
// TODO also the dirpint unit needs the upstream stalls to be independent of the valid coming in

module calc_direct(
      		   input logic clk, rst,
		   input logic v0, v1, v2,
		   input float_color_t ambient,
		   input float_color_t light_color,

		   output logic dirpint_to_calc_direct_stall,
		   input dirpint_to_calc_direct_t dirpint_to_calc_direct_data,
		   input logic dirpint_to_calc_direct_valid,

		   input logic calc_direct_to_BM_stall,
		   output calc_direct_to_BM_t calc_direct_to_BM_data,
		   output logic calc_direct_to_BM_valid
       
       );


	// Stall, valid signals going into the arbiter
	logic sa_p0_us_valid, sa_p1_us_valid, sa_p2_us_valid;
	logic sa_p0_us_stall, sa_p1_us_stall, sa_p2_us_stall;


	/* BEGIN SHADOW AND MISS PATH */	
	
	logic p0_stall;
	logic pvs0_us_valid, pvs0_us_stall;
	logic pvs0_ds_valid, pvs0_ds_stall;
	logic[5:0] pvs0_num_left_in_fifo;
	calc_dir_pvs_entry_t pvs0_us_data, pvs0_ds_data;
	assign pvs0_us_valid = dirpint_to_calc_direct_valid &&
			       dirpint_to_calc_direct_data.is_shadow &&
			       dirpint_to_calc_direct_data.is_miss;
	assign pvs0_us_data.rayID = dirpint_to_calc_direct_data.rayID;
	assign pvs0_us_data.spec = dirpint_to_calc_direct_data.spec;
	assign pvs0_us_data.is_last = dirpint_to_calc_direct_data.is_last;
	assign p0_stall = (pvs0_us_stall || ~v0) &&
			  dirpint_to_calc_direct_data.is_shadow &&
			  dirpint_to_calc_direct_data.is_miss;
	logic[5:0] p0_num_left_in_fifo;
	pipe_valid_stall3 #($bits(calc_dir_pvs_entry_t),108) 
						pvs0(.us_valid(pvs0_us_valid&&~p0_stall),
						    .us_stall(pvs0_us_stall),
						    .us_data(pvs0_us_data),
						    .ds_valid(pvs0_ds_valid),
						    .ds_stall(pvs0_ds_stall),
						    .ds_data(pvs0_ds_data),
						    .num_left_in_fifo(p0_num_left_in_fifo),
						    .clk,.rst,.v0,.v1,.v2);		

	float_color_t shadow_and_miss_color;
	shadow_and_miss_pl smpl(.A(ambient),
				.C(light_color),
				.K(dirpint_to_calc_direct_data.K),
				.N(dirpint_to_calc_direct_data.N),
				.L(dirpint_to_calc_direct_data.L),
				.p_int(dirpint_to_calc_direct_data.p_int),
				.clk,.rst,.v0,.v1,.v2,
				.color(shadow_and_miss_color));


	calc_direct_to_BM_t p0_in, p0_out;
	logic p0_we, p0_re, p0_full, p0_empty;

	assign p0_in.color = shadow_and_miss_color;
	assign p0_in.rayID = pvs0_ds_data.rayID;
	assign p0_in.spec = pvs0_ds_data.spec;
	assign p0_in.is_last = pvs0_ds_data.is_last;
	assign p0_we = pvs0_ds_valid;
	assign sa_p0_us_valid = ~p0_empty;
	assign p0_re = sa_p0_us_valid && ~sa_p0_us_stall;
	fifo #($bits(calc_direct_to_BM_t),35) 
					p0_f(.data_in(p0_in),
					     .we(p0_we),.re(p0_re),.full(p0_full),.empty(p0_empty),
					     .exists_in_fifo(),
					     .data_out(p0_out),
					     .num_left_in_fifo(p0_num_left_in_fifo),.clk,.rst);

	/* END SHADOW AND MISS PATH */

	/* BEGIN SHADOW AND NOT MISS PATH */


	logic p1_stall;
	logic pvs1_us_valid, pvs1_us_stall;
	logic pvs1_ds_valid, pvs1_ds_stall;
	logic[5:0] pvs1_num_left_in_fifo;
	calc_dir_pvs_entry_t pvs1_us_data, pvs1_ds_data;
	assign pvs1_us_valid = dirpint_to_calc_direct_valid &&
			       dirpint_to_calc_direct_data.is_shadow &&
			       ~dirpint_to_calc_direct_data.is_miss;
	assign pvs1_us_data.rayID = dirpint_to_calc_direct_data.rayID;
	assign pvs1_us_data.spec = dirpint_to_calc_direct_data.spec;
	assign pvs1_us_data.is_last = dirpint_to_calc_direct_data.is_last;
	assign p1_stall = (pvs1_us_stall || ~v0) &&
			  dirpint_to_calc_direct_data.is_shadow &&
			  ~dirpint_to_calc_direct_data.is_miss;
	logic[2:0] p1_num_left_in_fifo;
	pipe_valid_stall3 #($bits(calc_dir_pvs_entry_t),9) 
						pvs1(.us_valid(pvs1_us_valid&&~p1_stall),
						    .us_stall(pvs1_us_stall),
						    .us_data(pvs1_us_data),
						    .ds_valid(pvs1_ds_valid),
						    .ds_stall(pvs1_ds_stall),
						    .ds_data(pvs1_ds_data),
						    .num_left_in_fifo(p1_num_left_in_fifo),
						    .clk,.rst,.v0,.v1,.v2);

	float_color_t kr_q;
	ff_ar_en #($bits(float_color_t),0) kr(.q(kr_q),.d(dirpint_to_calc_direct_data.K),.en(v0),.clk,.rst);

	
	float_color_t shadow_and_not_miss_color;
	float_t m_a, m_b, m_res;
	assign m_a = ambient;
	assign m_b = v0 ? kr_q.red : (v1 ? kr_q.green : kr_q.blue);
	altfp_mult m(.dataa(m_a),
		     .datab(m_b),
		     .result(m_res),
		     .clock(clk),.aclr(rst),
		     .nan(),.zero(),.underflow(),.overflow());

	float_t r_q, g_q, b_q;
	ff_ar_en #($bits(float_t),0) snm_r(.q(r_q),.d(m_res),.en(v0),.clk,.rst);
	ff_ar_en #($bits(float_t),0) snm_g(.q(g_q),.d(m_res),.en(v1),.clk,.rst);
	ff_ar_en #($bits(float_t),0) snm_b(.q(b_q),.d(m_res),.en(v2),.clk,.rst);

	assign shadow_and_not_miss_color.red = r_q;
	assign shadow_and_not_miss_color.green = g_q;
	assign shadow_and_not_miss_color.blue = b_q;

	calc_direct_to_BM_t p1_in, p1_out;
	logic p1_we, p1_re, p1_full, p1_empty;

	assign p1_in.color = shadow_and_not_miss_color;
	assign p1_in.rayID = pvs1_ds_data.rayID;
	assign p1_in.spec = pvs1_ds_data.spec;
	assign p1_in.is_last = pvs1_ds_data.is_last;
	assign p1_we = pvs1_ds_valid;
	assign sa_p1_us_valid = ~p1_empty;
	assign p1_re = sa_p1_us_valid && ~sa_p1_us_stall;
	fifo #($bits(calc_direct_to_BM_t),4) 
					p1_f(.data_in(p1_in),
					     .we(p1_we),.re(p1_re),.full(p1_full),.empty(p1_empty),
					     .exists_in_fifo(),
					     .data_out(p1_out),
					     .num_left_in_fifo(p1_num_left_in_fifo),.clk,.rst);

	/* END SHADOW AND NOT MISS PATH */


	/* BEGIN ARBITER AND OTHER PATH*/


	logic pvs2_valid, pvs2_ds_stall;
	calc_direct_to_BM_t pvs2_ds_data;


	calc_direct_to_BM_t sa_p0_data, sa_p1_data, sa_p2_data;
	assign sa_p0_data = p0_out;
	assign sa_p1_data = p1_out;
	assign sa_p2_data = pvs2_ds_data; 
	small_arbitor #(3,$bits(calc_direct_to_BM_t))
					  sa(.valid_us({sa_p0_us_valid,sa_p1_us_valid,sa_p2_us_valid}),
					     .stall_us({sa_p0_us_stall,sa_p1_us_stall,sa_p2_us_stall}),
					     .data_us({sa_p0_data,sa_p1_data,sa_p2_data}),
					     .valid_ds(calc_direct_to_BM_valid),
					     .stall_ds(calc_direct_to_BM_stall),
					     .data_ds(calc_direct_to_BM_data),
					     .clk,.rst);

	logic p2_stall;
	assign p2_stall = pvs2_ds_stall && 
			  ~dirpint_to_calc_direct_data.is_shadow &&
			  dirpint_to_calc_direct_data.is_miss;
	assign pvs2_valid = dirpint_to_calc_direct_valid &&
			    ~dirpint_to_calc_direct_data.is_shadow &&
			    dirpint_to_calc_direct_data.is_miss;
	assign sa_p2_us_valid = pvs2_valid;
	assign pvs2_ds_stall = sa_p2_us_stall;
	assign pvs2_ds_data.rayID = dirpint_to_calc_direct_data.rayID;
	assign pvs2_ds_data.spec = dirpint_to_calc_direct_data.spec;
	assign pvs2_ds_data.is_last = dirpint_to_calc_direct_data.is_last;
	assign pvs2_ds_data.color = `MISS_COLOR;
	
	
	assign dirpint_to_calc_direct_stall = p0_stall || p1_stall || p2_stall;


endmodule: calc_direct



// Latency = 103 cycles

module shadow_and_miss_pl(input logic clk, rst,
			  input logic v0, v1, v2,

			  input float_color_t A, C,
			  input float_color_t K,
			  input vector_t N, L, p_int,
			  output float_color_t color);



	vector_t pr_out, pr_in;
	assign pr_in = p_int;
	ff_ar_en #($bits(vector_t),0) pr(.q(pr_out),.d(pr_in),.en(v0),.clk,.rst);

	vector_t lr_out, lr_in;
	assign lr_in = L;
	ff_ar_en #($bits(vector_t),0) lr(.q(lr_out),.d(lr_in),.en(v0),.clk,.rst);

	float_color_t kr_out, kr_in;
	assign kr_in = K;
	ff_ar_en #($bits(float_color_t),0) kr(.q(kr_out),.d(kr_in),.en(v0),.clk,.rst);
	

	float_t a_add0, b_add0, negb_add0, res_add0;
	assign a_add0 = v1 ? lr_out.x : ( v2 ? lr_out.y : lr_out.z );
	assign b_add0 = v1 ? pr_out.x : ( v2 ? pr_out.y : pr_out.z );
	assign negb_add0 = {~b_add0.sign,b_add0[30:0]};
	altfp_add add0(.dataa(a_add0),.datab(b_add0),
		       .clock(clk),.aclr(rst),
		       .result(res_add0),
		       .nan(),.zero(),.underflow(),.overflow());
	// L-pint

	vector_t norm_in;
	ff_ar_en #($bits(float_t),0) lnormx(.q(norm_in.x),.d(res_add0),.en(v2),.clk,.rst);
	ff_ar_en #($bits(float_t),0) lnormy(.q(norm_in.y),.d(res_add0),.en(v0),.clk,.rst);
	ff_ar_en #($bits(float_t),0) lnormz(.q(norm_in.z),.d(res_add0),.en(v1),.clk,.rst);


	vector_t norm_out;
	norm n(.norm(norm_out),.in(norm_in),.v0(v2),.v1(v0),.v2(v1),.clk,.rst);
	// norm(L)


	vector_t norm_buf, norm_buf_in;
	assign norm_buf_in = norm_out;
	ff_ar_en #($bits(vector_t),0) bf(.q(norm_buf),.d(norm_buf_in),.en(v0),.clk,.rst);


	vector_t b0_out, b0_in;
	assign b0_in = N;
	buf_t1 #(65,$bits(vector_t)) b0(.data_out(b0_out),.data_in(b0_in),.v0,.clk,.rst );
	// delay N


	vector_t a_d, b_d;
	float_t r_d;
	assign a_d = b0_out;
	assign b_d = norm_buf;
	dot_prod d(.a(a_d),.b(b_d),.result(r_d),.v0(v1),.v1(v2),.v2(v0),.clk,.rst);
	// dot(N,L)

	
	float_t a_mult0, b_mult0, r_mult0;
	assign a_mult0 = v1 ? C.red : (v2 ? C.green : C.blue);
	assign b_mult0 = r_d;
	altfp_mult mult0(.dataa(a_mult0),.datab(b_mult0),
			 .result(r_mult0),.clock(clk),.aclr(rst),
			 .nan(),.zero(),.underflow(),.overflow());
	// C * dot(N,L)


	float_t a_add1, b_add1, res_add1;
	assign a_add1 = v0 ? A.red : (v1 ? A.green : A.blue);
	assign b_add1 = r_mult0;
	altfp_add add1(.dataa(a_add1),.datab(b_add1),
		       .result(res_add1),.clock(clk),.aclr(rst),
		       .nan(),.zero(),.overflow(),.underflow());
	// A + C*dot(N,L)


	float_t b3_out, b3_in;
	assign b3_in = v1 ? kr_out.red : ( v2 ? kr_out.green : kr_out.blue );
	buf_t3 #(96,$bits(float_t)) b3(.data_out(b3_out),.data_in(b3_in),.clk,.rst);
	// delay K

	float_t a_mult1, b_mult1, r_mult1;
	assign a_mult1 = res_add1;
	assign b_mult1 = b3_out;
	altfp_mult mult1(.dataa(a_mult1),.datab(b_mult1),
			 .result(r_mult1),.clock(clk),.aclr(rst),
			 .nan(),.zero(),.underflow(),.overflow());
	// K*( A + C*dot(N,L) )

	
	float_t r_q, g_q, b_q;	
	ff_ar_en #($bits(float_t),0) rr(.q(r_q),.d(r_mult1),.en(v1),.clk,.rst);
	
	ff_ar_en #($bits(float_t),0) gr(.q(g_q),.d(r_mult1),.en(v2),.clk,.rst);

	ff_ar_en #($bits(float_t),0) br(.q(b_q),.d(r_mult1),.en(v0),.clk,.rst);


	assign color.red = r_q;
	assign color.green = g_q;
	assign color.blue = b_q;


endmodule: shadow_and_miss_pl



