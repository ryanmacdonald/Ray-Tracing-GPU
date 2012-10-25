// t_comp.
/*
  This calculates an early miss with lat = 2
  This calculates a hit with lat = 21 (equal to second half of tuv_calc)

  note that tri0 is always assumed to be valid.
  therefore only need tri1_v signal

*/
module t_comp(
  input clk, rst,
  input v0, v1, v2,

  input float_t t_int0, // valid v0
  input float_t t_int1, // valid v0

  input int_pipe1_t int_pipe1_in, // valid v1

  output logic EM_miss,
  output ray_t EM_ray,

  output int_pipe2_t int_pipe2_out,
  output vector_t p_int
  );


  
  // comp_t0t1
  float_t inA_comp_t0t1, inB_comp_t0t1;
  logic out_agb_comp_t0t1;


  float_t t_int0_f0;
  float_t t_int1_f0;


  // comp_tmax
  float_t inA_comp_tmax, inB_comp_tmax;
  logic out_agb_comp_tmax;

  logic t_sel;
  
  logic tri1_valid_f1;

  logic tri0_valid_f1;

  logic t_sel_f1;
  triID_t tri0_ID_f1;
  triID_t tri1_ID_f1;

  float_t t_max_f1;
  ray_t ray_f1;

  int_pipe2_t in_buf19;
  int_pipe2_t out_buf19;

  
//////////// INSTANTIATIONS/LOGIC /////////////////

  // comp_t0101 inst
  assign inA_comp_t0t1 = t_int0;
  assign inB_comp_t0t1 = t_int1;
  altfp_compare comp_t0101 (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_t0t1 ),
  .datab(inB_comp_t0t1 ),
  //.aeb(out_aeb_comp_t0t1),
	.agb(out_agb_comp_t0t1) );

  
  ff_ar_en #($bits(float_t),'h0) t_int0_f_inst(.d(t_int0), .q(t_int0_f0), .en(v0), .clk, .rst);
  ff_ar_en #($bits(float_t),'h0) t_int1_f_inst(.d(t_int1), .q(t_int1_f0), .en(v0), .clk, .rst);

  // t_sel is 1 only if tri1 is valid and tint1 < tint0
  assign t_sel = out_agb_comp_t0t1 & int_pipe1_in.tri1_valid;

  // comp_tmax inst
  assign inA_comp_tmax = int_pipe1_in.t_max;
  assign inB_comp_tmax = v0 ? t_int0 : t_int1_f0;
  altfp_compare comp_tmax (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_tmax ),
  .datab(inB_comp_tmax ),
  //.aeb(out_aeb_comp_tmax),
	.agb(out_agb_comp_tmax) );

  // tri0_valid_f1
  ff_ar_en #(1,'h0) tri0_valid_inst(.d(out_agb_comp_tmax), .q(tri0_valid_f1), .en(v1), .clk, .rst);
  
  // tri1_valid_f1
  ff_ar_en #(1,'h0) tri1_valid_inst(.d(int_pipe1_in.tri1_valid), .q(tri1_valid_f1), .en(v1), .clk, .rst);
  
  // t_sel_f1
  ff_ar_en #(1,'h0) t_sel_f_inst(.d(t_sel), .q(t_sel_f1), .en(v1), .clk, .rst);
  
  // tri0_ID_f1
  ff_ar_en #($bits(triID_t),'h0) t_triID0_f(.d(int_pipe1_in.tri0_ID), .q(tri0_ID_f1), .en(v1), .clk, .rst);
  
  // tri1_ID_f1
  ff_ar_en #($bits(triID_t),'h0) t_triID1_f(.d(int_pipe1_in.tri1_ID), .q(tri1_ID_f1), .en(v1), .clk, .rst);

  // t_max_f1
  ff_ar_en #($bits(float_t),'h0) t_max_f(.d(int_pipe1_in.t_max), .q(t_max_f1), .en(v1), .clk, .rst);
 
  // ray_f
  ff_ar_en #($bits(ray_t),'h0) ray_f(.d(int_pipe1_in.ray), .q(ray_f1), .en(v1), .clk, .rst);

  logic tri1_valid_f1_2;
  assign tri1_valid_f1_2 = tri1_valid_f1 & out_agb_comp_tmax ;

  // EM outputs
  assign EM_miss = ~tri1_valid_f1_2 & ~tri0_valid_f1 ;
  assign EM_ray = ray_f1;

  // pipe2 buf19
  assign in_buf19.t_int0 = t_int0_f0;
  assign in_buf19.t_int1 = t_int1_f0;
  assign in_buf19.t_sel = t_sel_f1;
  assign in_buf19.t_val1 = tri1_valid_f1_2;
  assign in_buf19.t_val0 = tri0_valid_f1;
  assign in_buf19.tri0_ID = tri0_ID_f1;
  assign in_buf19.tri1_ID = tri1_ID_f1;
  assign in_buf19.t_max = t_max_f1;
  assign in_buf19.ray = ray_f1;
  buf_t1 #(.LAT(19), .WIDTH($bits(int_pipe2_t)))
    int_pipe2_buf19(.data_in(in_buf19), .data_out(out_buf19), .v0(v2), .clk, .rst);


  // P_calc inst
  // TODO This module does not make sense unless you calculate both points of intersection
  p_calc p_calc_inst(
    .clk,
    .rst,
    .v0(v1),
    .v1(v2),
    .v2(v0),
    .t_int(0),
    .origin(int_pipe1_in.ray.origin),
    .dir(int_pipe1_in.ray.dir),
    .p_int );
 

  // OUTPUTS
  assign int_pipe2_out = out_buf19;

endmodule
