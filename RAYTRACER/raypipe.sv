`default_nettype none

module raypipe #(

	// parameters for icache
	parameter	I_SIDE_W=8, // TODO

				I_ADDR_W=16,
				I_BO_W=0,
				I_TAG_W=6,
				I_INDEX_W=10,

				I_LINE_W=288,
				I_NUM_BLK = 1,
				I_BLK_W = I_LINE_W/I_NUM_BLK,

				I_BASE_ADDR=0, // TODO
				I_NUM_LINES=1024,

	// parameters for tcaches
	      T_SIDE_W=8, // TODO

				T_ADDR_W=16,
				T_BO_W=3,
				T_TAG_W=4,
				T_INDEX_W=9,
	
				T_LINE_W=384,
				T_NUM_BLK = 8,
				T_BLK_W = T_LINE_W/T_NUM_BLK,

				T_BASE_ADDR=0, // TODO
				T_NUM_LINES=512,

	// parameters for lcache
	      L_SIDE_W=8, // TODO

				L_ADDR_W=16,
				L_BO_W=4,
				L_TAG_W=2,
				L_INDEX_W=10,

				L_LINE_W=256,
				L_NUM_BLK=16,
				L_BLK_W=L_LINE_W/L_NUM_BLK,

				L_BASE_ADDR=0, // TODO
				L_NUM_LINES=1024 ) (
  
  input clk, rst,
  	
  // Interface to PRG
  input logic v0, v1, v2,
  input logic render_frame,
  input AABB_t sceneAABB,
  input vector_t E, U, V, W,

  // Interface with memory arbitor
  output logic[`numcaches-1:0][24:0] addr_cache_to_sdram,
  output logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize,
  output logic[`numcaches-1:0] readReq,
  input logic[`numcaches-1:0] readValid_out,
  input logic[`numcaches-1:0][31:0] readData,
  input logic[`numcaches-1:0] doneRead,

  // Interface to Pixel Buffer
  output logic pb_we,
  input logic pb_full,
  output pixel_buffer_entry_t pb_data_out

  );

  // prg_to_shader 
  logic prg_to_shader_valid;
  prg_ray_t prg_to_shader_data;
  logic prg_to_shader_stall;

  // shader_to_rs
  logic raystore_we ;
  rayID_t raystore_write_addr ;
  ray_vec_t raystore_write_data ;

	// shader_to_sint
	logic shader_to_sint_valid ;
	shader_to_sint_t shader_to_sint_data ;
	logic shader_to_sint_stall ;
	
  // sint_to_shader
	logic sint_to_shader_valid ;
	sint_to_shader_t sint_to_shader_data ;
	logic sint_to_shader_stall ;

	// sint_to_ss
	logic sint_to_ss_valid ;
	sint_to_ss_t sint_to_ss_data ;
	logic sint_to_ss_stall ;

	// sint_to_tarb
	logic sint_to_tarb_valid ;
	tarb_t sint_to_tarb_data ;
	logic sint_to_tarb_stall ;

	// tarb_to_tcache0
	logic tarb_to_tcache0_valid ;
	tarb_t tarb_to_tcache0_data ;
	logic tarb_to_tcache0_stall ;

	// tcache_to_trav0
	logic tcache_to_trav0_valid ;
	tcache_to_trav_t tcache_to_trav0_data ;
	logic tcache_to_trav0_stall ;

	// trav0_to_rs
	logic trav0_to_rs_valid ;
	trav_to_rs_t trav0_to_rs_data ;
	logic trav0_to_rs_stall ;

	// rs_to_trav0
	logic rs_to_trav0_valid ;
	rs_to_trav_t rs_to_trav0_data ;
	logic rs_to_trav0_stall ;

	// trav0_to_tarb
	logic trav0_to_tarb_valid ;
	tarb_t trav0_to_tarb_data ;
	logic trav0_to_tarb_stall ;

	// trav0_to_ss
	logic trav0_to_ss_valid ;
	trav_to_ss_t trav0_to_ss_data ;
	logic trav0_to_ss_stall ;

	// trav0_to_list
	logic trav0_to_list_valid ;
	trav_to_list_t trav0_to_list_data ;
	logic trav0_to_list_stall ;

	// trav0_to_larb
	logic trav0_to_larb_valid ;
	leaf_info_t trav0_to_larb_data ;
	logic trav0_to_larb_stall ;

	// larb_to_lcache
	logic larb_to_lcache_valid ;
	leaf_info_t larb_to_lcache_data ;
	logic larb_to_lcache_stall ;

	// lcache_to_icache
	logic lcache_to_icache_valid ;
	lcache_to_icache_t lcache_to_icache_data ;
	logic lcache_to_icache_stall ;

	// icache_to_rs
	logic icache_to_rs_valid ;
	icache_to_rs_t icache_to_rs_data ;
	logic icache_to_rs_stall ;

	// rs_to_int
	logic rs_to_int_valid ;
	rs_to_int_t rs_to_int_data ;
	logic rs_to_int_stall ;

	// int_to_larb
	logic int_to_larb_valid ;
	leaf_info_t int_to_larb_data ;
	logic int_to_larb_stall ;

	// int_to_list
	logic int_to_list_valid ;
	int_to_list_t int_to_list_data ;
	logic int_to_list_stall ;

