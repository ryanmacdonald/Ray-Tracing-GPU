module tb_trav_unit();

  logic clk, rst;

//////////////// interface with  raystore /////////////////
	trav_to_rs_t    trav_to_rs0;
	logic           trav_to_rs0_valid;
	logic           trav_to_rs0_stall;

	trav_to_rs_t    trav_to_rs1;
	bit             trav_to_rs1_valid;
	bit             trav_to_rs1_stall;

	assign trav_to_rs1_valid = 1'b1;
	assign trav_to_rs1 = 'b0;

	lcache_to_rs_t  lcache_to_rs;
	bit             lcache_to_rs_valid;
	bit             lcache_to_rs_stall;

	assign lcache_to_rs_valid = 1'b1;
	assign lcache_to_rs = 'b0;

	list_to_rs_t    list_to_rs;
	bit             list_to_rs_valid;
	bit             list_to_rs_stall;

	assign list_to_rs_valid = 1'b1;
	assign list_to_rs = 'b0;

	// downstream interface

	rs_to_trav_t    rs_to_trav0;
	bit             rs_to_trav0_valid;
	bit             rs_to_trav0_stall;

	rs_to_trav_t    rs_to_trav1;
	bit             rs_to_trav1_valid;
	bit             rs_to_trav1_stall;

	rs_to_icache_t  rs_to_icache;
	bit             rs_to_icache_valid;
	bit             rs_to_icache_stall;

	rs_to_pcalc_t   rs_to_pcalc;
	bit             rs_to_pcalc_valid;
	bit             rs_to_pcalc_stall;

	logic raystore_we;
	logic [8:0] raystore_write_addr;
	ray_vec_t raystore_write_data;

//////////////// end of interface with  raystore /////////////////


  // tcache to trav
  logic tcache_to_trav_valid;
  tcache_to_trav_t tcache_to_trav_data;
  logic tcache_to_trav_stall;

//////////// normal node traversal /////////////////
  // trav to rs
  logic trav_to_rs_valid;
  trav_to_rs_t trav_to_rs_data;
  logic trav_to_rs_stall;


  // rs to trav
  logic rs_to_trav_valid;
  rs_to_trav_t rs_to_trav_data;
  logic rs_to_trav_stall;

  // trav to ss // common port for push/pop/update
  logic trav_to_ss_valid;
  trav_to_ss_t trav_to_ss_data;
  logic trav_to_ss_stall;
  
  shortreal ss_t_max;
  assign ss_t_max = $bitstoshortreal(trav_to_ss_data.t_max);


  // trav to tarb
  logic trav_to_tarb_valid;
  tarb_t trav_to_tarb_data;
  logic trav_to_tarb_stall;

  shortreal tarb_t_max;
  shortreal tarb_t_min;
  
  assign tarb_t_max = $bitstoshortreal(trav_to_tarb_data.t_max);
  assign tarb_t_min = $bitstoshortreal(trav_to_tarb_data.t_min);

 ///////////////////////////////////////

