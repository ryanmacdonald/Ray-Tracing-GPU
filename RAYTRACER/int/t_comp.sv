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


  float_t t_int0_f1;
  float_t t_int1_f1;


  // comp_tmax
  float_t inA_comp_tmax, inB_comp_tmax;
  logic out_agb_comp_tmax;

  // comp_tmin
  float_t inA_comp_tmin, inB_comp_tmin;
  logic out_agb_comp_tmin;

  
  float_t t_int;
  logic t_sel;
  triID_t triID;

  float_t t_int_f1;
  logic t_sel_f1;
  triID_t triID_f1;

  float_t t_min_f1;
  float_t t_max_f1;
  ray_t ray_f1;

  int_pipe2_t in_buf19;
  int_pipe2_t out_buf19;

  
//////////// INSTANTIATIONS/LOGIC /////////////////

  // comp_t0101 inst
  assign inA_comp_t0t1 = t_int0;
  assign inB_comp_t0t1 = t_int1;
  altfp_comp comp_t0101 (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_t0t1 ),
  .datab(inB_comp_t0t1 ),
  //.aeb(out_aeb_comp_t0t1),
	.agb(out_agb_comp_t0t1) );

  
  ff_ar_en #($bits(float_t),'h0) t_int0_f_inst(.d(t_int0), .q(t_int0_f1), .en(v0), .clk, .rst);
  ff_ar_en #($bits(float_t),'h0) t_int1_f_inst(.d(t_int1), .q(t_int1_f1), .en(v0), .clk, .rst);

  // t_sel is 1 only if tri1 is valid and tint1 < tint0
  assign t_sel = out_agb_comp_t0t1 & int_pipe1_in.tri1_valid;
  assign t_int = t_sel ? t_int1_f1 : t_int0_f1 ;
  assign triID = t_sel ? int_pipe1_in.tri1_ID : int_pipe1_in.tri0_ID ;

  // comp_tmin inst
  assign inA_comp_tmin = t_int;
  assign inB_comp_tmin = int_pipe1_in.t_min;
  altfp_comp comp_tmin (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_tmin ),
  .datab(inB_comp_tmin ),
  //.aeb(out_aeb_comp_tmin),
	.agb(out_agb_comp_tmin) );


  // comp_tmax inst
  assign inA_comp_tmax = int_pipe1_in.t_max;
  assign inB_comp_tmax = t_int;
  altfp_comp comp_tmax (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_tmax ),
  .datab(inB_comp_tmax ),
  //.aeb(out_aeb_comp_tmax),
	.agb(out_agb_comp_tmax) );


  // t_int_f1
  ff_ar_en #($bits(float_t),'h0) t_int_f_inst(.d(t_int), .q(t_int_f1), .en(v1), .clk, .rst);

  // t_sel_f1
  ff_ar_en #(1,'h0) t_sel_f_inst(.d(t_sel), .q(t_sel_f1), .en(v1), .clk, .rst);
  
  // triID_f1
  ff_ar_en #($bits(triID_t),'h0) t_triID_f(.d(triID), .q(triID_f), .en(v1), .clk, .rst);

  // t_min_f1
  ff_ar_en #($bits(float_t),'h0) t_min_f(.d(int_pipe1_in.t_min), .q(t_min_f1), .en(v1), .clk, .rst);

  // t_max_f1
  ff_ar_en #($bits(float_t),'h0) t_max_f(.d(int_pipe1_in.t_max), .q(t_max_f1), .en(v1), .clk, .rst);
 
  // ray_f
  ff_ar_en #($bits(ray_t),'h0) ray_f(.d(int_pipe1_in.ray), .q(ray_f1), .en(v1), .clk, .rst);


  // EM outputs
  assign EM_miss = ~in_buf19.t_hit;
  assign EM_ray = ray_f1;

  // pipe2 buf19
  assign in_buf19.t_int = t_int_f1;
  assign in_buf19.t_hit = out_agb_comp_tmax & out_agb_comp_tmin;
  assign in_buf19.t_sel = t_sel_f1;
  assign in_buf19.triID = triID_f1;
  assign in_buf19.t_max = t_max_f1;
  assign in_buf19.t_min = t_min_f1;
  assign in_buf19.ray = ray_f1;
  buf_t1 #(.LAT(19), .WIDTH($bits(int_pipe2_t)))
    int_pipe2_buf19(.data_in(in_buf19), .data_out(out_buf19), .v0(v2), .clk, .rst);


  // P_calc inst

  p_calc p_calc_inst(
    .clk,
    .rst,
    .v0(v1),
    .v1(v2),
    .v2(v0),
    .t_int(t_int),
    .origin(int_pipe1_in.ray.origin),
    .dir(int_pipe1_in.ray.dir),
    .p_int );
 

  // OUTPUTS
  assign int_pipe2_out = out_buf19;

endmodule
