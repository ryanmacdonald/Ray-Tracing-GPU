
module simple_shader_unit(
  
  input logic clk, rst,


  input logic prg_to_shader_valid,
  input prg_ray_t prg_to_shader_data,
  output logic prg_to_shader_stall,

 

 // From pipeline representing completed rays
  input logic pcalc_to_shader_valid,
  input rs_to_pcalc_t pcalc_to_shader_data,
  output logic pcalc_to_shader_stall,

  input logic int_to_shader_valid,
  input int_to_shader_t int_to_shader_data,
  output logic int_to_shader_stall,

  input logic sint_to_shader_valid,
  input sint_to_shader_t sint_to_shader_data,
  output logic sint_to_shader_stall,

  input logic ss_to_shader_valid,
  input ss_to_shader_t ss_to_shader_data,
  output logic ss_to_shader_stall,

 


  // dealing with scache
  input logic scache_to_shader_valid,
  input scache_to_shader_t scache_to_shader_data,
  output logic scache_to_shader_stall,
  
  output logic shader_to_scache_valid,
  output shader_to_scache_t shader_to_scache_data,
  input logic shader_to_scache_stall,


  // Other outputs of the shader

  output logic pb_we,
  input logic pb_full,
  output pixel_buffer_entry_t pb_data_out,
 

  output logic shader_to_sint_valid,
  output shader_to_sint_t shader_to_sint_data,
  input logic shader_to_sint_stall,

	output logic raystore_we,
	output rayID_t raystore_write_addr,
	output ray_vec_t raystore_write_data


  );

   
  logic triidstate_valid_us;
  shadow_or_miss_t triidstate_data_us;
  logic triidstate_stall_us;

  logic wren_triid;
  triID_t triid_wrdata;
  logic is_spec_wrdata;

  logic triidstate_to_scache_valid;
  triidstate_to_scache_t triidstate_to_scache_data;
  logic triidstate_to_scache_stall;



  logic scache_to_sendshadow_valid;
  scache_to_sendshadow_t scache_to_sendshadow_data;
  logic scache_to_sendshadow_stall;

  logic sendshadow_to_sint_valid;
  shader_to_sint_t sendshadow_to_sint_data;
  logic sendshadow_to_sint_stall;

  logic sendshadow_to_arb_valid;
  shadow_or_miss_t sendshadow_to_arb_data;
  logic sendshadow_to_arb_stall;


  // dirpint
  ray_vec_t wdata_dirpint;  // origin has p_int; dir has dir
  rayID_t waddr_dirpint;
  logic we_dirpint;
  
  scache_to_shader_t scache_to_dirpint_data;
  logic scache_to_dirpint_valid;
  logic scache_to_dirpint_stall;
  
  logic dirpint_to_calcdirect_stall;
  dirpint_to_calc_direct_t dirpint_to_calc_direct_data;
  logic dirpint_to_calc_direct_valid;

  logic dirpint_to_sendreflect_stall;
  dirpint_to_sendreflect_t dirpint_to_sendreflect_data;
  logic dirpint_to_sendreflect_valid;


  
  logic send_reflect_to_sint_valid;
  shader_to_sint_t send_reflect_to_sint_data;
  logic send_reflect_to_sint_stall;


  logic send_prg_to_sint_valid;
  shader_to_sint_t send_prg_to_sint_data;
  logic send_prg_to_sint_stall;
  

  calc_direct_to_BM_t calc_direct_to_BM_data;
  logic calc_direct_to_BM_valid;
  logic calc_direct_to_BM_stall;
  
  
  logic BM_to_raydone_stall;
  raydone_t BM_to_raydone_data;
  logic BM_to_raydone_valid;

  
  pixelID_t wdata_pixstore;
  rayID_t waddr_pixstore;
  logic we_pixstore;
  
    
  raydone_t arb_to_pixstore_data;
  logic arb_to_pixstore_valid;
  logic arb_to_pixstore_stall;
  
  
  logic pixstore_to_cc_stall;
  pixstore_to_cc_t pixstore_to_cc_data;
  logic pixstore_to_cc_valid;





