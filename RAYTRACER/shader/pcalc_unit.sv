/*
module pcalc_unit(
  input logic v0, v1, v2,
  input logic clk, rst,
  
  input logic rs_to_pcalc_valid,
  input rs_to_pcalc_t rs_to_pcalc_data,
  output logic rs_to_pcalc_stall,

  output logic pcalc_to_shader_valid,
  output pcalc_to_shader_data,
  input logic pcalc_to_shader_stall

  );
  
    input ray_vec_t vec,
	  input float_t t,
	  output vector_t pos);
 

  // pcalc math
  pcalc_math pcalc_math_inst(
  .clk, .rst,
  .v0, .v1, .v2,
  .vec(rs_to_pcalc_data.ray_vec),
  .t(rs_to_pcalc_data.t_int),
  .pos(pos_out)
  );

typedef struct packed {
  rayID_t rayID;
  bari_uv_t uv;
  float_t t_int;
  triID_t triID;
  ray_vec_t ray_vec;
} rs_to_pcalc_t;


  // pipe_VS

  struct packed {
    rayID_t rayID;
    triID_t triID;
  } pcalc_VSpipe_in, pcalc_VSpipe_out;

  logic pcalc_VSpipe_valid_us, pcalc_VSpipe_stall_us;
  logic pcalc_VSpipe_valid_ds, pcalc_VSpipe_stall_ds;
  logic [2:0] num_left_in_last_fifo;

  always_comb begin
    pcalc_VSpipe_in.rayID = rs_to_pcalc.rayID;
    pcalc_VSpipe_in.triID = rs_to_pcalc.triID;
  end
  assign pcalc_VSpipe_valid_us = rs_to_pcalc_valid;
  assign rs_to_pcalc_stall = pcalc_VSpipe_stall_us;
  

  pipe_valid_stall #(.WIDTH($bits(pcalc_VSpipe_in)), .DEPTH(4)) pcalc_VSpipe_inst(
    .clk, .rst,
    .us_valid(pcalc_VSpipe_valid_us),
    .us_data(pcalc_VSpipe_in),
    .us_stall(pcalc_VSpipe_stall_us),
    .ds_valid(pcalc_VSpipe_valid_ds),
    .ds_data(pcalc_VSpipe_out),
    .ds_stall(pcalc_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_last_fifo) );



  // Fifo
  

*/
