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
  
  logic raystore_to_int_valid;
  logic raystore_to_int_stall;
  rayID_t raystore_to_int_rayID;
  raystore_to_int_t raystore_to_int_data;

  // int to shortstack EM miss
  logic int_to_shortstack_EM_valid;
  rayID_t int_to_shortstack_EM_rayID;
  logic int_to_shortstack_EM_stall;

  // int to shortstack miss
  logic int_to_shortstack_valid;
  rayID_t int_to_shortstack_rayID;
  logic int_to_shortstack_stall;
 
 
  // int to shader
  logic int_to_shader_valid;
  rayID_t int_to_shader_rayID;
  intersection_t int_to_shader_intersection;
  logic int_to_shader_stall;




  rayID_t rayID;
  color_t color_out;
  
  // TODO change this mofoooo
  localparam int_cacheline_t cache_par0 = 'hbec000003d2aaaab3eb555553e0000003e555555be6aaaab0000000000000000beaaaaabbeb555553e6aaaab3faaaaab;
  localparam int_cacheline_t cache_par1 = 'hbe95da89bd47ce0c3fbe70633d47ce0c3eaed44abed44aed0000000000000000bf7fffffbfbe70633ed44aed3fffffff;


  always_comb begin
    raystore_to_int_data.tri0_cacheline = cache_par0;
    raystore_to_int_data.tri1_cacheline = cache_par1;
    raystore_to_int_data.tri1_valid = 1'b1;
    raystore_to_int_data.t_max = 32'h42480000;
    raystore_to_int_data.tri0_ID = 2;
    raystore_to_int_data.tri1_ID = 5;
    raystore_to_int_rayID = ray_in.rayID;
    raystore_to_int_data.ray_vec.origin = ray_in.origin;
    raystore_to_int_data.ray_vec.dir = ray_in.dir;
  end

  int_unit int_unit_inst(.*);

  color_t miss_color;
  color_t hit_color;

  assign hit_color = (int_to_shader_intersection.triID=='h2) ? `COLOR1 : `COLOR2 ;
  
  assign miss_color = `COLOR0;

  assign color_out = int_to_shader_valid ? hit_color : miss_color ;
  assign rayID = int_to_shader_valid ? int_to_shader_rayID : 
                 (int_to_shortstack_valid ? int_to_shortstack_rayID : int_to_shortstack_EM_rayID);
  assign we = int_to_shader_valid | int_to_shortstack_valid | int_to_shortstack_EM_valid ;
  
  assign int_to_shader_stall = full;
  assign int_to_shortstack_stall = full;
  assign int_to_shortstack_EM_stall = full;
  
  always_comb begin
    pixel_entry_out.color = color_out;
    pixel_entry_out.rayID = rayID;
  end

endmodule




