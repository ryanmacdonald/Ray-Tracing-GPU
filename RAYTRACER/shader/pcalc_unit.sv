
module pcalc_unit(
  input logic v0, v1, v2,
  input logic clk, rst,
  
  input logic rs_to_pcalc_valid,
  input rs_to_pcalc_t rs_to_pcalc_data,
  output logic rs_to_pcalc_stall,

  output logic pcalc_to_shader_valid,
  output pcalc_to_shader_t pcalc_to_shader_data,
  input logic pcalc_to_shader_stall,
  
  input ray_vec_t vec,
  input float_t t,
  output vector_t pos);
 

  vector_t pos_out;

  // pcalc math
  pcalc_math pcalc_math_inst(
  .clk, .rst,
  .v0, .v1, .v2,
  .vec(rs_to_pcalc_data.ray_vec),
  .t(rs_to_pcalc_data.t_int),
  .pos(pos_out)
  );


  // pipe_VS

  struct packed {
    rayID_t rayID;
    triID_t triID;
    vector_t dir;
  } pcalc_VSpipe_in, pcalc_VSpipe_out;

  logic pcalc_VSpipe_valid_us, pcalc_VSpipe_stall_us;
  logic pcalc_VSpipe_valid_ds, pcalc_VSpipe_stall_ds;
  logic [2:0] num_left_in_pcalc_fifo;

  always_comb begin
    pcalc_VSpipe_in.rayID = rs_to_pcalc.rayID;
    pcalc_VSpipe_in.triID = rs_to_pcalc.triID;
    pcalc_VSpipe_in.dir = rs_to_pcalc.ray_vec.dir;
  end
  assign pcalc_VSpipe_valid_us = rs_to_pcalc_valid;
  assign rs_to_pcalc_stall = pcalc_VSpipe_stall_us;
  

  pipe_valid_stall1 #(.WIDTH($bits(pcalc_VSpipe_in)), .DEPTH(16)) pcalc_VSpipe_inst(
    .clk, .rst, .v0, 
    .us_valid(pcalc_VSpipe_valid_us),
    .us_data(pcalc_VSpipe_in),
    .us_stall(pcalc_VSpipe_stall_us),
    .ds_valid(pcalc_VSpipe_valid_ds),
    .ds_data(pcalc_VSpipe_out),
    .ds_stall(pcalc_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_pcalc_fifo) );

  
  pcalc_to_shader_t pcalc_fifo_in, pcalc_fifo_out;

  // fifo to accumulate Definite misses and definite hits
  logic pcalc_fifo_full;
  logic pcalc_fifo_empty;
  logic pcalc_fifo_re;
  logic pcalc_fifo_we;
  always_comb begin
    pcalc_fifo_in.rayID = list_VSpipe_out.rayID ;
    pcalc_fifo_in.triID = list_VSpipe_out.triID ;
    pcalc_fifo_in.p_int = pos_out ;
    pcalc_fifo_in.dir = list_VSpipe_out.dir ;
  end
  assign pcalc_fifo_we = pcalc_VSpipe_valid_ds;

  fifo #(.DEPTH(6), .WIDTH($bits(pcalc_to_shader_t)) ) pcalc_fifo_inst(
    .clk, .rst,
    .data_in(pcalc_fifo_in),
    .data_out(pcalc_fifo_out),
    .full(pcalc_fifo_full),
    .empty(pcalc_fifo_empty),
    .re(pcalc_fifo_re),
    .we(pcalc_fifo_we),
    .num_left_in_fifo(num_left_in_pcalc_fifo),
    .exists_in_fifo());
 
    assign pcalc_to_shader_valid = ~pcalc_fifo_empty;
    assign pcalc_to_shader_data = pcalc_fifo_out;
    assign pcalc_fifo_re = pcalc_to_shader_valid & ~pcalc_to_shader_stall ;


endmodule