////int_to_shader TODO path for shadow rays

	// list_to_rs
	logic list_to_rs_valid ;
	list_to_rs_t list_to_rs_data ;
	logic list_to_rs_stall ;

	// list_to_ss
	logic list_to_ss_valid ;
	list_to_ss_t list_to_ss_data ;
	logic list_to_ss_stall ;

	// ss_to_tarb0
	logic ss_to_tarb_valid0 ;
	tarb_t ss_to_tarb_data0 ;
	logic ss_to_tarb_stall0 ;

	// ss_to_tarb1
	logic ss_to_tarb_valid1 ;
	tarb_t ss_to_tarb_data1 ;
	logic ss_to_tarb_stall1 ;

	// ss_to_shader
	logic ss_to_shader_valid ;
	ss_to_shader_t ss_to_shader_data ;
	logic ss_to_shader_stall ;

	// rs_to_pcalc
	logic rs_to_pcalc_valid ;
	rs_to_pcalc_t rs_to_pcalc_data ;
	logic rs_to_pcalc_stall ;

	logic pcalc_to_shader_valid ;
	rs_to_pcalc_t pcalc_to_shader_data ;
	logic pcalc_to_shader_stall ;

 


	//////////////////////// Cache signals ////////////////////////
	////////// Icache//////////////
	lcache_to_icache_t ic_us_sb_data;
  triID_t  ic_us_addr;
  logic ic_us_valid, ic_us_stall;
  
  //ds
	int_cacheline_t ic_ds_rdata;
	lcache_to_icache_t ic_ds_sb_data;
  logic ic_ds_valid, ic_ds_stall;

  assign ic_us_addr = lcache_to_icache_data.triID;
  assign ic_us_sb_data = lcache_to_icache_data;
  assign ic_us_valid = lcache_to_icache_valid;
  assign lcache_to_icache_stall = ic_us_stall;

  always_comb begin
    icache_to_rs_data.ray_info = ic_ds_sb_data.ray_info;
    icache_to_rs_data.ln_tri = ic_ds_sb_data.ln_tri;
    icache_to_rs_data.triID = ic_ds_sb_data.triID;
    icache_to_rs_data.tri_cacheline = ic_ds_rdata;
  end
  assign icache_to_rs_valid = ic_ds_valid;
  assign ic_ds_stall = icache_to_rs_stall;



	////////// t0cache//////////////
	tarb_t t0c_us_sb_data;
  nodeID_t  t0c_us_addr;
  logic t0c_us_valid, t0c_us_stall;
  
  //ds
	norm_node_t t0c_ds_rdata;
	tarb_t  t0c_ds_sb_data;
  logic t0c_ds_valid, t0c_ds_stall;

  assign t0c_us_addr = tarb_to_tcache0_data.nodeID;
  assign t0c_us_sb_data = tarb_to_tcache0_data;
  assign t0c_us_valid = tarb_to_tcache0_valid;
  assign tarb_to_tcache0_stall = t0c_us_stall;

  always_comb begin
    tcache_to_trav0_data.ray_info = t0c_ds_sb_data.ray_info;
    tcache_to_trav0_data.nodeID = t0c_ds_sb_data.nodeID;
    tcache_to_trav0_data.restnode_search = t0c_ds_sb_data.restnode_search;
    tcache_to_trav0_data.t_max = t0c_ds_sb_data.t_max;
    tcache_to_trav0_data.t_min = t0c_ds_sb_data.t_min;
    tcache_to_trav0_data.tree_node = t0c_ds_rdata;
  end
  assign t0c_ds_stall = tcache_to_trav0_stall;
  assign tcache_to_trav0_valid = t0c_ds_valid;

	
  ////////// lcache//////////////
  leaf_info_t lc_us_sb_data;
  lindex_t  lc_us_addr;
  logic lc_us_valid, lc_us_stall;
  
  //ds
	triID_t lc_ds_rdata;
	leaf_info_t  lc_ds_sb_data;
  logic lc_ds_valid, lc_ds_stall;

  assign lc_us_addr = larb_to_lcache_data.ln_tri.lindex;
  assign lc_us_sb_data = larb_to_lcache_data;
  assign lc_us_valid = larb_to_lcache_valid;
  assign larb_to_lcache_stall = lc_us_stall;

  always_comb begin
    lcache_to_icache_data.ray_info = lc_ds_sb_data.ray_info;
    lcache_to_icache_data.ln_tri = lc_ds_sb_data.ln_tri;
    lcache_to_icache_data.triID = lc_ds_rdata;
  end
  assign lc_ds_stall = lcache_to_icache_stall;
  assign lcache_to_icache_valid = lc_ds_valid;

	
  //////////////////////// Intersection Cache ////////////////////////

  
	cache_and_miss_handler #(
         .SIDE_W($bits(lcache_to_icache_t)),
         .ADDR_W(I_ADDR_W),
         .LINE_W(I_LINE_W),
         .BLK_W(I_BLK_W),
         .TAG_W(I_TAG_W),
         .INDEX_W(I_INDEX_W),
         .NUM_LINES(I_NUM_LINES),
         .BO_W(I_BO_W),
         .BASE_ADDR(I_BASE_ADDR))
		icache (
			.us_sb_data(ic_us_sb_data),
			.us_valid(ic_us_valid),
			.us_addr(ic_us_addr),
			.us_stall(ic_us_stall),
			.ds_rdata(ic_ds_rdata),
			.ds_sb_data(ic_ds_sb_data),
			.ds_valid(ic_ds_valid),
			.ds_stall(ic_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[0]),
			.transSize(transSize[0]),
			.readReq(readReq[0]),
			.readValid_out(readValid_out[0]),
			.readData(readData[0]),
			.doneRead(doneRead[0]),
			.clk, .rst);

	//////////////////////// Traversal Cache 0 ////////////////////////
	cache_and_miss_handler #(
         .SIDE_W($bits(tarb_t)),
         .ADDR_W(T_ADDR_W),
         .LINE_W(T_LINE_W),
         .BLK_W(T_BLK_W),
         .TAG_W(T_TAG_W),
         .INDEX_W(T_INDEX_W),
         .NUM_LINES(T_NUM_LINES),
         .BO_W(T_BO_W),
         .BASE_ADDR(T_BASE_ADDR))
		t0cache (
			.us_sb_data(t0c_us_sb_data),
			.us_valid(t0c_us_valid),
			.us_addr(t0c_us_addr),
			.us_stall(t0c_us_stall),
			.ds_rdata(t0c_ds_rdata),
			.ds_sb_data(t0c_ds_sb_data),
			.ds_valid(t0c_ds_valid),
			.ds_stall(t0c_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[1]),
			.transSize(transSize[1]),
			.readReq(readReq[1]),
			.readValid_out(readValid_out[1]),
			.readData(readData[1]),
			.doneRead(doneRead[1]),
			.clk, .rst);


	//////////////////////// List Cache ////////////////////////

	cache_and_miss_handler #(
         .SIDE_W($bits(leaf_info_t)),
         .ADDR_W(L_ADDR_W),
         .LINE_W(L_LINE_W),
         .BLK_W(L_BLK_W),
         .TAG_W(L_TAG_W),
         .INDEX_W(L_INDEX_W),
         .NUM_LINES(L_NUM_LINES),
         .BO_W(L_BO_W),
         .BASE_ADDR(L_BASE_ADDR))
		lcache (
			.us_sb_data(lc_us_sb_data),
			.us_valid(lc_us_valid),
			.us_addr(lc_us_addr),
			.us_stall(lc_us_stall),
			.ds_rdata(lc_ds_rdata),
			.ds_sb_data(lc_ds_sb_data),
			.ds_valid(lc_ds_valid),
			.ds_stall(lc_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[2]),
			.transSize(transSize[2]),
			.readReq(readReq[2]),
			.readValid_out(readValid_out[2]),
			.readData(readData[2]),
			.doneRead(doneRead[2]),
			.clk, .rst);