//------------------------------------------------------------------------
  // rayID Fifo instantiation
  rayID_t rayID_fifo_in, rayID_fifo_out;

	logic	  rayID_rdreq;
	logic	  rayID_wrreq;
	logic	  rayID_empty;
	logic	  rayID_full;
  logic [8:0] num_rays_in_fifo;

  assign rayID_fifo_in = is_init ? rayID_cnt : BM_to_raydone_data.rayID ;
  assign rayID_wrreq = is_init | (BM_to_raydone_valid & ~BM_to_raydone_stall);


  altbramfifo_w9_d512 rayID_fifo(
	.aclr(rst),
  .clock (clk),
	.data ( rayID_fifo_in),
	.rdreq(rayID_rdreq),
	.wrreq(rayID_wrreq),
	.empty(rayID_empty),
	.full(rayID_full),
	.q(rayID_fifo_out ),
  .usedw(num_rays_in_fifo) );

  assign rayID_rdreq = send_prg_to_sint_valid & ~wend_prg_to_shader_stall ;
  assign wren_ray_data = prg_to_shader_valid & ~prg_to_shader_stall ;
 
  assign send_prg_to_sint_valid = prg_to_shader_valid & ~rayID_empty;
  always_comb begin
    send_prg_to_sint_data.rayID = rayID_fifo_out;
    send_prg_to_sint_data.is_shadow = 1'b0 ;
    send_prg_to_sint_data.ray_vec.origin = prg_to_shader_data.origin;
    send_prg_to_sint_data.ray_vec.dir = prg_to_shader_data.dir;
  end


