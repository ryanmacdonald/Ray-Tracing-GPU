/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/

`define COLOR0 24'h00_00_00
`define COLOR1 24'hFF_FF_00
`define COLOR2 24'hFF_00_FF

module int_wrap(
  input logic clk,
  input logic rst,
  input valid_in,
  input ray_t ray_in,
  input logic v0, v1, v2,
  
  output we,
  input full,
  output rayID_t rayID,
  output color_t color_out
  
  );
  
  
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
  ray_t ray_out;
  intersection_t intersection_out;
  //output float_t tMax,

  // Early Miss outputs
  ray_t EM_ray_out;   // Early Miss Ray 28 latency
  logic EM_miss;      // 1 if miss, 0 if hit
  
  always_comb begin
    int_pipe1_in.tri1_valid = 1'b1;
    int_pipe1_in.t_max = 32'h42480000;
    int_pipe1_in.tri0_ID = 2;
    int_pipe1_in.tri1_ID = 5;
    int_pipe1_in.ray = ray_in;
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
  assign rayID = valid_out ? ray_out.rayID : (EM_miss ? EM_ray_out.rayID : 'h0 );
  assign we = valid_out | EM_miss ;
  

endmodule