///////// leaf node traversal //////////////////

   // trav to larb
  logic trav_to_larb_valid;
  leaf_info_t trav_to_larb_data;
  logic trav_to_larb_stall;
 
 
  // trav to list (with tmax)
  logic trav_to_list_valid;
  trav_to_list_t trav_to_list_data;
  logic trav_to_list_stall;

  shortreal list_t_max;
  assign list_t_max = $bitstoshortreal(trav_to_list_data.t_max_leaf);
   
  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end

  trav_unit trav_unit_inst(.*);

  // Provide stimulus from tcache to trav
  

  function norm_node_t create_norm_node(logic [1:0] axis, shortreal split, nodeID_t right_ID, logic low_empty, logic high_empty);
    norm_node_t r;
    r.node_type = axis;
    r.split = ($shortrealtobits(split) >> 4);
    r.right_ID = right_ID;
    r.low_empty = low_empty;
    r.high_empty = high_empty;
    return r;
  endfunction

  function leaf_node_t create_leaf_node(int lindex, int lnum_left);
    leaf_node_t l;
    l.node_type = 2'b11;
    l.ln_tri.lindex = lindex;
    l.ln_tri.lnum_left = lnum_left;
    return l;
  endfunction

  task send_to_trav(int rayID, int nodeID, logic restnode_search, shortreal t_max, shortreal t_min, norm_node_t tree_node, int ss_wptr, int ss_num);
   // @(posedge clk);
    tcache_to_trav_data.ray_info.rayID <= rayID;
    tcache_to_trav_data.ray_info.is_shadow <= 0;
    tcache_to_trav_data.ray_info.ss_wptr <= ss_wptr;
    tcache_to_trav_data.ray_info.ss_num <= ss_num;
    tcache_to_trav_data.nodeID <= nodeID;
    tcache_to_trav_data.restnode_search <= restnode_search;
    tcache_to_trav_data.t_max <= to_bits(t_max);
    tcache_to_trav_data.t_min <= to_bits(t_min);
    tcache_to_trav_data.tree_node <= tree_node;
    tcache_to_trav_valid <= 1;
    @(posedge clk);
    while(tcache_to_trav_stall) @(posedge clk);
    //tcache_to_trav_valid <= 0;
    //tcache_to_trav_data <= 'hX;
  endtask

  

  norm_node_t norm_node;
  leaf_node_t leaf_node;

  ray_vec_t ray_vec;

  initial begin
    tcache_to_trav_valid = 0;
    tcache_to_trav_data = 'hX;

    raystore_we <= 1'b0;
    raystore_write_addr <= 'bx;
    raystore_write_data <= 'bx;

	// write the test ray vector into the ray store
    ray_vec.origin = create_vec(0,0,8);
    ray_vec.dir = create_vec(-1,-1,-1);
    @(posedge clk);
    raystore_we <= 1'b1;
    raystore_write_addr <= 'd6;
    raystore_write_data <= ray_vec;

    ray_vec.origin = create_vec(1,7,0);
    ray_vec.dir = create_vec(2,-2,1);
    @(posedge clk);
    raystore_we <= 1'b1;
    raystore_write_addr <= 'd7;
    raystore_write_data <= ray_vec;


	@(posedge clk);
    raystore_we <= 1'b0;
    raystore_write_addr <= 'bx;
    raystore_write_data <= 'bx;

	// wait some time
    repeat(10) @(posedge clk);

    @(posedge clk);
    norm_node = create_norm_node(2'b10, 5, 12, 0,0);
    send_to_trav(6, 2, 1, 10, 0, norm_node,0,0);
    norm_node = create_norm_node(2'b10, 5, 12, 1,0);
    send_to_trav(6, 2, 1, 10, 0, norm_node,1,2);
    norm_node = create_norm_node(2'b10, 5, 12, 0,1);
    send_to_trav(6, 2, 1, 10, 0, norm_node,1,4);

/*
    norm_node = create_norm_node(2'b10, 5, 12, 0,0);
    send_to_trav(7, 2, 1, 10, 0, norm_node);
    norm_node = create_norm_node(2'b10, 5, 12, 1,0);
    send_to_trav(7, 2, 1, 10, 0, norm_node);
    norm_node = create_norm_node(2'b10, 5, 12, 0,1);
    send_to_trav(7, 2, 1, 10, 0, norm_node);
*/    
    leaf_node = create_leaf_node(5, 8);
    send_to_trav(3, 2, 1, 4, 0, leaf_node,2,4);
    leaf_node = create_leaf_node(2, 9);
    send_to_trav(4, 2, 1, 13, 0, leaf_node,1,0);
    leaf_node = create_leaf_node(7, 1);
    send_to_trav(5, 2, 1, 0.05, 0, leaf_node,2,3);
   
    
    tcache_to_trav_valid <= 0;
    repeat(100) @(posedge clk);
    $finish;
  end

  // Deal with trav ->rs -> trav

	assign trav_to_rs0_valid = trav_to_rs_valid;
	assign trav_to_rs0 = trav_to_rs_data;
	assign trav_to_rs_stall = trav_to_rs0_stall;

	raystore rs(.*);

	assign rs_to_trav_valid = rs_to_trav0_valid;
	assign rs_to_trav_data = rs_to_trav0;
	assign rs_to_trav0_stall = rs_to_trav_stall;

/*	
  assign rs_to_trav_valid = trav_to_rs_valid;
  assign trav_to_rs_stall = rs_to_trav_stall;
  always_comb begin
    rs_to_trav_data.ray_info.rayID = trav_to_rs_data.ray_info.rayID ;
    rs_to_trav_data.nodeID = trav_to_rs_data.nodeID ;
    rs_to_trav_data.node = trav_to_rs_data.node ;
    rs_to_trav_data.restnode_search = trav_to_rs_data.restnode_search ;
    rs_to_trav_data.t_max = trav_to_rs_data.t_max ;
    rs_to_trav_data.t_min = trav_to_rs_data.t_min ;
  end
  */

  initial begin
// NOTE: commented the following two lines since they are now coming from the raystore
//    rs_to_trav_data.origin = to_bits(8);
//    rs_to_trav_data.dir = to_bits(0.05);
/*  while(~rs_to_trav_valid | rs_to_trav_stall) @(posedge clk);
    trav_to_data.origin = to_bits(5);
    trav_to_data.dir = to_bits(-1);
    while(~rs_to_trav_valid | rs_to_trav_stall) @(posedge clk);
*/
  end

  int i;
  initial begin
    
    forever @(posedge clk) begin
      i = {$random}%2;
    end
  end

  always_comb begin
    
    if(i & trav_to_ss_valid ) trav_to_ss_stall = 1;
    else trav_to_ss_stall = 0;
    if((!i) & trav_to_tarb_valid) trav_to_tarb_stall = 1;
    else trav_to_tarb_stall = 0;

    if((!i) & trav_to_list_valid ) trav_to_list_stall = 1;
    else trav_to_list_stall = 0;
    if((i) & trav_to_larb_valid) trav_to_larb_stall = 1;
    else trav_to_larb_stall = 0;

  end
  


  function float_t to_bits(shortreal a);
    return $shortrealtobits(a);
  endfunction

  function vector_t create_vec(shortreal x, shortreal y, shortreal z);
    vector_t vec;
    vec.x = $shortrealtobits(x);
    vec.y = $shortrealtobits(y);
    vec.z = $shortrealtobits(z);
    return vec;
  endfunction

endmodule
