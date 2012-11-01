/*
case(trav_case)
    0 : Traverse only low ( Do not change t_max / t_min )
    1 : Traverse only high ( Do not change t_max / t_min )
    2 : Travese low (t_max <= t_mid, t_min <= t_min)
        Push high (t_max <= t_max, t_min <= t_mid)
    3 : Travese high (t_max <= t_mid, t_min <= t_min)
        Push low (t_max <= t_max, t_min <= t_mid)
  endcase
*/



module trav_unit(
  input logic clk, rst,

  // tcache to trav
  input logic tcache_to_trav_valid,
  input tcache_to_trav_t tcache_to_trav_data,
  output logic tcache_to_trav_stall,

//////////// normal node traversal /////////////////
  // trav to rs
  output logic trav_to_rs_valid,
  output trav_to_rs_t trav_to_rs_data,
  input logic trav_to_rs_stall,


  // rs to trav
  input logic rs_to_trav_valid,
  input rs_to_trav_t rs_to_trav_data,
  output logic rs_to_trav_stall,

  // trav to ss // common port for push/update
  output logic trav_to_ss_valid,
  output trav_to_ss_t trav_to_ss_data,
  input logic trav_to_ss_stall,

  
  // trav to iarb
  output logic trav_to_iarb_valid,
  output iarb_t trav_to_iarb_data,
  input logic trav_to_iarb_stall
 ///////////////////////////////////////

///////// leaf node traversal //////////////////

   // trav to larb
  output logic trav_to_larb_valid,
  output leaf_info_t trav_to_larb_data,
  input logic trav_to_larb_stall
 
  // trav to list (with tmax)
  output logic trav_to_list_valid,
  output float_t trav_to_list_data,
  input logic trav_to_list_stall
  
  );

  logic tcache_valid;
  tcache_to_trav_t tcache_data;
  logic tcache_stall;

// Stall buffer
  VS_buf #($bits(tcache_to_trav_t)) stall_buf(.clk, .rst,
    .data_ds(tcache_data_out), 
    .valid_ds(tcache_valid),
    .stall_ds(tcache_stall),
    .data_us(tcache_to_trav_data),
    .valid_us(tcache_to_trav_valid),
    .stall_us(tcache_to_trav_stall) );


////////////////// Leaf node route /////////////////////////////
  struct packed {
    rayID_t rayID;
    float_t t_max;
    ln_tri_t ln_tri;
  } leaf_fifo_in, leaf_fifo_out,
  
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
    leaf_fifo_in.ln_tri = tcache_data_out.tree_node.leaf_node.ln_tri ;
  end

  fifo #(.WIDTH($bits(iarb_t)), .K(2)) leaf_fifo(
    .clk, .rst,
    .data_in(leaf_fifo_in),
    .data_out(leaf_fifo_out),
    .we(leaf_fifo_we),
    .re(leaf_fifo_re),
    .full(leaf_fifo_full),
    .empty(leaf_fifo_empty) );



  float_t to_list_buf, to_list_buf_n;
  logic to_list_valid, to_list_valid_n;

  leaf_info_t to_larb_buf, to_larb_buf_n;
  logic to_larb_valid, to_larb_valid_n;

  assign leaf_fifo_re = (~to_list_valid | (to_list_valid & ~trav_to_list_stall)) &
                        (~to_larb_valid | (to_larb_valid & ~trav_to_larb_stall)); 
  assign to_larb_buf_n.rayID = leaf_fifo_out.rayID;
  assign to_larb_buf_n.ln_tri = leaf_fifo_out.ln_tri;
  assign to_larb_valid_n = trav_to_larb_stall ? 1'b1 : leaf_fifo_re;
  ff_ar_en #($bits(leaf_info_t),'h0) larb_buf(.d(to_larb_buf_n), .q(to_larb_buf), .en(leaf_fifo_re), .clk, .rst);
  ff_ar #($bits(leaf_info_t),'h0) larb_valid(.d(to_larb_valid_n), .q(to_larb_valid), .clk, .rst);
  trav_to_larb_data = to_larb_buf;
  trav_to_larb_valid = to_larb_valid;


  assign to_list_buf_n.rayID = leaf_fifo_out.rayID;
  assign to_list_buf_n.t_max = leaf_fifo_out.t_max;
  assign to_list_valid_n = trav_to_list_stall ? 1'b1 : leaf_fifo_re ;
  ff_ar_en #($bits(float_t),'h0) list_buf(.d(to_list_buf_n), .q(to_list_buf), .en(leaf_fifo_re), .clk, .rst);
  ff_ar #($bits(float_t),'h0) list_valid(.d(to_list_valid_n), .q(to_list_valid), .clk, .rst);
  trav_to_list_data = to_list_buf;
  trav_to_list_valid = to_list_valid;

///////////////////////////////////// end leaf node route //////////////////////////////////////



  // trav to rs
  always_comb begin
    trav_to_rs_data.rayID = tcache_data_out.rayID;
    trav_to_rs_data.nodeID = tcache_data_out.nodeID;
    trav_to_rs_data.node = tcache_data_out.tree_node.norm_node;
    trav_to_rs_data.restnode_search = tcache_data_out.restnode_search;
    trav_to_rs_data.t_max = tcache_data_out.t_max;
    trav_to_rs_data.t_min = tcache_data_out.t_min;
  end
  assign trav_to_rs_valid = tcache_valid_in & tcache_data_out.tree_node.leaf_node.node_type != 2'b11;

  
  // rs_to_trav interface 

  // trav_math instantiation

  // pipe_stall_valid inst

  // fifo inst

  // trav_to_ss buffer and interface

  // trav_to_iarb buffer and interface

  // 0 traverse only low
  // 1 traverse only high
  // 2 traverse low and push high
  // 3 traverse high and push low
  
  logic [3:0] trav_case; 

  // rs to trav
  
  // Update stack request
  // only valid if restnode_search & (trav_case = 2 or 3)
  


endmodule
