module trav_unit(
  input logic clk, rst,

  // tcache to trav
  input logic tcache_to_trav_valid,
  input tcache_to_trav_t tcache_to_trav_data,
  output logic tcache_to_trav_stall,


  // trav to rs
  output logic trav_to_rs_valid,
  output trav_to_rs_t trav_to_rs_data,
  input logic trav_to_rs_stall,


  // rs to trav
  input logic rs_to_trav_valid,
  input rs_to_trav_t rs_to_trav_data,
  output logic rs_to_trav_stall,


  // trav to ss (push)
  output logic trav_to_ss_push_valid,
  output trav_to_ss_t trav_to_ss_push__data,
  input logic trav_to_ss_push_stall,


  // trav to ss (update)
  output logic trav_to_ss_update_valid,
  output trav_to_ss_t trav_to_ss_update__data,
  input logic trav_to_ss_update_stall,


   // trav to iarb
  output logic trav_to_iarb_valid,
  output iarb_t trav_to_iarb_data,
  input logic trav_to_iarb_stall
 

  );

  logic tcache_valid_in;
  tcache_to_trav_t tcache_data_out;
  logic tcache_stall_us;


  VS_buf #($bits(tcache_to_trav_t)) stall_buf(.clk, .rst,
    .data_ds(tcache_data_out), 
    .valid_ds(tcache_valid_in),
    .stall_ds(tcache_stall_us),
    .data_us(tcache_to_trav_data),
    .valid_us(tcache_to_trav_valid),
    .stall_us(tcache_to_trav_stall) );


  iarb_t leaf_fifo_in, leaf_fifo_out;
  logic leaf_fifo_we, leaf_fifo_re, leaf_fifo_full, leaf_fifo_empty;
  // add a small 4-wide fifo before the trav to tarb path
  
  assign leaf_fifo_we = ~leaf_fifo_full & tcache_valid_in & 
                          (tcache_data_out.tree_node.leaf_node.node_type == 2'b11);
  assign tcache_stall_us = tcache_valid_in & ( 
                            (leaf_fifo_full & tcache_data_out.tree_node.leaf_node.node_type == 2'b11) |
                            (trav_to_rs_stall & tcache_data_out.tree_node.leaf_node.node_type != 2'b11) );

  always_comb begin
    leaf_fifo_in.rayID = tcache_data_out.rayID ;
    leaf_fifo_in.t_max = tcache_data_out.t_max ;
    leaf_fifo_in.tri0_ID = tcache_data_out.tree_node.leaf_node.tri0_ID;
    leaf_fifo_in.tri1_ID = tcache_data_out.tree_node.leaf_node.tri1_ID;
    leaf_fifo_in.tri1_valid = tcache_data_out.tree_node.leaf_node.tri1_valid;
  end

  fifo #(.WIDTH($bits(iarb_t)), .K(2)) leaf_fifo(
    .clk, .rst,
    .data_in(leaf_fifo_in),
    .data_out(leaf_fifo_out),
    .we(leaf_fifo_we),
    .re(leaf_fifo_re),
    .full(leaf_fifo_full),
    .empty(leaf_fifo_empty) );

  assign trav_to_iarb_valid = ~leaf_fifo_empty ;
  assign leaf_fifo_re = trav_to_iarb_valid & ~trav_to_iarb_stall ;


  // trav to rs
  always_comb begin
    trav_to_rs_data.rayID = tcache_data_out.rayID;
    trav_to_rs_data.nodeID = tcache_data_out.nodeID;
    trav_to_rs_data.node = tcache_data_out.tree_node.norm_node;
    trav_to_rs_data.restnode_search = tcache_data_out.restnode_search;
    trav_to_rs_data.t_max = tcache_data_out.t_max;
    trav_to_rs_data.t_min = tcache_data_out.t_min;
  end



  // rs to trav
  



endmodule
