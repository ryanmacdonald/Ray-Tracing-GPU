
module simple_shader_unit(
  
  input logic clk, rst,


  input logic prg_to_shader_valid,
  input prg_ray_t prg_to_shader_data,
  output logic prg_to_shader_stall,

  
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
  rayID_t rayID_cnt, rayID_cnt_n;
  assign rayID_cnt_n = is_init ? rayID_cnt + 1'b1 : 'h0 ;
  assign is_init_n = is_init ? (rayID_cnt == 9'd511 ? 1'b0 : 1'b1) : 1'b0 ;
  ff_ar #($bits(rayID_t),'h0) rayID_cnt_buf(.d(rayID_cnt_n), .q(rayID_cnt), .clk, .rst);
  ff_ar #(1,1'b1) is_init_buf(.d(is_init_n), .q(is_init), .clk, .rst);
  

//------------------------------------------------------------------------
  // ray_data bram
  struct packed {
    pixelID_t pixelID;
  } wrdata_ray_data, rddata_ray_data;

  rayID_t raddr_ray_data, waddr_ray_data;
  logic wren_ray_data;
  
  assign waddr_ray_data = rayID_fifo_out;
  assign wrdata_ray_data = prg_to_shader_data.pixelID;

  bram_dual_rw_512x19 ray_data_bram(
  //.aclr(rst),
  .rdaddress(raddr_ray_data),
  .wraddress(waddr_ray_data),
  .clock(clk),
  .data(wrdata_ray_data),
  .wren(wren_ray_data),
  .q(rddata_ray_data) );


//------------------------------------------------------------------------
  // pipe_VS for ray_data
  struct packed {
    logic is_hit;
    triID_t triID;
  } ray_data_VSpipe_in, ray_data_VSpipe_out;

  logic ray_data_VSpipe_valid_us, ray_data_VSpipe_stall_us;
  logic ray_data_VSpipe_valid_ds, ray_data_VSpipe_stall_ds;
  logic [1:0] num_left_in_ray_data_fifo;



  pipe_valid_stall #(.WIDTH($bits(ray_data_VSpipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(ray_data_VSpipe_valid_us),
    .us_data(ray_data_VSpipe_in),
    .us_stall(ray_data_VSpipe_stall_us),
    .ds_valid(ray_data_VSpipe_valid_ds),
    .ds_data(ray_data_VSpipe_out),
    .ds_stall(ray_data_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_ray_data_fifo) );

  
//------------------------------------------------------------------------
  //fifo for pixel buffer


  // ray_data Fifo instantiation
  struct packed {
    pixelID_t pixelID;
    triID_t triID;
    logic is_hit;
  } ray_data_fifo_in, ray_data_fifo_out;
  
  logic ray_data_fifo_full;
  logic ray_data_fifo_empty;
  logic ray_data_fifo_re;
  logic ray_data_fifo_we;

  always_comb begin
    ray_data_fifo_in.pixelID = rddata_ray_data;
    ray_data_fifo_in.triID = ray_data_VSpipe_out.triID;
    ray_data_fifo_in.is_hit = ray_data_VSpipe_out.is_hit;
  end
  assign ray_data_fifo_re = ~pb_full & ~ray_data_fifo_empty;
  assign ray_data_fifo_we = ray_data_VSpipe_valid_ds;
  assign ray_data_VSpipe_stall_ds = pb_full & ~ray_data_fifo_empty;
  assign pb_we = ray_data_fifo_re ;

  fifo #(.DEPTH(3), .WIDTH($bits(ray_data_fifo_in)) ) ray_data_fifo_inst(
    .clk, .rst,
    .data_in(ray_data_fifo_in),
    .data_out(ray_data_fifo_out),
    .full(ray_data_fifo_full),
    .empty(ray_data_fifo_empty),
    .re(ray_data_fifo_re),
    .we(ray_data_fifo_we),
    .num_left_in_fifo(num_left_in_ray_data_fifo),
    .exists_in_fifo());


  
//------------------------------------------------------------------------
  // output to pixel buffer
      // call calc_color function here.
  always_comb begin
    pb_data_out.color = calc_color(ray_data_fifo_out.is_hit,ray_data_fifo_out.triID);
    pb_data_out.pixelID = ray_data_fifo_out.pixelID;
  end