//------------------------------------------------------------------------
  // rayID initialization logic
  logic is_init, is_init_n;  // State bit for initializing 
  rayID_t init_rayID, init_rayID_n;
  assign init_rayID_n = is_init ? init_rayID + 1'b1 : 'h0 ;
  assign is_init_n = is_init ? (init_rayID == 9'd511 ? 1'b0 : 1'b1) : 1'b0 ; // TODO: replace magic number with parameterized expression
  ff_ar #($bits(rayID_t),'h0) init_rayID_buf(.d(init_rayID_n), .q(init_rayID), .clk, .rst);
  ff_ar #(1,1'b1) is_init_buf(.d(is_init_n), .q(is_init), .clk, .rst);
  


//------------------------------------------------------------------------
  // Pix_store
	
  assign wdata_pixstore = prg_to_shader_data.pixelID;
  assign waddr_pixstore = rayID_fifo_out;
  assign we_pixstore = rayID_rdreq ;

  pixstore pixstore_inst(
		.clk,
		.rst,
		.wdata_pixstore,
		.waddr_pixstore,
		.we_pixstore,
		.arb_to_pixstore_data,
		.arb_to_pixstore_valid,
		.arb_to_pixstore_stall,
		.pixstore_to_cc_stall,
		.pixstore_to_cc_data,
		.pixstore_to_cc_valid
	);

//------------------------------------------------------------------------
  // color convert

  
  color_convert color_convert_inst(
		.clk,
		.rst,
		.v0, .v1, .v2,
		.pixstore_to_cc_stall,
		.pixstore_to_cc_data,
		.pixstore_to_cc_valid,
		.cc_to_pixel_buffer_valid,
		.cc_to_pixel_buffer_data
	);

//------------------------------------------------------------------------
  // scache arbitration
  
 	logic [1:0] toscache_arb_valid_us;
  logic [1:0] toscache_arb_stall_us;
  logic [1:0][$bits(shader_to_scache_t)-1:0] toscache_arb_data_us;
  logic toscache_arb_valid_ds;
  logic toscache_arb_stall_ds;
  to_shader_t toscache_arb_data_ds;

  shader_to_scache_t from_pcalc, from_triidstate;
  always_comb begin
    from_pcalc.rayID = pcalc_to_shader_data.rayID;
    from_pcalc.triID = pcalc_to_shader_data.triID;
    from_pcalc.p_int = pcalc_to_shader_data.p_int;
    from_pcalc.is_miss = 1'b0;
    from_pcalc.is_shadow = 1'b0;
    from_pcalc.is_last = 1'b0 ;
    from_pcalc.is_dirpint = 1'b0 ;
  end
  
  always_comb begin
    from_triidstate.rayID = triidstate_to_scache_data.rayID;
    from_triidstate.triID = triidstate_to_scache_data.triID;
    from_triidstate.p_int = `DC ;
    from_triidstate.is_miss = triidstate_to_scache_data.is_miss;
    from_triidstate.is_shadow = triidstate_to_scache_data.is_shadow;
    from_triidstate.is_last = triidstate_to_scache_data.is_last;
    from_triidstate.is_dirpint = 1'b1 ;
  end
  

  always_comb begin
    toscache_arb_valid_us[0] = pcalc_to_shader_valid;
    toscache_arb_data_us[0] = from_pcalc;
    toscache_arb_valid_us[1] = triidstate_to_scache_valid;
    toscache_arb_data_us[1] = from_triidstate;
  end
  assign pcalc_to_shader_stall = toscache_arb_stall_us[0];
  assign triidstate_to_scache_stall = toscache_arb_stall_us[1];


  toscache_arbitor #(.NUM_IN(2), .WIDTH($bits(shader_to_scache_t))) to_scache_inst(
		.clk,
		.rst,
		.valid_us(toscache_arb_valid_us),
		.stall_us(toscache_arb_stall_us),
		.data_us(toscache_arb_data_us),
		.valid_ds(toscache_arb_valid_ds),
		.stall_ds(toscache_arb_stall_ds),
		.data_ds(toscache_arb_data_ds)
	);



//------------------------------------------------------------------------
  // miss_or_shadow arbitration
 	
  logic [3:0] mos_arb_valid_us;
  logic [3:0] mos_arb_stall_us;
  logic [3:0][$bits(shadow_or_miss_t)-1:0] mos_arb_data_us;
  logic mos_arb_valid_ds;
  logic mos_arb_stall_ds;
  to_shader_t mos_arb_data_ds;

  always_comb begin
    mos_arb_valid_us[0] = send_shadow_to_arb_valid;
    mos_arb_data_us[0] = send_shadow_to_arb_data;
    
    mos_arb_valid_us[1] = send_shadow_to_arb_valid;
    mos_arb_data_us[1] = send_shadow_to_arb_data;
    
    mos_arb_valid_us[2] = send_shadow_to_arb_valid;
    mos_arb_data_us[2] = send_shadow_to_arb_data;

    mos_arb_valid_us[3] = send_shadow_to_arb_valid;
    mos_arb_data_us[3] = send_shadow_to_arb_data;
  end


  mos_arbitor #(.NUM_IN(4), .WIDTH($bits(shadow_or_miss_t))) to_scache_inst(
		.clk,
		.rst,
		.valid_us(mos_arb_valid_us),
		.stall_us(mos_arb_stall_us),
		.data_us(mos_arb_data_us),
		.valid_ds(mos_arb_valid_ds),
		.stall_ds(mos_arb_stall_ds),
		.data_ds(mos_arb_data_ds)
	);

//------------------------------------------------------------------------
  // sendshadow
	send_shadow send_shadow_inst(
		.clk,
		.rst,
		.v0, .v1, .v2,
		.scache_to_sendshadow_valid,
		.scache_to_sendshadow_data,
		.scache_to_sendshadow_stall,
		.sendshadow_to_sint_valid,
		.sendshadow_to_sint_data,
		.sendshadow_to_sint_stall,
		.shadow_or_miss_valid(send_shadow_to_arb_valid),
		.shadow_or_miss_data(send_shadow_to_arb_data),
		.shadow_or_miss_stall(send_shadow_to_arb_stall)
	);


//------------------------------------------------------------------------
  // triidstate
 triidstate triidstate_inst(
		.clk,
		.rst,
		.triidstate_valid_us,
		.triidstate_data_us,
		.triidstate_stall_us,
		.wren_triid,
		.triid_wrdata,
		.is_spec_wrdata,
		.triidstate_to_scache_valid,
		.triidstate_to_scache_data,
		.triidstate_to_scache_stall
	);



//------------------------------------------------------------------------
  // dirpint
	dirpint dirpint_inst(
		.clk,
		.rst,
		.wdata_dirpint,
		.waddr_dirpint,
		.we_dirpint,
		.scache_to_dirpint_data,
		.scache_to_dirpint_valid,
		.scache_to_dirpint_stall,
		.dirpint_to_calc_direct_stall,
		.dirpint_to_calc_direct_data,
		.dirpint_to_calc_direct_valid,
		.dirpint_to_sendreflect_stall,
		.dirpint_to_sendreflect_data,
		.dirpint_to_sendreflect_valid
	);



//------------------------------------------------------------------------
  // sendreflect
	send_reflect send_reflect_inst(
		.clk,
		.rst,
		.v0, .v1, .v2,
		.dirpint_to_sendreflect_valid,
		.dirpint_to_sendreflect_data,
		.dirpint_to_sendreflect_stall,
		.shader_to_sint_valid(send_reflect_to_sint_valid),
		.shader_to_sint_data(send_reflect_to_sint_data),
		.shader_to_sint_stall(send_reflect_to_sint_stall)
	);


//------------------------------------------------------------------------
  // calc_direct
  	calc_direct calc_direct_inst(
		.clk,
		.rst,
		.v0, .v1, .v2,
		.ambient,
		.light_color,
		.dirpint_to_calc_direct_stall,
		.dirpint_to_calc_direct_data,
		.dirpint_to_calc_direct_valid,
		.calc_direct_to_BM_stall,
		.calc_direct_to_BM_data,
		.calc_direct_to_BM_valid
	);



//------------------------------------------------------------------------
  // BMcalc
	BM BM_inst(
		.clk,
		.rst,
		.is_init,
		.calc_direct_to_BM_data,
		.calc_direct_to_BM_valid,
		.calc_direct_to_BM_stall,
		.BM_to_raydone_stall,
		.BM_to_raydone_data,
		.BM_to_raydone_valid
	);



//------------------------------------------------------------------------
  // ray_issue arbitration



endmodule
