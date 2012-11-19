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

  // trav to ss // common port for push/pop/update
  output logic trav_to_ss_valid,
  output trav_to_ss_t trav_to_ss_data,
  input logic trav_to_ss_stall,
  
  // trav to tarb
  output logic trav_to_tarb_valid,
  output tarb_t trav_to_tarb_data,
  input logic trav_to_tarb_stall,
 ///////////////////////////////////////

///////// leaf node traversal //////////////////

   // trav to larb
  output logic trav_to_larb_valid,
  output leaf_info_t trav_to_larb_data,
  input logic trav_to_larb_stall,
 
  // trav to list (with tmax)
  output logic trav_to_list_valid,
  output trav_to_list_t trav_to_list_data,
  input logic trav_to_list_stall
  
  );

  logic tcache_valid;
  tcache_to_trav_t tcache_data;
  logic tcache_stall;

// Stall buffer
  VS_buf #($bits(tcache_to_trav_t)) stall_buf(.clk, .rst,
    .data_ds(tcache_data), 
    .valid_ds(tcache_valid),
    .stall_ds(tcache_stall),
    .data_us(tcache_to_trav_data),
    .valid_us(tcache_to_trav_valid),
    .stall_us(tcache_to_trav_stall) );


////////////////// Leaf node route /////////////////////////////
  struct packed {
    ray_info_t ray_info;
    float_t t_max;
    ln_tri_t ln_tri;
  } leaf_fifo_in, leaf_fifo_out;
  
  logic leaf_fifo_we, leaf_fifo_re, leaf_fifo_full, leaf_fifo_empty;
  // add a small 4-wide fifo before the trav to tarb path
  
  assign leaf_fifo_we = ~leaf_fifo_full & tcache_valid & 
                          (tcache_data.tree_node.node_type == 2'b11);
  assign tcache_stall = tcache_valid & ( 
                            (leaf_fifo_full & tcache_data.tree_node.node_type == 2'b11) |
                            (trav_to_rs_stall & tcache_data.tree_node.node_type != 2'b11) );

  leaf_node_t leaf_node_tmp;
  assign leaf_node_tmp = leaf_node_t'(tcache_data.tree_node);


  always_comb begin
    leaf_fifo_in.ray_info = tcache_data.ray_info ;
    leaf_fifo_in.t_max = tcache_data.t_max ;
    leaf_fifo_in.ln_tri = leaf_node_tmp.ln_tri ;
  end

  fifo #(.WIDTH($bits(leaf_fifo_in)), .DEPTH(8)) leaf_fifo(
    .clk, .rst,
    .data_in(leaf_fifo_in),
    .data_out(leaf_fifo_out),
    .we(leaf_fifo_we),
    .re(leaf_fifo_re),
    .full(leaf_fifo_full),
    .empty(leaf_fifo_empty),
    .num_left_in_fifo(),
    .exists_in_fifo());



  trav_to_list_t to_list_buf, to_list_buf_n;
  logic to_list_valid, to_list_valid_n;

  leaf_info_t to_larb_buf, to_larb_buf_n;
  logic to_larb_valid, to_larb_valid_n;

  assign leaf_fifo_re = ~leaf_fifo_empty & (~to_list_valid | ~trav_to_list_stall) &
                                           (~to_larb_valid | ~trav_to_larb_stall); 
  always_comb begin
    if(trav_to_larb_stall) to_larb_buf_n = to_larb_buf;
    else begin
      to_larb_buf_n.ray_info = leaf_fifo_out.ray_info;
      to_larb_buf_n.ln_tri = leaf_fifo_out.ln_tri;
    end
  end

  assign to_larb_valid_n = (trav_to_larb_stall & to_larb_valid) | leaf_fifo_re;
  

  ff_ar_en #($bits(leaf_info_t),'h0) larb_buf(.d(to_larb_buf_n), .q(to_larb_buf), .en(leaf_fifo_re), .clk, .rst);
  ff_ar #(1,'h0) larb_valid(.d(to_larb_valid_n), .q(to_larb_valid), .clk, .rst);
  
  assign trav_to_larb_data = to_larb_buf;
  assign trav_to_larb_valid = to_larb_valid;

  always_comb begin
    if(trav_to_list_stall) to_list_buf_n = to_list_buf;
    else begin
      to_list_buf_n.rayID = leaf_fifo_out.ray_info.rayID;
      to_list_buf_n.t_max_leaf = leaf_fifo_out.t_max;
    end
  end

  assign to_list_valid_n = (trav_to_list_stall & to_list_valid) | leaf_fifo_re ;
  
  ff_ar_en #($bits(trav_to_list_t),'h0) list_buf(.d(to_list_buf_n), .q(to_list_buf), .en(leaf_fifo_re), .clk, .rst);
  ff_ar #(1,'h0) list_valid(.d(to_list_valid_n), .q(to_list_valid), .clk, .rst);
  assign trav_to_list_data = to_list_buf;
  assign trav_to_list_valid = to_list_valid;

///////////////////////////////////// end leaf node route //////////////////////////////////////



  // trav to rs
  always_comb begin
    trav_to_rs_data.ray_info = tcache_data.ray_info;
    trav_to_rs_data.nodeID = tcache_data.nodeID;
    trav_to_rs_data.node = tcache_data.tree_node;
    trav_to_rs_data.restnode_search = tcache_data.restnode_search;
    trav_to_rs_data.t_max = tcache_data.t_max;
    trav_to_rs_data.t_min = tcache_data.t_min;
  end
  assign trav_to_rs_valid = tcache_valid & tcache_data.tree_node.node_type != 2'b11;


  struct packed {
    ray_info_t ray_info;  // sb
    nodeID_t parent_ID; //sb
    nodeID_t right_ID; // sb
    logic low_empty; // sb 
    logic high_empty; // sb
    logic restnode_search; // sb
  } trav_sb_in, trav_sb_out;

  struct packed {
    ray_info_t ray_info;  // sb
    nodeID_t parent_ID; //sb
    nodeID_t right_ID; // sb
    logic low_empty; // sb 
    logic high_empty; // sb
    logic restnode_search; // sb
    // mains
    float_t t_max;
    float_t t_min;
    float_t t_mid;
    logic only_low;
    logic only_high;
    logic trav_lo_then_hi;
    logic trav_hi_then_lo;

  } trav_fifo_in, trav_fifo_out;


  logic ds_valid_pipe_vs;
  logic ds_stall_pipe_vs;

  logic [3:0] num_left_in_trav_fifo;
  
  always_comb begin
    trav_sb_in.ray_info = rs_to_trav_data.ray_info ;
    trav_sb_in.parent_ID = rs_to_trav_data.nodeID ;
    trav_sb_in.right_ID = rs_to_trav_data.node.right_ID ;
    trav_sb_in.low_empty = rs_to_trav_data.node.low_empty ;
    trav_sb_in.high_empty = rs_to_trav_data.node.high_empty ;
    trav_sb_in.restnode_search = rs_to_trav_data.restnode_search ;
  end

  pipe_valid_stall #(.WIDTH($bits(trav_sb_in)), .DEPTH(14)) pipe_inst(
    .clk, .rst,
    .us_valid(rs_to_trav_valid),
    .us_data(trav_sb_in),
    .us_stall(rs_to_trav_stall),
    .ds_valid(ds_valid_pipe_vs),
    .ds_data(trav_sb_out),
    .ds_stall(ds_stall_pipe_vs),
    .num_left_in_fifo(num_left_in_trav_fifo) );


  trav_math big_ass_math_thaaaang(
    .clk, .rst,
    .origin_in(rs_to_trav_data.origin),
    .dir_in(rs_to_trav_data.dir),
    .split_in({rs_to_trav_data.node.split,4'b0}), // TODO TEST THIS MOTHER FUCKER
    .t_max_in(rs_to_trav_data.t_max),
    .t_min_in(rs_to_trav_data.t_min),
  
    .t_max_out(trav_fifo_in.t_max),
    .t_min_out(trav_fifo_in.t_min),
    .t_mid_out(trav_fifo_in.t_mid),

    .only_low(trav_fifo_in.only_low),
    .only_high(trav_fifo_in.only_high),
    .trav_lo_then_hi(trav_fifo_in.trav_lo_then_hi),
    .trav_hi_then_lo(trav_fifo_in.trav_hi_then_lo)
  );



  always_comb begin
    trav_fifo_in.ray_info = trav_sb_out.ray_info ;
    trav_fifo_in.parent_ID = trav_sb_out.parent_ID ;
    trav_fifo_in.right_ID = trav_sb_out.right_ID ;
    trav_fifo_in.low_empty = trav_sb_out.low_empty ;
    trav_fifo_in.high_empty = trav_sb_out.high_empty ;
    trav_fifo_in.restnode_search = trav_sb_out.restnode_search ;
  end


  logic trav_fifo_full;
  logic trav_fifo_empty;
  logic trav_fifo_re;
  logic trav_fifo_we;


  assign trav_fifo_we = ds_valid_pipe_vs ;
  

  fifo #(.DEPTH(15), .WIDTH($bits(trav_fifo_in)) ) trav_fifo_inst(
    .clk, .rst,
    .data_in(trav_fifo_in),
    .data_out(trav_fifo_out),
    .full(trav_fifo_full),
    .empty(trav_fifo_empty),
    .re(trav_fifo_re),
    .we(trav_fifo_we),
    .num_left_in_fifo(num_left_in_trav_fifo),
    .exists_in_fifo());

    

  logic low_empty;
  logic high_empty;
  float_t t_max;
  float_t t_min;
  float_t t_mid;
  logic only_low;
  logic only_high;
  logic trav_lo_then_hi;
  logic trav_hi_then_lo;
   
  assign low_empty = trav_fifo_out.low_empty;
  assign high_empty = trav_fifo_out.high_empty;
  assign t_max = trav_fifo_out.t_max;
  assign t_min = trav_fifo_out.t_min;
  assign t_mid = trav_fifo_out.t_mid;
  assign only_low = trav_fifo_out.only_low;
  assign only_high = trav_fifo_out.only_high;
  assign trav_lo_then_hi = trav_fifo_out.trav_lo_then_hi;
  assign trav_hi_then_lo = trav_fifo_out.trav_hi_then_lo;
 
  
  `ifndef SYNTH
    always @(*) begin
      assert(!(trav_fifo_full & ds_valid_pipe_vs));
      assert(trav_fifo_empty || (only_low + only_high + trav_lo_then_hi + trav_hi_then_lo == 1));
      assert(trav_fifo_empty || (t_max > t_min));
      assert(!(low_empty & high_empty));
    end
  `endif
 

  logic using_ss;
  logic pop_valid;
  logic push_valid;
  logic update_restnode_valid;
  logic update_maxscene_valid;
  nodeID_t push_node_ID;
  
  nodeID_t low_node_ID;
  
  assign low_node_ID = trav_fifo_out.parent_ID + 1'b1;

  assign pop_valid = (only_low & low_empty) | (only_high & high_empty) ;
  assign push_valid = ((~low_empty & ~high_empty) & (trav_lo_then_hi | trav_hi_then_lo)) ;
  assign update_restnode_valid = trav_fifo_out.restnode_search & push_valid;
  assign push_node_ID = trav_lo_then_hi ? trav_fifo_out.right_ID : low_node_ID ;
  assign update_maxscene_valid = trav_fifo_out.restnode_search & ((trav_lo_then_hi & high_empty) | (trav_hi_then_lo & low_empty)) ;

  // trav_to_ss buffer and interface
  trav_to_ss_t ss_buf_n, ss_buf;
  logic ss_valid_n, ss_valid;
  
  logic good_to_ss;
  assign good_to_ss = ~trav_fifo_empty & (pop_valid | push_valid | update_restnode_valid | update_maxscene_valid);

  assign ss_valid_n = (ss_valid & trav_to_ss_stall) | (good_to_ss & trav_fifo_re) ;


  always_comb begin
    if(ss_valid & trav_to_ss_stall) ss_buf_n = ss_buf;
    else begin
      ss_buf_n.ray_info = trav_fifo_out.ray_info;
      ss_buf_n.push_req = push_valid ;
      ss_buf_n.push_node_ID = push_node_ID ;
      ss_buf_n.update_restnode_req = update_restnode_valid ;
      ss_buf_n.rest_node_ID = trav_fifo_out.parent_ID ;
      ss_buf_n.t_max = t_max; // TODO is it always t_max??
      ss_buf_n.pop_req = pop_valid ;
      ss_buf_n.update_maxscene_req = update_maxscene_valid;
    end
 end

  ff_ar #(1,1'b0) ss_valid_reg(.d(ss_valid_n), .q(ss_valid), .clk, .rst);
  ff_ar #($bits(trav_to_ss_t),'h0) ss_buf_reg(.d(ss_buf_n), .q(ss_buf), .clk, .rst);
 

  assign trav_to_ss_valid = ss_valid;
  assign trav_to_ss_data = ss_buf;

//--------------------------------------------------------------------------
  nodeID_t trav_node_ID;
  float_t trav_t_max;
  float_t trav_t_min;

  // DIfficult logic here TODO
  assign trav_node_ID = only_low | (trav_lo_then_hi & ~low_empty) | (trav_hi_then_lo & high_empty) ?
                        low_node_ID : trav_fifo_out.right_ID ;
  always_comb begin
    unique case({only_low|only_high,(trav_lo_then_hi & ~low_empty)|(trav_hi_then_lo & ~high_empty),(trav_hi_then_lo & high_empty)|(trav_lo_then_hi & low_empty)})
     3'b100 : begin
        trav_t_max = t_max;
        trav_t_min = t_min;
      end
     3'b010 : begin
        trav_t_max = t_mid;
        trav_t_min = t_min;
      end
     3'b001 : begin
        trav_t_max = t_max;
        trav_t_min = t_mid;
      end
    endcase

  end

  // trav_to_tarb buffer and interface
  tarb_t tarb_buf_n, tarb_buf;
  logic tarb_valid_n, tarb_valid;

  logic good_to_tarb;
  assign good_to_tarb = ~trav_fifo_empty & ~pop_valid;


  logic [1:0] ss_wptr_next;
  logic [2:0] ss_num_next;
  assign ss_wptr_next = push_valid ? (trav_fifo_out.ray_info.ss_wptr + 1'b1) : 
                                      trav_fifo_out.ray_info.ss_wptr ;
  assign ss_num_next = push_valid ? (trav_fifo_out.ray_info.ss_num == 3'h4 ? 3'h4 : 
                                     trav_fifo_out.ray_info.ss_num + 1'b1) :
                                     trav_fifo_out.ray_info.ss_num ;

  // TODO sketchy!! maybe
  assign tarb_valid_n = (tarb_valid & trav_to_tarb_stall) | (good_to_tarb & trav_fifo_re);
  
  always_comb begin
    if(tarb_valid & trav_to_tarb_stall) tarb_buf_n = tarb_buf;
    else begin
      tarb_buf_n.ray_info.rayID = trav_fifo_out.ray_info.rayID ;
      tarb_buf_n.ray_info.is_shadow = trav_fifo_out.ray_info.is_shadow ;
      tarb_buf_n.ray_info.ss_wptr = ss_wptr_next;
      tarb_buf_n.ray_info.ss_num = ss_num_next ;
      tarb_buf_n.nodeID = trav_node_ID;
      tarb_buf_n.restnode_search = trav_fifo_out.restnode_search & ~push_valid;
      tarb_buf_n.t_max = trav_t_max ;
      tarb_buf_n.t_min = trav_t_min ;
    end
  end

  ff_ar #(1,1'b0) tarb_valid_reg(.d(tarb_valid_n), .q(tarb_valid), .clk, .rst);
  ff_ar #($bits(tarb_t),'h0) tarb_buf_reg(.d(tarb_buf_n), .q(tarb_buf), .clk, .rst);

  assign trav_to_tarb_valid = tarb_valid;
  assign trav_to_tarb_data = tarb_buf;

  assign ds_stall_pipe_vs = (ss_valid & trav_to_ss_stall) | (tarb_valid & trav_to_tarb_stall) ;
  always_comb begin
    case({good_to_ss,good_to_tarb})
      2'b00 : trav_fifo_re = 1'b0;
      2'b10 : trav_fifo_re = ~trav_to_ss_stall;
      2'b01 : trav_fifo_re = ~trav_to_tarb_stall;
      2'b11 : trav_fifo_re = ~trav_to_ss_stall & ~trav_to_tarb_stall;
    endcase
  end

endmodule
