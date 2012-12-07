
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

//------------------------------------------------------------------------
  // rayID Fifo instantiation
  rayID_t rayID_fifo_in, rayID_fifo_out;

	logic	  rayID_rdreq;
	logic	  rayID_wrreq;
	logic	  rayID_empty;
	logic	  rayID_full;
  logic [8:0] num_rays_in_fifo;

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


//------------------------------------------------------------------------
  // scache arbitration


//------------------------------------------------------------------------
  // miss_or_shadow arbitration



//------------------------------------------------------------------------
  // sendshadow



//------------------------------------------------------------------------
  // triidstate



//------------------------------------------------------------------------
  // dirpint



//------------------------------------------------------------------------
  // sendreflect



//------------------------------------------------------------------------
  // calcdirect
  

//------------------------------------------------------------------------
  // BMcalc



//------------------------------------------------------------------------
  // ray_issue arbitration


endmodule
