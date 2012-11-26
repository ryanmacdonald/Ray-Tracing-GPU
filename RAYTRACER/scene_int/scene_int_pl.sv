 



//////////////** SCENE INTERSECTION UNIT **/////////////

// Takes in a primary ray and outputs tmin, tmax values
// based on the scene bounding box.

module scene_int_pl(input shader_to_sint_t ray,
		 input v0, v1, v2,
		 input float_t xmin, xmax,
		 input float_t ymin, ymax,
		 input float_t zmin, zmax,
		 input logic isShadow,
		 input logic clk, rst,
		 output float_t tmin_scene, tmax_scene,
		 output logic miss);

	`ifndef SYNTH
		shortreal tmin_sr, tmax_sr;
		assign tmin_sr = $bitstoshortreal(tmin_scene);
		assign tmax_sr = $bitstoshortreal(tmax_scene);
	`endif

	
	float_t dataa_add1_pos, dataa_add1_neg, datab_add1, result_add1;
	assign dataa_add1_pos = v0 ? ray.ray_vec.origin.x : (v1 ? ray.ray_vec.origin.y : ray.ray_vec.origin.z);
	assign dataa_add1_neg = {~dataa_add1_pos.sign,dataa_add1_pos[30:0]};
	assign datab_add1 = v0 ? xmin : (v1 ? ymin : zmin);
	altfp_add add1(.aclr(rst),.clock(clk),
		       .dataa(dataa_add1_neg),.datab(datab_add1),.nan(),
		       .overflow(),.result(result_add1),
	 	       .underflow(),.zero());


	float_t dataa_add2_pos, datab_add2, dataa_add2_neg, result_add2;
	assign dataa_add2_pos = v0 ? ray.ray_vec.origin.x : (v1? ray.ray_vec.origin.y: ray.ray_vec.origin.z);
	assign dataa_add2_neg = {~dataa_add2_pos.sign,dataa_add2_pos[30:0]};
	assign datab_add2 = v0 ? xmax : (v1 ? ymax : zmax);
	altfp_add add2(.aclr(rst),.clock(clk),
		       .dataa(dataa_add2_neg),.datab(datab_add2),.nan(),
		       .overflow(),.result(result_add2),
		       .underflow(),.zero());



	float_t dirbuf_in, dirbuf_out;
	assign dirbuf_in = v0 ? ray.ray_vec.dir.x : (v1 ? ray.ray_vec.dir.y : ray.ray_vec.dir.z);
	buf_t3 #(7,$bits(float_t)) dirbuf(.data_out(dirbuf_out),.data_in(dirbuf_in),.clk,.rst);
	

	float_t dataa_div1, datab_div1, result_div1;
	assign dataa_div1 = result_add1;
	assign datab_div1 = dirbuf_out;
	altfp_div div1(.aclr(rst),.clock(clk),
		       .dataa(dataa_div1),.datab(datab_div1),.division_by_zero(),
		       .nan(),.overflow(),.result(result_div1),.underflow(),.zero());


	float_t dataa_div2, datab_div2, result_div2;
	assign dataa_div2 = result_add2;
	assign datab_div2 = dirbuf_out;
	altfp_div div2(.aclr(rst),.clock(clk),
		       .dataa(dataa_div2),.datab(datab_div2),.division_by_zero(),
		       .nan(),.overflow(),.result(result_div2),.underflow(),.zero());

	logic signbuf_in, signbuf_out;
	assign signbuf_in = dirbuf_out.sign;
	buf_t3 #(6,1) signbuf(.data_out(signbuf_out),.data_in(signbuf_in),.clk,.rst);
	

	// Signal declarations for regs and fp comparators //

	float_t q_r1, d_r1;
	float_t q_r2, d_r2;
	float_t q_r3, d_r3;
	float_t q_r4, d_r4;
	float_t q_r5, d_r5;
	logic q_r6, d_r6;
	float_t q_r7, d_r7;
	float_t q_r8, d_r8;
	logic q_r9, d_r9;
	float_t dataa_cmp1, datab_cmp1;
	float_t q_r10, d_r10;
	logic agb_cmp1;
	float_t dataa_cmp2, datab_cmp2;
	logic agb_cmp2;
	float_t dataa_cmp3, datab_cmp3;
	logic agb_cmp3;
	float_t dataa_cmp4, datab_cmp4;
	logic agb_cmp4;
	float_t dataa_cmp5, datab_cmp5;
	logic agb_cmp5;
	float_t dataa_cmp6, datab_cmp6;
	logic agb_cmp6;
	float_t dataa_cmp7, datab_cmp7;
	logic agb_cmp7;
	float_t dataa_cmp8, datab_cmp8;
	logic agb_cmp8;
	float_t dataa_cmp9, datab_cmp9;
	logic agb_cmp9;
	float_t dataa_cmp10, datab_cmp10;
	logic agb_cmp10;
	float_t dataa_cmp11, datab_cmp11;
	logic agb_cmp11;


	assign d_r1 = signbuf_out ? result_div2 : result_div1;
	ff_ar #($bits(float_t),0) r1(.q(q_r1),.d(d_r1),.clk(clk),.rst(rst));

	
	assign d_r2 = signbuf_out ? result_div1 : result_div2;
	ff_ar #($bits(float_t),0) r2(.q(q_r2),.d(d_r2),.clk(clk),.rst(rst));

	
	assign d_r3 = q_r1;
	ff_ar #($bits(float_t),0) r3(.q(q_r3),.d(d_r3),.clk(clk),.rst(rst));

	
	assign d_r4 = q_r2;
	ff_ar #($bits(float_t),0) r4(.q(q_r4),.d(d_r4),.clk(clk),.rst(rst));

	
	assign d_r5 = agb_cmp1 ? q_r3 : d_r3;
	ff_ar #($bits(float_t),0) r5(.q(q_r5),.d(d_r5),.clk(clk),.rst(rst));

	
	assign d_r6 = agb_cmp2 || agb_cmp3;
	ff_ar #(1,0) r6(.q(q_r6),.d(d_r6),.clk(clk),.rst(rst));

  // CHanged from r2
	assign d_r7 = agb_cmp4 ? q_r4 : d_r4;
	ff_ar #($bits(float_t),0) r7(.q(q_r7),.d(d_r7),.clk(clk),.rst(rst));


	assign d_r8 = agb_cmp5 ? q_r5 : q_r1;
	ff_ar #($bits(float_t),0) r8(.q(q_r8),.d(d_r8),.clk(clk),.rst(rst));


	assign d_r9 = q_r6 || agb_cmp6 || agb_cmp7;
	ff_ar #(1,0) r9(.q(q_r9),.d(d_r9),.clk(clk),.rst(rst));


	assign d_r10 = agb_cmp8 ? q_r7 : q_r2;
	ff_ar #($bits(float_t),0) r10(.q(q_r10),.d(d_r10),.clk(clk),.rst(rst));


	assign dataa_cmp1 = q_r1; //tmin
	assign datab_cmp1 = d_r1; // tymin
	altfp_compare cmp1(.aclr(rst),.clock(clk),.dataa(dataa_cmp1),.datab(datab_cmp1),.agb(agb_cmp1),.aeb());
  // tmin > tymin

	assign dataa_cmp2 = q_r1;
	assign datab_cmp2 = d_r2;
	altfp_compare cmp2(.aclr(rst),.clock(clk),.dataa(dataa_cmp2),.datab(datab_cmp2),.agb(agb_cmp2),.aeb());
	

	assign dataa_cmp3 = d_r1;
	assign datab_cmp3 = q_r2;
	altfp_compare cmp3(.aclr(rst),.clock(clk),.dataa(dataa_cmp3),.datab(datab_cmp3),.agb(agb_cmp3),.aeb());
	
  // SKETCHY  could be wrong
	assign dataa_cmp4 = d_r2; // tymax
	assign datab_cmp4 = q_r2; // tmax
	altfp_compare cmp4(.aclr(rst),.clock(clk),.dataa(dataa_cmp4),.datab(datab_cmp4),.agb(agb_cmp4),.aeb());
  // tymax > tmax

	assign dataa_cmp5 = d_r5; // tmin
	assign datab_cmp5 = d_r1; // tzmin
	altfp_compare cmp5(.aclr(rst),.clock(clk),.dataa(dataa_cmp5),.datab(datab_cmp5),.agb(agb_cmp5),.aeb());
  // tmin > tzmin

	assign dataa_cmp6 = d_r5; //tmin
	assign datab_cmp6 = d_r2; // tzmax
	altfp_compare cmp6(.aclr(rst),.clock(clk),.dataa(dataa_cmp6),.datab(datab_cmp6),.agb(agb_cmp6),.aeb());
  // tmin > tzmax

	assign dataa_cmp7 = d_r1; // Tzmin 
	assign datab_cmp7 = d_r7; // tmax
	altfp_compare cmp7(.aclr(rst),.clock(clk),.dataa(dataa_cmp7),.datab(datab_cmp7),.agb(agb_cmp7),.aeb());
  // tzmin > tmax

	assign dataa_cmp8 = d_r2; // tzmax
	assign datab_cmp8 = d_r7; // tmax
	altfp_compare cmp8(.aclr(rst),.clock(clk),.dataa(dataa_cmp8),.datab(datab_cmp8),.agb(agb_cmp8),.aeb());
	// tzmax > tmax

	assign dataa_cmp9 = d_r8;
	assign datab_cmp9 = `EPSILON;
	altfp_compare cmp9(.aclr(rst),.clock(clk),.dataa(dataa_cmp9),.datab(datab_cmp9),.agb(agb_cmp9),.aeb());


	assign dataa_cmp10 = d_r10;
	assign datab_cmp10 = `FP_1 ; 
	altfp_compare cmp10(.aclr(rst),.clock(clk),.dataa(dataa_cmp10),.datab(datab_cmp10),.agb(agb_cmp10),.aeb());
  // tmax > 1.0

	assign dataa_cmp11 = `EPSILON;
	assign datab_cmp11 = d_r10;
	altfp_compare cmp11(.aclr(rst),.clock(clk),.dataa(dataa_cmp11),.datab(datab_cmp11),.agb(agb_cmp11),.aeb());
	// EPSILON > tmax?

	assign miss = q_r9 || agb_cmp11;

	assign tmin_scene = agb_cmp9 ? q_r8 : `EPSILON;

	assign tmax_scene = agb_cmp10&&~isShadow ?  q_r10 : `FP_1;


endmodule: scene_int_pl