//------------------------------------------------------------------------
  typedef struct packed {
    rayID_t rayID;
    triID_t triID;
    logic is_hit;
  } to_shader_t;
  
  // Arbitor for the *to_shader units
  to_shader_t pcalc_data_in;
  to_shader_t sint_data_in;
  to_shader_t int_data_in;
  to_shader_t ss_data_in;
  always_comb begin
    pcalc_data_in.rayID = pcalc_to_shader_data.rayID ;
    pcalc_data_in.triID = pcalc_to_shader_data.triID ;
    pcalc_data_in.is_hit = 1'b1;
    int_data_in.rayID = int_to_shader_data.rayID;
    int_data_in.triID = 'd0; // `DC ;
    int_data_in.is_hit = 1'b1;
    sint_data_in.rayID = sint_to_shader_data.rayID ;
    sint_data_in.triID = 'd0; // `DC ;
    sint_data_in.is_hit = 1'b0;
    ss_data_in.rayID = ss_to_shader_data.rayID ;
    ss_data_in.triID = 'd0; // `DC ;
    ss_data_in.is_hit = 1'b0;
  end

 	logic [3:0] arb_valid_us;
  logic [3:0] arb_stall_us;
  logic [3:0][$bits(to_shader_t)-1:0] arb_data_us;
  logic arb_valid_ds;
  logic arb_stall_ds;
  to_shader_t arb_data_ds;
  always_comb begin
    arb_valid_us[0] = pcalc_to_shader_valid;
    arb_data_us[0] = pcalc_data_in;
    pcalc_to_shader_stall = arb_stall_us[0];
    
    arb_valid_us[1] = int_to_shader_valid;
    arb_data_us[1] = int_data_in;
    int_to_shader_stall = arb_stall_us[1];

    arb_valid_us[2] = sint_to_shader_valid;
    arb_data_us[2] = sint_data_in;
    sint_to_shader_stall = arb_stall_us[2];

    arb_valid_us[3] = ss_to_shader_valid;
    arb_data_us[3] = ss_data_in;
    ss_to_shader_stall = arb_stall_us[3];

 end

  arbitor #(.NUM_IN(4), .WIDTH($bits(to_shader_t))) arbitor_inst(
		.clk,
		.rst,
		.valid_us(arb_valid_us),
		.stall_us(arb_stall_us),
		.data_us(arb_data_us),
		.valid_ds(arb_valid_ds),
		.stall_ds(arb_stall_ds),
		.data_ds(arb_data_ds)
	);
 
  assign arb_stall_ds = arb_valid_ds & (ray_data_VSpipe_stall_us | is_init);
  always_comb begin
    ray_data_VSpipe_in.triID = arb_data_ds.triID;
    ray_data_VSpipe_in.is_hit = arb_data_ds.is_hit;
  end
  assign ray_data_VSpipe_valid_us = arb_valid_ds;
  assign raddr_ray_data = arb_data_ds.rayID;
  
  assign rayID_fifo_in = is_init ? rayID_cnt : arb_data_ds.rayID;
  assign rayID_wrreq = is_init | (arb_valid_ds & ~arb_stall_ds);

//------------------------------------------------------------------------
  // PRG -> sint/rs path
  ray_vec_t prg_ray_vec;
  assign prg_ray_vec.origin = prg_to_shader_data.origin;
  assign prg_ray_vec.dir = prg_to_shader_data.dir;

  assign prg_to_shader_stall = shader_to_sint_stall | rayID_empty;
  assign shader_to_sint_valid = prg_to_shader_valid & ~rayID_empty;
  always_comb begin
    shader_to_sint_data.rayID = rayID_fifo_out;
    shader_to_sint_data.is_shadow = 1'b0;
    shader_to_sint_data.ray_vec = prg_ray_vec;
  end
  assign rayID_rdreq = prg_to_shader_valid & ~prg_to_shader_stall ;
  assign wren_ray_data = prg_to_shader_valid & ~prg_to_shader_stall ;


  assign raystore_we = shader_to_sint_valid;
  assign raystore_write_addr = rayID_fifo_out;
  assign raystore_write_data = prg_ray_vec ;

//------------------------------------------------------------------------

  function color_t calc_color(logic is_hit, triID_t triID);
    if(~is_hit) return `MISS_COLOR;
    else begin
      unique case(triID)
        16'h0 : return `TRI_0_COLOR;
        16'h4 : return `TRI_1_COLOR;
      endcase
    end

  endfunction



endmodule

