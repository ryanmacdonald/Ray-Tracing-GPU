/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/



module int_math(
  input logic clk,
  input logic rst,

  input logic v0, v1, v2,

  //inputs
  input Int_cacheline_t tri0_cacheline;
  input TriID_t tri0_ID;
  input Int_cacheline_t tri1_cacheline;
  input TriID_t tri1_ID;
  input Ray_t ray_in;

  output logic hit_out;  // 1 if hit
  output Ray_t ray_out;
  output Intersection_t intersection_out;

  // Early Miss outputs
  output Ray_t EM_ray_out;   // Early Miss Ray
  output Ray_t EM_miss;      // 1 if miss, 0 if hit


  // prime_calc0 -> t_uv_calc0


  // prime_calc1 -> t_uv_calc1


  // buf25 -> t_comp


  // tuv_calc0/1 -> t_comp


  // tuv_calc0/1 -> output logic


  // t_comp -> output logic



  // Output logic



  // prime_calc0/1 inst


  // buf25_t1 inst


  //tuv_calc0/1 inst

  
  // t_comp inst

endmodule