//----------------------------------------------------------------------

  // PRG
	prg prg_inst(
		.clk,
		.rst,
		.v0, .v1, .v2,
		.start(render_frame),
		.E, .U, .V, .W,
		.pw(`PW),
		.prg_to_shader_stall,
		.prg_to_shader_valid,
		.prg_to_shader_data
	);
	

  // Shaader (simple) 
  // For now  there is no pcalc since there is no need
  assign pcalc_to_shader_data = rs_to_pcalc_data;
	assign pcalc_to_shader_valid = rs_to_pcalc_valid;
  assign rs_to_pcalc_stall = pcalc_to_shader_stall;

  simple_shader_unit simple_shader_unit_inst(
		.clk,
		.rst,
		.prg_to_shader_valid,
		.prg_to_shader_data,
		.prg_to_shader_stall,
		.pcalc_to_shader_valid,
		.pcalc_to_shader_data,
		.pcalc_to_shader_stall,
		.int_to_shader_valid(1'b0),
		.int_to_shader_data(9`DC),
		.int_to_shader_stall(),
		.sint_to_shader_valid,
		.sint_to_shader_data,
		.sint_to_shader_stall,
		.ss_to_shader_valid,
		.ss_to_shader_data,
		.ss_to_shader_stall,
		.pb_we,
		.pb_full,
		.pb_data_out,
		.shader_to_sint_valid,
		.shader_to_sint_data,
		.shader_to_sint_stall,
		.raystore_we,
		.raystore_write_addr,
		.raystore_write_data
	);


  // sint
  scene_int scene_int_inst(
		.clk,
		.rst,
		.v0, .v1, .v2,
		.sceneAABB,
		.shader_to_sint_valid,
		.shader_to_sint_data,
		.shader_to_sint_stall,
		.sint_to_shader_valid,
		.sint_to_shader_data,
		.sint_to_shader_stall,
		.sint_to_ss_valid,
		.sint_to_ss_data,
		.sint_to_ss_stall,
		.sint_to_tarb_valid,
		.sint_to_tarb_data,
		.sint_to_tarb_stall 
	);


  // Tarb 
  logic [3:0][$bits(tarb_t)-1:0] tarb_data_us;
  logic [3:0] tarb_valid_us, tarb_stall_us;
  
  always_comb begin
    tarb_data_us[0] = ss_to_tarb_data0;
    tarb_valid_us[0] = ss_to_tarb_valid0;
    ss_to_tarb_stall0 = tarb_stall_us[0];
    
    tarb_data_us[1] = ss_to_tarb_data1;
    tarb_valid_us[1] = ss_to_tarb_valid1;
    ss_to_tarb_stall1 = tarb_stall_us[1];
   
    tarb_data_us[2] = trav0_to_tarb_data;
    tarb_valid_us[2] = trav0_to_tarb_valid;
    trav0_to_tarb_stall = tarb_stall_us[2];
   
    tarb_data_us[3] = sint_to_tarb_data;
    tarb_valid_us[3] = sint_to_tarb_valid;
    sint_to_tarb_stall = tarb_stall_us[3];
 end


	arbitor #(.NUM_IN(4), .WIDTH($bits(tarb_t))) tarb(
		.clk,
		.rst,
		.valid_us(tarb_valid_us),
		.stall_us(tarb_stall_us),
		.data_us(tarb_data_us),
		.valid_ds(tarb_to_tcache0_valid),
		.stall_ds(tarb_to_tcache0_stall),
		.data_ds(tarb_to_tcache0_data)
	);

  // trav0
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

  // shortstack
	shortstack_unit shortstack_unit_inst(
		.clk,
		.rst,
		.trav0_to_ss_valid,
		.trav0_to_ss_data,
		.trav0_to_ss_stall,
		.trav1_to_ss_valid(1'b0),
		.trav1_to_ss_data(83`DC),
		.trav1_to_ss_stall(),
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

  // raystore
	raystore raystore_inst(
		.clk,
		.rst,
		.trav0_to_rs_data,
		.trav0_to_rs_valid,
		.trav0_to_rs_stall,
		.trav1_to_rs_data(144`DC),
		.trav1_to_rs_valid(1'b0),
		.trav1_to_rs_stall(),
		.icache_to_rs_data,
		.icache_to_rs_valid,
		.icache_to_rs_stall,
		.list_to_rs_data,
		.list_to_rs_valid,
		.list_to_rs_stall,
		.rs_to_trav0_data,
		.rs_to_trav0_valid,
		.rs_to_trav0_stall,
		.rs_to_trav1_data(),
		.rs_to_trav1_valid(),
		.rs_to_trav1_stall(1'b0),
		.rs_to_int_data,
		.rs_to_int_valid,
		.rs_to_int_stall,
		.rs_to_pcalc_data,
		.rs_to_pcalc_valid,
		.rs_to_pcalc_stall,
		.raystore_we,
		.raystore_write_addr,
		.raystore_write_data
	);

  // larb
	
  logic [1:0][$bits(leaf_info_t)-1:0] larb_data_us;
  logic [1:0] larb_valid_us, larb_stall_us;
  
  always_comb begin
    larb_data_us[0] = trav0_to_larb_data;
    larb_valid_us[0] = trav0_to_larb_valid;
    trav0_to_larb_stall = larb_stall_us[0];
    
    larb_data_us[1] = int_to_larb_data;
    larb_valid_us[1] = int_to_larb_valid;
    int_to_larb_stall = larb_stall_us[1];
  end 
  
  arbitor #(.NUM_IN(2), .WIDTH($bits(leaf_info_t))) larb(
		.clk,
		.rst,
		.valid_us(larb_valid_us),
		.stall_us(larb_stall_us),
		.data_us(larb_data_us),
		.valid_ds(larb_to_lcache_valid),
		.stall_ds(larb_to_lcache_stall),
		.data_ds(larb_to_lcache_data)
	);


  // int
	int_unit int_unit_inst(
		.clk,
		.rst,
		.rs_to_int_valid,
		.rs_to_int_data,
		.rs_to_int_stall,
		.int_to_list_valid,
		.int_to_list_data,
		.int_to_list_stall,
		.int_to_larb_valid,
		.int_to_larb_data,
		.int_to_larb_stall
	);


  // list
	list_unit list_unit_inst(
		.clk,
		.rst,
		.trav0_to_list_valid,
		.trav0_to_list_data,
		.trav0_to_list_stall,
		.trav1_to_list_valid(1'b0),
		.trav1_to_list_data(41`DC),
		.trav1_to_list_stall(),
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

endmodule
