/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/



module tb_int_math(
  logic clk,
  logic rst,

  logic v0, v1, v2,

  Int_cacheline_t tri0_cacheline;
  TriID_t tri0_ID;
  Int_cacheline_t tri1_cacheline;
  TriID_t tri1_ID;
  Ray_t ray_in;

  logic hit_out;  // 1 if hit (valid ray/intersection)
  Ray_t ray_out;
  Intersection_t intersection_out;

  Ray_t EM_ray_out;   // Early Miss Ray
  Ray_t EM_miss;      // 1 if miss, (valid missed ray)

  

  int_math int_math_inst(.*);
  
  
  logic cnt;
  


  




endmodule
