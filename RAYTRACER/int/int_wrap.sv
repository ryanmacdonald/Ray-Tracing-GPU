/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/

`define COLOR0 24'h11_22_33
`define COLOR1 24'h44_55_66
`define COLOR2 24'h77_88_99

module int_wrap(
  input logic clk,
  input logic rst,
  input valid_in,
  input ray_t ray_in,
  input logic v0, v1, v2,
  
  output we,
  input full,
  output pixel_buffer_entry_t pixel_entry_out
  );
  
  rayID_t rayID;
  color_t color_out;
 
  // int_math inputs
  int_cacheline_t tri0_cacheline;
  int_cacheline_t tri1_cacheline;
  int_pipe1_t int_pipe1_in;
  
  // TODO change this mofoooo
  localparam int_cacheline_t cache_par0 = 'hbec000003d2aaaab3eb555553e0000003e555555be6aaaab0000000000000000beaaaaabbeb555553e6aaaab3faaaaab;
  localparam int_cacheline_t cache_par1 = 'hbe95da89bd47ce0c3fbe70633d47ce0c3eaed44abed44aed0000000000000000bf7fffffbfbe70633ed44aed3fffffff;
//  assign cache_par0 = 'h0;
//  assign cache_par1 = 'h1;

  assign tri0_cacheline = cache_par0;
  assign tri1_cacheline = cache_par1;


  logic valid_out; // 47 lat
  logic hit_out;  // 1 if hit //0 if miss 
  rayID_t rayID_out;
  intersection_t intersection_out;
  ray_vec_t ray_vec_in;
  //output float_t tMax,

  // Early Miss outputs
  rayID_t EM_rayID_out;   // Early Miss Ray 28 latency
  logic EM_miss;      // 1 if miss, 0 if hit
  
  always_comb begin
    int_pipe1_in.tri1_valid = 1'b1;
    int_pipe1_in.t_max = 32'h42480000;
    int_pipe1_in.tri0_ID = 2;
    int_pipe1_in.tri1_ID = 5;
    int_pipe1_in.rayID = ray_in.rayID;
    ray_vec_in.origin = ray_in.origin;
    ray_vec_in.dir = ray_in.dir;
  end
  

  

  int_math int_math_inst(.*);

/*
  always_comb begin 
    $display("%b, %b", valid_out,EM_miss);
    assert(!(valid_out & EM_miss));
  end
*/
  color_t norm_color;
  color_t EM_color;
  
  assign norm_color = ~hit_out ? `COLOR0 : ((intersection_out.triID=='h2) ? `COLOR1 : `COLOR2 );


  assign EM_color = `COLOR0;

  assign color_out = valid_out ? norm_color : (EM_miss ? EM_color : `COLOR0);
  assign rayID = valid_out ? rayID_out : (EM_miss ? EM_rayID_out : 'h0 );
  assign we = valid_out | EM_miss ;
  
  always_comb begin
    pixel_entry_out.color = color_out;
    pixel_entry_out.rayID = rayID;
  end

endmodule




