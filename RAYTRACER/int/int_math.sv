/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/


module int_math(
  input logic clk,
  input logic rst,

  input logic v0, v1, v2,

  //inputs
  input valid_in,
  input int_cacheline_t tri0_cacheline,
  input int_cacheline_t tri1_cacheline,
  input int_pipe1_t int_pipe1_in,

  output logic valid_out,
  output logic hit_out,  // 1 if hit //0 if miss
  output ray_t ray_out,
  output intersection_t intersection_out,
  //output float_t tMax,

  // Early Miss outputs
  output ray_t EM_ray_out,   // Early Miss Ray
  output logic EM_miss      // 1 if miss, 0 if hit
  
  );
/*
  //debugshit
  shortreal originp_pc1_f;
  shortreal dirp_pc1_f;
  shortreal originp_pc0_f;
  shortreal dirp_pc0_f;
  shortreal t_intersect_tuv0_f;
  shortreal t_intersect_tuv1_f;
  shortreal u0_f, v0_f;
  shortreal u1_f, v1_f;

 always_comb begin
  originp_pc1_f = $bitstoshortreal(originp_pc1);
  dirp_pc1_f = $bitstoshortreal(dirp_pc1);
  originp_pc0_f = $bitstoshortreal(originp_pc0);
  dirp_pc0_f = $bitstoshortreal(dirp_pc0);
  t_intersect_tuv0_f = $bitstoshortreal(t_intersect_tuv0);
  t_intersect_tuv1_f = $bitstoshortreal(t_intersect_tuv1);
  u0_f = $bitstoshortreal(uv_tuv0.u);
  v0_f = $bitstoshortreal(uv_tuv0.v);
  u1_f = $bitstoshortreal(uv_tuv1.u);
  v1_f = $bitstoshortreal(uv_tuv1.v);
  end
  */
  
  
  // prime_calc0 
   vector_t origin_in_pc0;
   vector_t dir_in_pc0;
   int_cacheline_t tri_info_in_pc0;

   float_t originp_pc0;
   float_t dirp_pc0;

  // prime_calc1
   vector_t origin_in_pc1;
   vector_t dir_in_pc1;
   int_cacheline_t tri_info_in_pc1;

   float_t originp_pc1;
   float_t dirp_pc1;


  // buf27 
  int_pipe1_t buf27_out;


  // tuv_calc0
   float_t dirp_tuv0;
   float_t originp_tuv0;
   float_t t_intersect_tuv0;
   logic bari_hit_tuv0;
   bari_uv_t uv_tuv0;


  // tuv_calc1
   float_t dirp_tuv1;
   float_t originp_tuv1;
   float_t t_intersect_tuv1;
   logic bari_hit_tuv1;
   bari_uv_t uv_tuv1;


  // t_comp 
   float_t t_int0_tc;
   float_t t_int1_tc;
   int_pipe1_t int_pipe1_in_tc;
   logic EM_miss_tc;
   ray_t EM_ray_tc;
   int_pipe2_t int_pipe2_out_tc;
   vector_t p_int_tc;


  // Vbuf28
  logic valid_buf28_in;
  logic valid_buf28_out;

  // Vbuf19
  logic valid_buf19_in;
  logic valid_buf19_out;

  // Output logic



  // prime_calc0 inst
  assign origin_in_pc0 = int_pipe1_in.ray.origin;
  assign dir_in_pc0 = int_pipe1_in.ray.dir;
  assign tri_info_in_pc0 = tri0_cacheline;
  prime_calc pc0(
  .clk,
  .rst,
  .v0(v0),
  .v1(v1),
  .v2(v2),
  .origin_in(origin_in_pc0),
  .dir_in(dir_in_pc0),
  .tri_info_in(tri_info_in_pc0),
  .originp(originp_pc0),
  .dirp(dirp_pc0) );
  

  // prime_calc1 inst
  assign origin_in_pc1 = int_pipe1_in.ray.origin;
  assign dir_in_pc1 = int_pipe1_in.ray.dir;
  assign tri_info_in_pc1 = tri1_cacheline;
  prime_calc pc1(
  .clk,
  .rst,
  .v0(v0),
  .v1(v1),
  .v2(v2),
  .origin_in(origin_in_pc1),
  .dir_in(dir_in_pc1),
  .tri_info_in(tri_info_in_pc1),
  .originp(originp_pc1),
  .dirp(dirp_pc1) );


  // buf25_t1 inst
  buf_t1 #(.LAT(27), .WIDTH($bits(int_pipe1_t)))
    int_pipe2_buf27(.data_in(int_pipe1_in), .data_out(buf27_out), .v0(v0), .clk, .rst);



  // tuv_calc0 inst
  assign dirp_tuv0 = dirp_pc0;
  assign originp_tuv0 = originp_pc0;
  tuv_calc tuv0(
  .clk,
  .rst,
  .v0(v2),
  .v1(v0),
  .v2(v1),
  .dirp(dirp_tuv0),
  .originp(originp_tuv0),
  .t_intersect(t_intersect_tuv0),
  .bari_hit(bari_hit_tuv0),
  .uv(uv_tuv0) );

  
  // tuv_calc1 inst
  assign dirp_tuv1 = dirp_pc1;
  assign originp_tuv1 = originp_pc1;
  tuv_calc tuv1(
  .clk,
  .rst,
  .v0(v2),
  .v1(v0),
  .v2(v1),
  .dirp(dirp_tuv1),
  .originp(originp_tuv1),
  .t_intersect(t_intersect_tuv1),
  .bari_hit(bari_hit_tuv1),
  .uv(uv_tuv1) );

  
  // t_comp inst
  assign t_int0_tc = t_intersect_tuv0;
  assign t_int1_tc = t_intersect_tuv1;
  assign int_pipe1_in_tc = buf27_out;
  t_comp tc(
  .clk,
  .rst,
  .v0(v2),
  .v1(v0),
  .v2(v1),
  .t_int0(t_int0_tc),
  .t_int1(t_int1_tc),
  .int_pipe1_in(int_pipe1_in_tc),
  .EM_miss(EM_miss_tc),
  .EM_ray(EM_ray_tc),
  .int_pipe2_out(int_pipe2_out_tc),
  .p_int(p_int_tc) );


  // valid buf 28
  assign valid_buf28_in = valid_in;
  buf_t1 #(.LAT(28), .WIDTH(1) )
    valid_buf28(.data_in(valid_buf28_in), .data_out(valid_buf28_out), .v0(v0), .clk, .rst);

  // valid buf 19
  assign valid_buf19_in = valid_buf28_out;
  buf_t1 #(.LAT(19), .WIDTH(1) )
    valid_buf19(.data_in(valid_buf19_in), .data_out(valid_buf19_out), .v0(v1), .clk, .rst);



  // Output logic

  assign EM_ray_out = EM_ray_tc;
  assign EM_miss = EM_miss_tc & v1 & valid_buf28_out ;
  
  assign valid_out = valid_buf19_out & v2 & (int_pipe2_out_tc.t_val0 | int_pipe2_out_tc.t_val1) ; // if missed on t_comp, already early miss
  
  
  logic hit_tri0, hit_tri1, tri_hit;
  assign hit_tri0 = int_pipe2_out_tc.t_val0 & bari_hit_tuv0;
  assign hit_tri1 = int_pipe2_out_tc.t_val1 & bari_hit_tuv1;
  assign hit_out =   hit_tri0 | hit_tri1 ;
  
  assign tri_hit = ~hit_tri0 | (int_pipe2_out_tc.t_sel & hit_tri1) ; // which triangle was hit
  
  assign ray_out = int_pipe2_out_tc.ray;
  assign intersection_out.triID = tri_hit ? int_pipe2_out_tc.tri1_ID : int_pipe2_out_tc.tri0_ID;
  assign intersection_out.t_int = tri_hit ? int_pipe2_out_tc.t_int1 :  int_pipe2_out_tc.t_int0 ;
  assign intersection_out.p_int = p_int_tc;
  assign intersection_out.uv = tri_hit ? uv_tuv1 : uv_tuv0 ;



endmodule




