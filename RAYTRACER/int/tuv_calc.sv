// tuv_calc.
/*
  This calculates t with lat = 6
  calculates u and v and deterimes if it is a bari_hit
  
  Functionally this can be thought as intersecting the Ray (originp,dirp) with the unit triangle
  located at (0,0,0) , (1,0,0), (0,1,0)

*/

module tuv_calc(
  input clk, rst,
  input v0, v1, v2,

  input float_t dirp,
  input float_t originp,

  output float_t t_intersect, // 6 cyclle lat
  
  output logic bari_hit, // 27
  output bari_uv_t uv
  );


  // Divider signals
  float_t inA_div, inB_div, out_div;
  logic nan_div, overflow_div, underflow_div, zero_div, division_by_zero_div;

  // Multiply signals
  float_t inA_mult, inB_mult, out_mult;
  logic nan_mult, overflow_mult, underflow_mult, zero_mult;

  // Add1
  float_t inA_add1, inB_add1, out_add1;
  logic nan_add1, overflow_add1, underflow_add1, zero_add1;

  // Add2
  float_t inA_add2, inB_add2, out_add2;
  logic nan_add2, overflow_add2, underflow_add2, zero_add2;

  // dirp_buf5
  float_t dirp_buf5_in;
  float_t dirp_buf5_out;

  // originp_buf10
  float_t originp_buf10_in;
  float_t originp_buf10_out;

  // t_reg
  float_t t_reg;
  
  // v_reg
  float_t v_reg;

  // comp0
  float_t inA_comp0, inB_comp0;
  logic out_agb_comp0;

  // v_comp0_ff
  logic v_comp0_ff;

  // comp1
  float_t inA_comp1, inB_comp1;
  logic out_agb_comp1;

  // uv_buf8
  bari_uv_t uv_buf8_in;
  bari_uv_t uv_buf8_out;

  // comp0_buf7
  logic comp0_buf7_in;
  logic comp0_buf7_out;

//////////// INSTANTIATIONS/LOGIC /////////////////

  // dirp_buf5 inst
  assign dirp_buf5_in = dirp;
  buf_t3 #(.LAT(5), .WIDTH($bits(float_t))) 
    dirp_buf5(.data_in(dirp_buf5_in), .data_out(dirp_buf5_out), .clk, .rst);

  // originp_buf inst
  assign originp_buf10_in = originp;
  buf_t3 #(.LAT(10), .WIDTH($bits(float_t)))
    originp_buf10(.data_in(originp_buf10_in), .data_out(originp_buf10_out), .clk, .rst);


  // div inst // TODO Check to see if it is A/B or B/A
  assign inA_div = {1'b1,originp[30:0]};
  assign inB_div = dirp;
  
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

  assign t_intersect = out_div;

  // t_reg inst // TODO is it really v0?
  ff_ar_en #($bits(float_t),'h0) t_reg_inst(.d(out_div), .q(t_reg), .en(v0), .clk, .rst);
  

  // mult inst // TODO is it v0
  assign inA_mult = dirp_buf5_out;
  assign inB_mult = v0 ? out_div : t_reg ;

  altfp_mult mult(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_mult ),
  .datab(inB_mult ),
  .nan(nan_mult ),
  .overflow(overflow_mult ),
  .result(out_mult ),
  .underflow(underflow_mult ),
	.zero(zero_mult));



  // add1 inst
  assign inA_add1 = out_mult ;
  assign inB_add1 = originp_buf10_out;

  altfp_add add1(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add1 ),
  .datab(inB_add1 ),
  .nan(nan_add1 ),
  .overflow(overflow_add1 ),
  .result(out_add1 ),
  .underflow(underflow_add1 ),
	.zero(zero_add1) );

  

  // v_reg inst // TODO is it v0? (18)
  ff_ar_en #($bits(float_t),'h0) v_reg_inst(.d(out_add1), .q(v_reg), .en(v0), .clk, .rst);


  // add2 inst
  assign inA_add2 = out_add1;
  assign inB_add2 = v_reg;

  altfp_add add2(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add2 ),
  .datab(inB_add2 ),
  .nan(nan_add2 ),
  .overflow(overflow_add2 ),
  .result(out_add2 ),
  .underflow(underflow_add2 ),
	.zero(zero_add2) );



  // comp0 inst  (u/v > 0) 
  assign inA_comp0 = out_add1;
  assign inB_comp0 = `FP_0;
  
  altfp_comp comp0 (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp0 ),
  .datab(inB_comp0 ),
  //.aeb(out_aeb_comp0),
	.agb(out_agb_comp0) );


  // comp1 inst (1 > u+v)
  assign inA_comp1 = `FP_1;
  assign inB_comp1 = out_add2;
  
  altfp_comp comp1 (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp1 ),
  .datab(inB_comp1 ),
  //.aeb(out_aeb_comp1),
	.agb(out_agb_comp1) );



  // v_comp0_ff // TODO is it v1? (19)
  ff_ar_en #(1,'h0) v_comp0_ff_inst(.d(out_agb_comp0), .q(v_comp0_ff), .en(v1), .clk, .rst);


  // comp0_buf7
  assign comp0_buf7_in = out_agb_comp0 & v_comp0_ff; // u>0 && v>0
  
  buf_t1 #(.LAT(7), .WIDTH(1)) // TODO is it really v2
    comp0_buf7(.data_in(comp0_buf7_in), .data_out(comp0_buf7_out), .v0(v2), .clk, .rst);


  // uv_buf8
  assign uv_buf8_in = {out_add1,v_reg};
  buf_t1 #(.LAT(8), .WIDTH($bits(bari_uv_t))) // TODO is it really v1
    uv_buf8(.data_in(uv_buf8_in), .data_out(uv_buf8_out), .v0(v1), .clk, .rst);


  // Output assigns //TODO should this be v0?
  assign bari_hit = out_agb_comp1 & comp0_buf7_out & v0;  
  assign uv = uv_buf8_out;


endmodule
