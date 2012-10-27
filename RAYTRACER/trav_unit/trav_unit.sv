module trav_unit(
  input logic clk, rst,

  // tcache to trav
  input logic tcache_to_trav_valid;
  input tree_node_t tcache_to_trav_node;
  input nodeID_t tcache_to_trav_nodeID;
  input rayID_t tcache_to_trav_rayID;
  output tcache_to_trav_stall;

  // trav to raystore
  output logic trav_to_raystore_valid;
  output norm_node_t trav_to_raystore_node;
  output rayID_t trav_to_raystore_rayID;
  input logic trav_to_raystore_stall;

  // raystore to trav
  input logic raystore_to_trav_valid;
  input raystore_t raystore_to_trav_data;
  input rayID_t raystore_to_trav_rayID;
  output logic raystore_to_trav_stall;

  // trav to shortstack
  output logic trav_to_shortstack_valid;
  output nodeID_t trav_to_shortstack_node;
  output rayID_t trav_to_shortstack_rayID;
  input logic trav_to_shortstack_stall;

  // trav to tarb
  output logic trav_to_tarb_valid;
  output norm_node_t trav_to_tarb_node;
  output rayID_t trav_to_tarb_rayID;
  input logic trav_to_tarb_stall;


  );

  // Buffer tcache to trav
  struct packed {
    tree_node_t node;
    nodeID_t nodeID;
    rayID_t rayID;
  } data_in, data_out;
  logic valid_in;
  logic stall_us;

  VS_buf #($bits(data_in)) (.clk, .rst,
    .data_ds(data_in, 
    .valid_ds(valid_in),
    .stall_ds(stall_us),
    .data_us(data_in),
    .valid_us(tcache_to_trav_valid),
    .stall_us(tcache_to_trav_stall) );

  

endmodule
