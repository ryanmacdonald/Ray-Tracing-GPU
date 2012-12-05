
module dirpint (
  input logic clk, rst,
  
  input ray_vec_t wdata_dirpint,  // origin has p_int, dir has dir
  input rayID_t waddr_dirpint,
  input logic we_dirpint,
  
  
  input scache_to_dirpint_t scache_to_dirpint_data,
  input logic scache_to_dirpint_valid,
  output logic scache_to_dirpint_stall,
  
  
  input logic dirpint_to_calcdirect_stall,
  output dirpint_to_cc_t dirpint_to_cc_data,
  output logic dirpint_to_cc_valid

  
  );




//------------------------------------------------------------------------
  // dirpint bram

  logic wren_dirpint;
  rayID_t raddr_dirpint;
  ray_vec_t rddata_dirpint;
  assign raddr_dirpint = scache_to_dirpint_data.rayID;

  bram_dual_rw_512x19 dirpint_bram(
  //.aclr(rst),
  .rdaddress(raddr_dirpint),
  .wraddress(waddr_dirpint),
  .clock(clk),
  .data(wdata_dirpint),
  .wren(we_dirpint),
  .q(rddata_dirpint) );


//------------------------------------------------------------------------
  float_color_t dirpint_VSpipe_in, dirpint_VSpipe_out;

  logic dirpint_VSpipe_valid_us, dirpint_VSpipe_stall_us;
  logic dirpint_VSpipe_valid_ds, dirpint_VSpipe_stall_ds;
  logic [1:0] num_left_in_dirpint_fifo;

  assign dirpint_VSpipe_valid_us = arb_to_dirpint_valid;
  assign dirpint_VSpipe_in = arb_to_dirpint_data.f_color;

  pipe_valid_stall #(.WIDTH($bits(dirpint_VSpipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(dirpint_VSpipe_valid_us),
    .us_data(dirpint_VSpipe_in),
    .us_stall(dirpint_VSpipe_stall_us),
    .ds_valid(dirpint_VSpipe_valid_ds),
    .ds_data(dirpint_VSpipe_out),
    .ds_stall(dirpint_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_dirpint_fifo) );

  
//------------------------------------------------------------------------
  //fifo for pixel buffer


  dirpint_to_cc_t dirpint_fifo_in, dirpint_fifo_out;
  
  logic dirpint_fifo_full;
  logic dirpint_fifo_empty;
  logic dirpint_fifo_re;
  logic dirpint_fifo_we;

  always_comb begin
    dirpint_fifo_in.pixelID = rddata_dirpint;
    dirpint_fifo_in.f_color = dirpint_VSpipe_out; 
  end
  assign dirpint_fifo_re = ~dirpint_to_cc_stall & ~dirpint_fifo_empty;
  assign dirpint_fifo_we = dirpint_VSpipe_valid_ds;
  assign dirpint_VSpipe_stall_ds = dirpint_to_cc_stall;
  assign dirpint_to_cc_valid = ~dirpint_fifo_empty ;
  assign dirpint_to_cc_data = dirpint_fifo_out ;

  fifo #(.DEPTH(3), .WIDTH($bits(dirpint_fifo_in)) ) dirpint_fifo_inst(
    .clk, .rst,
    .data_in(dirpint_fifo_in),
    .data_out(dirpint_fifo_out),
    .full(dirpint_fifo_full),
    .empty(dirpint_fifo_empty),
    .re(dirpint_fifo_re),
    .we(dirpint_fifo_we),
    .num_left_in_fifo(num_left_in_dirpint_fifo),
    .exists_in_fifo());


endmodule    
