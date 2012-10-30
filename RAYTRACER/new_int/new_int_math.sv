/* 
  Fully pipelined 1/1 intersection unit.
  Takes in a cacheline (Matrix + translate)
  A ray_vec
  and does a intersection test with them (t_int > epsilon && bari_test)  NO MAX test

*/

module new_int_math(
  input logic clk, rst,
  input int_cacheline_t int_cacheline,
  input ray_vec_t ray_vec,

  output logic hit,
  output float_t t_int,
  output bari_uv_t uv


  );

  // Prime calc X
  float_t mK1_x, mK2_x, mK3_x, tK_x;
  float_t originp_x, dirp_x;
  
  assign mK1_x = int_cacheline.matrix.m11;
  assign mK2_x = int_cacheline.matrix.m12;
  assign mK3_x = int_cacheline.matrix.m13;
  assign tK_x = int_cacheline.translate.x;

  prime_calc pcX(
    .clk, .rst,
    .ray_vec,
    .mK1(mK1_x),
    .mK2(mK2_x),
    .mK3(mK3_x),
    .tK(tK_x),
    .originp(originp_x),
    .dirp(dirp_x) );



  // Prime calc Y
  float_t mK1_y, mK2_y, mK3_y, tK_y;
  float_t originp_y, dirp_y;
  
  assign mK1_y = int_cacheline.matrix.m21;
  assign mK2_y = int_cacheline.matrix.m22;
  assign mK3_y = int_cacheline.matrix.m23;
  assign tK_y = int_cacheline.translate.y;

  prime_calc pcY(
    .clk, .rst,
    .ray_vec,
    .mK1(mK1_y),
    .mK2(mK2_y),
    .mK3(mK3_y),
    .tK(tK_y),
    .originp(originp_y),
    .dirp(dirp_y) );


  // Prime calc Z
  float_t mK1_z, mK2_z, mK3_z, tK_z;
  float_t originp_z, dirp_z;
  
  assign mK1_z = int_cacheline.matrix.m31;
  assign mK2_z = int_cacheline.matrix.m32;
  assign mK3_z = int_cacheline.matrix.m33;
  assign tK_z = int_cacheline.translate.z;

  prime_calc pcZ(
    .clk, .rst,
    .ray_vec,
    .mK1(mK1_z),
    .mK2(mK2_z),
    .mK3(mK3_z),
    .tK(tK_z),
    .originp(originp_z),
    .dirp(dirp_z) );



  // Divider signals
  float_t inA_div, inB_div, out_div;
  logic nan_div, overflow_div, underflow_div, zero_div, division_by_zero_div;

  assign inA_div = originp_z;
  assign inB_div = {1'b0,dirp_z[30:0]};
  altfp_div div1 (
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_div ),
  .datab(inB_div ),
  .division_by_zero(division_by_zero_div ),
  .nan(nan_div ),
  .overflow(overflow_div ),
  .result(out_div ),
  .underflow(underflow_div ),
	.zero(zero_div));


  // originp X buffer 11
  float_t oXp_in, oXp_out;
  assign oXp_in = originp_x;
  buf_t3 #(.LAT(11), .WIDTH($bits(float_t))) 
    oXp_buf11(.data_in(oXp_in), .data_out(oXp_out), .clk, .rst);


  // dirp X buffer 6
  float_t dXp_in, dXp_out;
  buf_t3 #(.LAT(6), .WIDTH($bits(float_t))) 
    dXp_buf6(.data_in(dXp_in), .data_out(dXp_out), .clk, .rst);


   // Multiply signals
  float_t inA_mult_x, inB_mult_x, out_mult_x;
  logic nan_mult_x, overflow_mult_x, underflow_mult_x, zero_mult_x;
 
  assign inA_mult_x = dXp_out;
  assign inB_mult_x = out_div;
  altfp_mult mult_x (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_x),
  .datab(inB_mult_x),
  .nan(nan_mult_x ),
  .overflow(overflow_mult_x ),
  .result(out_mult_x ),
  .underflow(underflow_mult_x ),
	.zero(zero_mult_x));


  // Add X
  float_t inA_add_x, inB_add_x, out_add_x;
  logic nan_add_x, overflow_add_x, underflow_add_x, zero_add_x;

  assign inA_add_x = oXp_out;
  assign inB_add_x = out_mult_x;
  altfp_add add_x(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_x ),
  .datab(inB_add_x ),
  .nan(nan_add_x ),
  .overflow(overflow_add_x ),
  .result(out_add_x ),
  .underflow(underflow_add_x ),
	.zero(zero_add_x) );



  // originp Y buffer 11
  float_t oYp_in, oYp_out;
  assign oYp_in = originp_y;
  buf_t3 #(.LAT(11), .WIDTH($bits(float_t))) 
    oYp_buf11(.data_in(oYp_in), .data_out(oYp_out), .clk, .rst);


  // dirp Y buffer 6
  float_t dYp_in, dYp_out;
  buf_t3 #(.LAT(6), .WIDTH($bits(float_t))) 
    dYp_buf6(.data_in(dYp_in), .data_out(dYp_out), .clk, .rst);


   // Multiply signals
  float_t inA_mult_y, inB_mult_y, out_mult_y;
  logic nan_mult_y, overflow_mult_y, underflow_mult_y, zero_mult_y;
 
  assign inA_mult_y = dYp_out;
  assign inB_mult_y = out_div;
  altfp_mult mult_y (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_y),
  .datab(inB_mult_y),
  .nan(nan_mult_y ),
  .overflow(overflow_mult_y ),
  .result(out_mult_y ),
  .underflow(underflow_mult_y ),
	.zero(zero_mult_y));


  // Add Y
  float_t inA_add_y, inB_add_y, out_add_y;
  logic nan_add_y, overflow_add_y, underflow_add_y, zero_add_y;

  assign inA_add_y = oYp_out;
  assign inB_add_y = out_mult_y;
  altfp_add add_y(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_y ),
  .datab(inB_add_y ),
  .nan(nan_add_y ),
  .overflow(overflow_add_y ),
  .result(out_add_y ),
  .underflow(underflow_add_y ),
	.zero(zero_add_y) );


  // Add bary
  float_t inA_bary, inB_bary, out_bary;
  logic nan_bary, overflow_bary, underflow_bary, zero_bary;

  assign inA_bary = out_add_x;
  assign inB_bary = out_add_y;
  altfp_add bary(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_bary ),
  .datab(inB_bary ),
  .nan(nan_bary ),
  .overflow(overflow_bary ),
  .result(out_bary ),
  .underflow(underflow_bary ),
	.zero(zero_bary) );

