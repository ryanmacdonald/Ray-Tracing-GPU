module simple_shader_unit(
  
  input logic clk, rst,


  input logic prg_to_shader_valid,
  input prg_to_shader_t prg_to_shader_data,
  output logic prg_to_shader_stall,

  
  input logic pcalc_to_shader_valid,
  input pcalc_to_shader_t pcalc_to_shader_data,
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

  
  
  


  output logic shader_to_sint_valid,
  output shader_to_sint_t shader_to_sint_data,
  input logic shader_to_sint_stall,

	output logic raystore_we,
	output rayID_t raystore_write_addr,
	output ray_vec_t raystore_write_data,


  );




//------------------------------------------------------------------------
  // rayID Fifo instantiation
  rayID_t rayID_fifo_in, rayID_fifo_out;

	logic	  rayID_rdreq;
	logic	  rayID_wrreq;
	logic	  rayID_empty;
	logic	  rayID_full;
 
  assign rayID_fifo_in = ;
  assign rayID_rdreq = ;
  assign rayID_wrreq = ;

  altbramfifo_w9_d512 rayID_fifo(
	.clock (clk),
	.data ( rayID_fifo_in),
	.rdreq(rayID_rdreq),
	.wrreq(rayID_wrreq),
	.empty(rayID_empty),
	.full(rayID_full),
	.q(rayID_fifo_out ),
  .usedw(rayID_num_fifo));


//------------------------------------------------------------------------
  // rayID initialization logic
  logic is_init_n;  // State bit for initializing 
  rayID_t rayID_cnt, rayID_cnt_n;
  assign rayID_cnt_n = is_init ? rayID_cnt + 1'b1 : 'h0 ;
  assign is_init_n = is_init ? (rayID_cnt == 9'h511) : 1'b0 ;
  ff_ar #($bits(rayID_t),'h0) rayID_cnt_buf(.d(rayID_cnt_n), .q(rayID_cnt), .clk, .rst);
  ff_ar #(1,1'b1) is_init_buf(.d(is_init_n), .q(is_init), .clk, .rst);
  

//------------------------------------------------------------------------
  // ray_data bram
  struct packed {
    pixelID_t pixelID;
  } wrdata_ray_data, rddata_ray_data;

  rayID_t raddr_ray_data, waddr_ray_data;
  logic wren_ray_data;
  
  assign raddr_ray_data = ;
  assign waddr_ray_data = ;
  assign wren_ray_data = ;
  assign wrdata_ray_data = ;

  bram_dual_rw_512x ray_data_bram(
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
    triID_t triID;
    logic is_hit;
  } ray_data_VSpipe_in, ray_data_VSpipe_out;

  logic ray_data_VSpipe_valid_us, ray_data_VSpipe_stall_us;
  logic ray_data_VSpipe_valid_ds, ray_data_VSpipe_stall_ds;
  logic [1:0] num_left_in_ray_data_fifo;

  always_comb begin
    ray_data_VSpipe_in.triID = ;
    ray_data_VSpipe_in.is_hit = ;
  end
  assign ray_data_VSpipe_valid_us = ;
  assign ray_data_VSpipe_stall_ds =  ; 

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
  packed struct {
    pixelID_t pixelID;
    triID_t triID;
    logic is_hit;
  } ray_data_fifo_in, ray_data_fifo_out;

	logic	  ray_data_rdreq;
	logic	  ray_data_wrreq;
	logic	  ray_data_empty;
	logic	  ray_data_full;
 
  assign ray_data_fifo_in = ;
  assign ray_data_rdreq = ;
  assign ray_data_wrreq = ;

  altbramfifo_w9_d512 ray_data_fifo(
	.clock (clk),
	.data (ray_data_fifo_in),
	.rdreq(ray_data_rdreq),
	.wrreq(ray_data_wrreq),
	.empty(ray_data_empty),
	.full(ray_data_full),
	.q(ray_data_fifo_out ),
  .usedw(ray_data_num_fifo));


  
//------------------------------------------------------------------------
  // output to pixel buffer
      // call calc_color function here.






//------------------------------------------------------------------------
  // Arbitor for the *to_shader units
  

//------------------------------------------------------------------------
  // Small fifo for arbitor





  function color_t calc_color(logic is_miss, triID_t triID);
    if(is_miss) return `MISS_COLOR;
    else begin
      unique case(triID);
        16'h0 : return `TRI_0_COLOR;
        16'h1 : return `TRI_1_COLOR;
      endcase
    end

  endfunction



endmodule
