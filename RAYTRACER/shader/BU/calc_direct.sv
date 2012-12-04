


// A --> Ambient light color
// K --> Color of triangle
// C --> Diffuse light color
// B --> Background color
// N --> Normal of triangle
// L --> Normal from triangle to light

module calc_direct(input logic clk, rst,
		   input logic v0, v1, v2,

		   output logic dirpint_to_calc_direct_stall,
		   input dirpint_to_calc_direct_t dirpint_to_calc_direct_data,
		   input logic dirpint_to_calc_direct_valid,

		   input logic calc_direct_to_BM_stall,
		   output calc_direct_to_BM_t calc_direct_to_BM_data,
		   output logic calc_direct_to_BM_valid);

	
	
	logic p0_stall;
	logic pvs0_us_valid, pvs0_us_stall;
	logic pvs0_ds_valid, pvs0_ds_stall;
	logic[5:0] pvs0_num_left_in_fifo;
	rayID_t pvs0_us_data, pvs0_ds_data;
	assign pvs0_us_valid = dirpint_to_calc_direct_valid &&
			       dirpint_to_calc_direct_data.is_shadow &&
			       dirpint_to_calc_direct_data.miss;
	assign pvs0_us_data = dirpint_to_calc_direct_data.rayID;
	assign p0_stall = (pvs0_us_stall || ~v0) && pvs0_us_valid;
	pipe_valid_stall3 #($bits(rayID_t),99) pvs0(.us_valid(pvs0_us_valid&&~p0_stall),
						    .us_stall(pvs0_us_stall),
						    .us_data(pvs0_us_data),
						    .ds_valid(pvs0_ds_valid),
						    .ds_stall(pvs0_ds_stall),
						    .ds_data(pvs0_ds_data),
						    .num_left_in_fifo(),
						    .clk,.rst,.v0,.v1,.v2);		

	float_t shadow_and_miss_color;
	shadow_and_miss_pl smpl(.A(dirpint_to_calc_direct_data.A),
				.C(dirpint_to_calc_direct_data.C),
				.K(dirpint_to_calc_direct_data.K),
				.N(dirpint_to_calc_direct_data.N),
				.L(dirpint_to_calc_direct_data.L),
				.p_int(dirpint_to_calc_direct_data.p_int),
				.clk,.rst,.v0,.v1,.v2,
				.color(shadow_and_miss_color));


	logic p1_stall;
	logic pvs1_us_valid, pvs1_us_stall;
	logic pvs1_ds_valid, pvs1_ds_stall;
	logic[5:0] pvs1_num_left_in_fifo;
	rayID_t pvs1_us_data, pvs1_ds_data;
	assign pvs1_us_valid = dirpint_to_calc_direct_valid &&
			       dirpint_to_calc_direct_data.is_shadow &&
			       ~dirpint_to_calc_direct_data.miss;
	assign pvs1_us_data = dirpint_to_calc_direct_data.rayID;
	assign p1_stall = (pvs1_us_stall || ~v0) && pvs1_us_valid;
	pipe_valid_stall3 #($bits(rayID_t),5) pvs1(.us_valid(pvs1_us_valid&&~p1_stall),
						    .us_stall(pvs1_us_stall),
						    .us_data(pvs1_us_data),
						    .ds_valid(pvs1_ds_valid),
						    .ds_stall(pvs1_ds_stall),
						    .ds_data(pvs1_ds_data),
						    .num_left_in_fifo(),
						    .clk,.rst,.v0,.v1,.v2);

	
	float_t shadow_and_not_miss_color;
	altfp_mult m(.dataa(dirpint_to_calc_direct_data.A),
		     .datab(dirpint_to_calc_direct_data.K),
		     .result(shadow_and_not_miss_color),
		     .clock(clk),.aclr(rst),
		     .nan(),.zero(),.underflow(),.overflow());


	logic pvs2_valid, pvs2_ds_stall;
	calc_direct_to_BM_t pvs2_ds_data;

	logic sa_p0_us_valid, sa_p1_us_valid, sa_p2_us_valid;
	logic sa_p0_us_stall, sa_p1_us_stall, sa_p2_us_stall;
	calc_direct_to_BM_t sa_p0_data, sa_p1_data, sa_p2_data;
	assign pvs0_ds_stall = sa_p0_us_stall;
	assign pvs1_ds_stall = sa_p1_us_stall;
	//assign pvs2_ds_stall =  Assigned later
	assign sa_p0_us_valid = pvs0_ds_valid;
	assign sa_p1_us_valid = pvs1_ds_valid;
	assign sa_p2_us_valid = pvs2_valid;
	assign sa_p0_data.rayID = pvs0_ds_data;
	assign sa_p0_data.color = shadow_and_miss_color;
	assign sa_p1_data.rayID = pvs1_ds_data;
	assign sa_p1_data.color = shadow_and_not_miss_color;
	assign sa_p2_data = pvs2_ds_data;
	small_arbitor #(3,$bits(calc_direct_to_BM_t))
					  sa(.valid_us({sa_p0_us_valid,sa_p1_us_valid,sa_p2_us_valid}),
					     .stall_us({sa_p0_us_stall,sa_p1_us_stall,sa_p2_us_stall}),
					     .data_us({sa_p0_data,sa_p1_data,sa_p2_data}),
					     .valid_ds(calc_direct_to_BM_valid),
					     .stall_ds(calc_direct_to_BM_valid),
					     .data_ds(calc_direct_to_BM_data),
					     .clk,.rst);

	logic p2_stall;
	assign p2_stall = pvs2_ds_stall && pvs2_valid;
	assign pvs2_valid = dirpint_to_calc_direct_valid &&
			    ~dirpint_to_calc_direct_data.is_shadow &&
			    dirpint_to_calc_direct_data.miss;
	assign pvs2_ds_stall = sa_p2_us_stall;
	assign pvs2_ds_data.rayID = dirpint_to_calc_direct_data.rayID;
	assign pvs2_ds_data.color = `MISS_COLOR;
	
	
	assign dirpint_to_calc_direct_stall = p0_stall || p1_stall || p2_stall;


endmodule: calc_direct



// Latency = 99 cycles

module shadow_and_miss_pl(input logic clk, rst,
			  input logic v0, v1, v2,

			  input float_t A, C, K,
			  input vector_t N, L, p_int,
			  output float_t color);



	float_t a_add0, b_add0, negb_add0, res_add0;
	assign a_add0 = v0 ? L.x : ( v1 ? L.y : L.z );
	assign b_add0 = v0 ? p_int.x : ( v1 ? p_int.y : p_int.z );
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
	norm n(.norm(norm_out),.in(norm_in),.v0(v1),.v1(v2),.v2(v0),.clk,.rst);
	// norm(L)


	vector_t b0_out, b0_in;
	assign b0_in = N;
	buf_t1 #(62,$bits(vector_t)) b0(.data_out(b0_out),.data_in(b0_in),.v0,.clk,.rst );
	// delay N


	vector_t a_d, b_d;
	float_t r_d;
	assign a_d = b0_out;
	assign b_d = norm_out;
	dot_prod d(.a(a_d),.b(b_d),.result(r_d),.v0(v2),.v1(v0),.v2(v1),.clk,.rst);
	// dot(N,L)

	
	float_t b1_out, b1_in;
	assign b1_in = C;
	buf_t1 #(82,$bits(float_t)) b1(.data_out(b1_out),.data_in(b1_in),.v0,.clk,.rst);
	// delay C

	
	float_t a_mult0, b_mult0, r_mult0;
	assign a_mult0 = b1_out;
	assign b_mult0 = r_d;
	altfp_mult mult0(.dataa(a_mult0),.datab(b_mult0),
			 .result(r_mult0),.clock(clk),.aclr(rst),
			 .nan(),.zero(),.underflow(),.overflow());
	// C * dot(N,L)


	float_t b2_out, b2_in;
	assign b2_in = A;
	buf_t1 #(87,$bits(float_t)) b2(.data_out(b2_out),.data_in(b2_in),.v0,.clk,.rst);
	// delay A


	float_t a_add1, b_add1, res_add1;
	assign a_add1 = b2_out;
	assign b_add1 = r_mult0;
	altfp_add add1(.dataa(a_add1),.datab(b_add1),
		       .result(res_add1),.clock(clk),.aclr(rst),
		       .nan(),.zero(),.overflow(),.underflow());
	// A + C*dot(N,L)


	float_t b3_out, b3_in;
	assign b3_in = K;
	buf_t1 #(94,$bits(float_t)) b3(.data_out(b3_out),.data_in(b3_in),.v0,.clk,.rst);
	// delay K

	float_t a_mult1, b_mult1, r_mult1;
	assign a_mult1 = res_add1;
	assign b_mult1 = b3_out;
	altfp_mult mult1(.dataa(a_mult1),.datab(b_mult1),
			 .result(r_mult1),.clock(clk),.aclr(rst),
			 .nan(),.zero(),.underflow(),.overflow());
	// K*( A + C*dot(N,L) )

	assign color = r_mult1;


endmodule: shadow_and_miss_pl