/* Just need to add t_int buf19,
  uv buf8, 
  out_bary < 1
  t_int > eps
  t_int flop

*/

  float_t t_int_buf_in, t_int_buf_out;
  assign t_int_buf_in = out_div;
  buf_t3 #(.LAT(19), .WIDTH($bits(float_t))) 
    t_int_buf19(.data_in(t_int_buf_in), .data_out(t_int_buf_out), .clk, .rst);

  bari_uv_t bary_in, bary_out ;
  assign bary_in.u = out_add_x ;
  assign bary_in.v = out_add_y ;
  buf_t3 #(.LAT(8), .WIDTH($bits(bari_uv_t))) 
    bary_buf8(.data_in(bary_in), .data_out(bary_out), .clk, .rst);
 

// comp1
  float_t inA_comp1, inB_comp1;
  logic out_agb_comp1;
  assign inA_comp1 = `FP_1;
  assign inB_comp1 = out_bary ;
  altfp_compare comp1 (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp1 ),
  .datab(inB_comp1 ),
  //.aeb(out_aeb_comp1),
	.agb(out_agb_comp1) );

  
  ff_ar #($bits(float_t),'h0) t_reg_inst(.d(t_int_buf_out), .q(t_int), .clk, .rst);


   float_t inA_comp_ep, inB_comp_ep;
  logic out_agb_comp_ep;
  assign inA_comp_ep = t_int_buf_out;
  assign inB_comp_ep = `EPSILON ;
  altfp_compare comp_ep (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_ep ),
  .datab(inB_comp_ep ),
  //.aeb(out_aeb_comp_ep),
	.agb(out_agb_comp_ep) );
 

  // outputs
  assign hit = out_agb_comp1 & out_agb_comp_ep & ~uv.u.sign & ~uv.v.sign ;
  // t_int is already register
  assign uv = bary_out;



endmodule



