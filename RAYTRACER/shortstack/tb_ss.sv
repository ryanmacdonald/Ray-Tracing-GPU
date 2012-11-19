`default_nettype none

module tb_ss();

  logic clk, rst;

  //--------------------- SHORSTACK INTERFACES -----------------------------
  logic trav0_to_ss_valid;
  trav_to_ss_t trav0_to_ss_data;
  logic trav0_to_ss_stall;


  bit trav1_to_ss_valid;
  trav_to_ss_t trav1_to_ss_data;
  bit trav1_to_ss_stall;


  bit sint_to_ss_valid;
  sint_to_ss_t sint_to_ss_data;
  bit sint_to_ss_stall;


  logic list_to_ss_valid;
  list_to_ss_t list_to_ss_data;
  logic list_to_ss_stall;


  logic ss_to_shader_valid;
  ss_to_shader_t ss_to_shader_data;
  bit ss_to_shader_stall;


  // This is for reading from the stack
  logic ss_to_tarb_valid0;
  tarb_t ss_to_tarb_data0;
  bit ss_to_tarb_stall0;
  

  // this is for reading from the restart node
  logic ss_to_tarb_valid1;
  tarb_t ss_to_tarb_data1;
  bit ss_to_tarb_stall1;

//--------------------- list INTERFACES -----------------------------
  logic trav0_to_list_valid;
  trav_to_list_t trav0_to_list_data;
  logic trav0_to_list_stall;

  logic trav1_to_list_valid;
  trav_to_list_t trav1_to_list_data;
  logic trav1_to_list_stall;

  bit int_to_list_valid;
  int_to_list_t int_to_list_data;
  logic int_to_list_stall;

/*
  logic list_to_ss_valid;
  list_to_ss_t list_to_ss_data;
  logic list_to_ss_stall;
*/

  logic list_to_rs_valid;
  list_to_rs_t list_to_rs_data;
  logic list_to_rs_stall;


//////////////// interface with  raystore /////////////////
	trav_to_rs_t    trav0_to_rs_data;
	logic           trav0_to_rs_valid;
	logic           trav0_to_rs_stall;

	trav_to_rs_t    trav1_to_rs_data;
	bit             trav1_to_rs_valid;
	bit             trav1_to_rs_stall;

//  assign trav1_to_rs_valid = 1'b1;
//  assign trav1_to_rs1_data = 'b0;

	lcache_to_rs_t  lcache_to_rs_data;
	bit             lcache_to_rs_valid;
	bit             lcache_to_rs_stall;

//  assign lcache_to_rs_valid = 1'b1;
//  assign lcache_to_rs_data = 'b0;

	
  // downstream interface

	rs_to_trav_t    rs_to_trav0_data;
	logic           rs_to_trav0_valid;
	logic           rs_to_trav0_stall;

	rs_to_trav_t    rs_to_trav1_data;
	logic           rs_to_trav1_valid;
	bit             rs_to_trav1_stall;

	rs_to_icache_t  rs_to_icache_data;
	logic           rs_to_icache_valid;
	bit             rs_to_icache_stall;

	rs_to_pcalc_t   rs_to_pcalc_data;
	logic           rs_to_pcalc_valid;
	bit             rs_to_pcalc_stall;

	logic raystore_we;
  rayID_t raystore_write_addr;
	ray_vec_t raystore_write_data;

//////////////// Trav interface /////////////////


  // tcache to trav
  bit tcache_to_trav0_valid;
  tcache_to_trav_t tcache_to_trav0_data;
  logic tcache_to_trav0_stall;

//////////// normal node traversal /////////////////
  // trav to rs
/*  logic trav_to_rs_valid;
  trav_to_rs_t trav_to_rs_data;
  logic trav_to_rs_stall;
*/

  // rs to trav
/*  logic rs_to_trav_valid;
  rs_to_trav_t rs_to_trav_data;
  logic rs_to_trav_stall;
*/
/*
  logic trav_to_ss_valid;
  trav_to_ss_t trav_to_ss_data;
  logic trav_to_ss_stall;
*/  
 
  // trav to larb
  logic trav0_to_larb_valid;
  leaf_info_t trav0_to_larb_data;
  logic trav0_to_larb_stall;
 
 
  // trav to list (with tmax)
/*  logic trav_to_list_valid;
  trav_to_list_t trav_to_list_data;
  logic trav_to_list_stall;
*/

  // trav to tarb
  logic trav0_to_tarb_valid;
  tarb_t trav0_to_tarb_data;
  logic trav0_to_tarb_stall;

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
  class random_stall;
    rand bit[31:0] r;
    constraint c {r == 'h0; } 
  endclass
  
  random_stall r;
  initial begin
    r = new;
  end

  always_ff @(posedge clk) begin
    r.randomize();
    trav0_to_tarb_stall <= trav0_to_tarb_valid & r.r[0];
    trav0_to_larb_stall <= trav0_to_larb_valid & r.r[1];
    ss_to_shader_stall <= ss_to_shader_valid & r.r[2];
    rs_to_icache_stall <= rs_to_icache_valid & r.r[3];
    rs_to_pcalc_stall <= rs_to_pcalc_valid & r.r[4];
    rs_to_trav1_stall <= rs_to_trav1_valid & r.r[5];
    ss_to_tarb_stall0 <= ss_to_tarb_valid0 & r.r[6];
    ss_to_tarb_stall1 <= ss_to_tarb_valid1 & r.r[7];
  end

  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end

  function vector_t create_vec(shortreal x, shortreal y, shortreal z);
    vector_t vec;
    vec.x = $shortrealtobits(x);
    vec.y = $shortrealtobits(y);
    vec.z = $shortrealtobits(z);
    return vec;
  endfunction

  function float_t to_bits(shortreal a);
    return $shortrealtobits(a);
  endfunction

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
    tcache_to_trav0_data.ray_info.rayID <= rayID;
    tcache_to_trav0_data.ray_info.is_shadow <= 0;
    tcache_to_trav0_data.ray_info.ss_wptr <= ss_wptr;
    tcache_to_trav0_data.ray_info.ss_num <= ss_num;
    tcache_to_trav0_data.nodeID <= nodeID;
    tcache_to_trav0_data.restnode_search <= restnode_search;
    tcache_to_trav0_data.t_max <= to_bits(t_max);
    tcache_to_trav0_data.t_min <= to_bits(t_min);
    tcache_to_trav0_data.tree_node <= tree_node;
    tcache_to_trav0_valid <= 1;
    @(posedge clk);
    while(tcache_to_trav0_stall) @(posedge clk);
    tcache_to_trav0_valid <= 0;
    tcache_to_trav0_data <= 'hX;
    @(posedge clk);
  endtask
 
  task send_int_to_list(int rayID, int triID, bit hit, bit is_last, shortreal t_int, int ss_wptr, int ss_num);
    int_to_list_valid <= 1'b1;
    int_to_list_data.ray_info.rayID <= rayID;
    int_to_list_data.ray_info.ss_wptr <= ss_wptr;
    int_to_list_data.ray_info.ss_num <= ss_num;
    int_to_list_data.ray_info.is_shadow <= 0;
    int_to_list_data.triID <= triID ;
    int_to_list_data.hit <= hit ;
    int_to_list_data.is_last <= is_last ;
    int_to_list_data.t_int <= to_bits(t_int) ;
    int_to_list_data.uv.u <= to_bits({$random}%100) ;
    int_to_list_data.uv.v <= to_bits({$random}%100) ;
    @(posedge clk);
    while(int_to_list_stall) @(posedge clk);
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
    @(posedge clk);
  endtask
 
  task send_sint_to_ss(int rayID, shortreal t_max_scene);
    sint_to_ss_valid <= 1'b1;
    sint_to_ss_data.rayID <= rayID ;
    sint_to_ss_data.t_max_scene <= to_bits(t_max_scene) ;
    @(posedge clk);
    while(sint_to_ss_stall) @(posedge clk);
    sint_to_ss_valid <= 0;
    sint_to_ss_data <= 'hX ;
  endtask
  

  // Dealing with tcache -> trav
  norm_node_t norm_node;
  leaf_node_t leaf_node;
  ray_vec_t ray_vec;
  initial begin
    raystore_we = 1'b0;
	// write the test ray vector into the ray store
    ray_vec.origin = create_vec(1,10,11);
    ray_vec.dir = create_vec(1,-1,-1);
    @(posedge clk);
    raystore_we <= 1'b1;
    raystore_write_addr <= 'd6;
    raystore_write_data <= ray_vec;
    @(posedge clk);
    raystore_we <= 1'b1;
    raystore_write_addr <= 'd9;
    raystore_write_data <= ray_vec;
    @(posedge clk);
    raystore_we <= 1'b0;
    raystore_write_addr <= 'bx;
    raystore_write_data <= 'bx;

	// wait some time
    repeat(10) @(posedge clk);

    @(posedge clk);
    norm_node = create_norm_node(.axis(2'b00), .split(5), .right_ID(12), .low_empty(0),.high_empty(0));
    send_to_trav(.rayID(9), .nodeID(2), .restnode_search(1), .tree_node(norm_node), .t_max(11), .t_min(0), .ss_wptr(2),.ss_num(1)); // TODO test t_max==10
    norm_node = create_norm_node(2'b10, 5, 12, 1,0);
    send_to_trav(.rayID(6), .nodeID(5), .restnode_search(1), .tree_node(norm_node), .t_max(10), .t_min(0), .ss_wptr(1),.ss_num(4));
    norm_node = create_norm_node(2'b10, 5, 12, 0,1);
    send_to_trav(7, 2, 1, 10, 0, norm_node,1,4);
    
    leaf_node = create_leaf_node(5, 8);
    send_to_trav(3, 2, 1, 4, 0, leaf_node,2,4);
    leaf_node = create_leaf_node(2, 9);
    send_to_trav(4, 2, 1, 13, 0, leaf_node,1,0);
    leaf_node = create_leaf_node(7, 1);
    send_to_trav(5, 2, 1, 0.05, 0, leaf_node,2,3);
   
    
    tcache_to_trav0_valid <= 0;
    repeat(100) @(posedge clk);
    $finish;
  end

  
  
  initial begin
    trav1_to_list_valid = 0;
    trav1_to_list_data = 'hX;
    // fill up t_max_leaf with all odd rayIDs 
    @(posedge clk);
    for(int i=8; i<11; i+=1) begin
      trav1_to_list_valid <= 1;
      trav1_to_list_data.rayID <= i;
      trav1_to_list_data.t_max_leaf <= to_bits(i);
      @(posedge clk);
      while(trav1_to_list_stall) @(posedge clk);
    end
    trav1_to_list_valid <= 0;
    trav1_to_list_data <= 'hX;
  end

  initial begin
    @(posedge clk);
    send_sint_to_ss(9,209);
    send_sint_to_ss(10,210);
    send_sint_to_ss(8,208);
  end


  initial begin
    int_to_list_valid = 0;
    int_to_list_data = 'hX;
    repeat(50) @(posedge clk);
    send_int_to_list(.rayID(10),.triID(3),.hit(1),.is_last(0),.t_int(5),.ss_wptr(1), .ss_num(1));
    send_int_to_list(.rayID(9),.triID(`DC),.hit(0),.is_last(1),.t_int('hX),.ss_wptr(3),.ss_num(2));
    send_int_to_list(.rayID(8),.triID(6),.hit(1),.is_last(1),.t_int(10),.ss_wptr(0),.ss_num(0));
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
    /*repeat(30) @(posedge clk);
    send_int_to_list(.rayID(9),.triID(4),.hit(1),.is_last(1),.t_int(5.5));
    send_int_to_list(.rayID(8),.triID(0),.hit(0),.is_last(1),.t_int(`DC));
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
    repeat(20) @(posedge clk);
    send_int_to_list(8,0,0,1,-2);
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
*/    repeat(80) @(posedge clk);
    $finish;
  end

  
  
	shortstack_unit shortstack_unit_inst(
		.clk,
		.rst,
		.trav0_to_ss_valid,
		.trav0_to_ss_data,
		.trav0_to_ss_stall,
		.trav1_to_ss_valid,
		.trav1_to_ss_data,
		.trav1_to_ss_stall,
		.sint_to_ss_valid,
		.sint_to_ss_data,
		.sint_to_ss_stall,
		.list_to_ss_valid,
		.list_to_ss_data,
		.list_to_ss_stall,
		.ss_to_shader_valid,
		.ss_to_shader_data,
		.ss_to_shader_stall,
		.ss_to_tarb_valid0,
		.ss_to_tarb_data0,
		.ss_to_tarb_stall0,
		.ss_to_tarb_valid1,
		.ss_to_tarb_data1,
		.ss_to_tarb_stall1
	);

	trav_unit trav_unit_inst(
		.clk,
		.rst,
		.tcache_to_trav_valid(tcache_to_trav0_valid),
		.tcache_to_trav_data(tcache_to_trav0_data),
		.tcache_to_trav_stall(tcache_to_trav0_stall),
		.trav_to_rs_valid(trav0_to_rs_valid),
		.trav_to_rs_data(trav0_to_rs_data),
		.trav_to_rs_stall(trav0_to_rs_stall),
		.rs_to_trav_valid(rs_to_trav0_valid),
		.rs_to_trav_data(rs_to_trav0_data),
		.rs_to_trav_stall(rs_to_trav0_stall),
		.trav_to_ss_valid(trav0_to_ss_valid),
		.trav_to_ss_data(trav0_to_ss_data),
		.trav_to_ss_stall(trav0_to_ss_stall),
		.trav_to_tarb_valid(trav0_to_tarb_valid),
		.trav_to_tarb_data(trav0_to_tarb_data),
		.trav_to_tarb_stall(trav0_to_tarb_stall),
		.trav_to_larb_valid(trav0_to_larb_valid),
		.trav_to_larb_data(trav0_to_larb_data),
		.trav_to_larb_stall(trav0_to_larb_stall),
		.trav_to_list_valid(trav0_to_list_valid),
		.trav_to_list_data(trav0_to_list_data),
		.trav_to_list_stall(trav0_to_list_stall)
	);

	list_unit list_unit_inst(
		.clk,
		.rst,
		.trav0_to_list_valid,
		.trav0_to_list_data,
		.trav0_to_list_stall,
		.trav1_to_list_valid,
		.trav1_to_list_data,
		.trav1_to_list_stall,
		.int_to_list_valid,
		.int_to_list_data,
		.int_to_list_stall,
		.list_to_ss_valid,
		.list_to_ss_data,
		.list_to_ss_stall,
		.list_to_rs_valid,
		.list_to_rs_data,
		.list_to_rs_stall
	);

	raystore raystore_inst(
		.clk,
		.rst,
		.trav0_to_rs_data,
		.trav0_to_rs_valid,
		.trav0_to_rs_stall,
		.trav1_to_rs_data,
		.trav1_to_rs_valid,
		.trav1_to_rs_stall,
		.lcache_to_rs_data,
		.lcache_to_rs_valid,
		.lcache_to_rs_stall,
		.list_to_rs_data,
		.list_to_rs_valid,
		.list_to_rs_stall,
		.rs_to_trav0_data,
		.rs_to_trav0_valid,
		.rs_to_trav0_stall,
		.rs_to_trav1_data,
		.rs_to_trav1_valid,
		.rs_to_trav1_stall,
		.rs_to_icache_data,
		.rs_to_icache_valid,
		.rs_to_icache_stall,
		.rs_to_pcalc_data,
		.rs_to_pcalc_valid,
		.rs_to_pcalc_stall,
		.raystore_we,
		.raystore_write_data,
		.raystore_write_addr
	);


endmodule
