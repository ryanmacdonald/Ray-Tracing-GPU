
module pixstore (
  input logic clk, rst,
  
  input pixelID_t wdata_pixstore,
  input rayID_t waddr_pixstore,
  input logic we_pixstore,
  
    
  input arb_to_pixstore_data_t arb_to_pixstore_data,
  input logic arb_to_pixstore_valid,
  output logic arb_to_pixstore_stall,
  
  
  input logic pixstore_to_cc_stall,
  output pixstore_to_cc_t pixstore_to_cc_data,
  output logic pixstore_to_cc_vald


  );




//------------------------------------------------------------------------
  // pixstore bram

  logic wren_pixstore;
  rayID_t raddr_pixstore;
  pixID_t rddata_pixstore;
  assign raddr_pixstore = arb_to_pixstore_data;

  bram_dual_rw_512x19 pixstore_bram(
  //.aclr(rst),
  .rdaddress(raddr_pixstore),
  .wraddress(waddr_pixstore),
  .clock(clk),
  .data(wrdata_pixstore),
  .wren(wren_pixstore),
  .q(rddata_pixstore) );


//------------------------------------------------------------------------
  pixelID_t pixstore_VSpipe_in, pixstore_VSpipe_out;

  logic pixstore_VSpipe_valid_us, pixstore_VSpipe_stall_us;
  logic pixstore_VSpipe_valid_ds, pixstore_VSpipe_stall_ds;
  logic [1:0] num_left_in_pixstore_fifo;

  assign pixstore_VSpipe_valid_us = arb_to_pixstore_valid;
  always_comb begin
    pixstore_VSpipe_data_us.
  end

  pipe_valid_stall #(.WIDTH($bits(pixstore_VSpipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(pixstore_VSpipe_valid_us),
    .us_data(pixstore_VSpipe_in),
    .us_stall(pixstore_VSpipe_stall_us),
    .ds_valid(pixstore_VSpipe_valid_ds),
    .ds_data(pixstore_VSpipe_out),
    .ds_stall(pixstore_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_pixstore_fifo) );

  
//------------------------------------------------------------------------
  //fifo for pixel buffer


  struct packed {
    pixelID_t pixelID;
    float_color_t f_color;
  } pixstore_fifo_in, pixstore_fifo_out;
  
  logic pixstore_fifo_full;
  logic pixstore_fifo_empty;
  logic pixstore_fifo_re;
  logic pixstore_fifo_we;

  always_comb begin
    pixstore_fifo_in.pixelID = rddata_pixstore;
    pixstore_fifo_in.triID = pixstore_VSpipe_out.triID;
    pixstore_fifo_in.is_hit = pixstore_VSpipe_out.is_hit;
    pixstore_fifo_in.bb_miss = pixstore_VSpipe_out.bb_miss; // added bb_miss for testing
    pixstore_fifo_in.is_shadow = pixstore_VSpipe_out.is_shadow; 
  end
  assign pixstore_fifo_re = ~pb_full & ~pixstore_fifo_empty;
  assign pixstore_fifo_we = pixstore_VSpipe_valid_ds;
  assign pixstore_VSpipe_stall_ds = pb_full & ~pixstore_fifo_empty;
  assign pb_we = pixstore_fifo_re ;

  fifo #(.DEPTH(3), .WIDTH($bits(pixstore_fifo_in)) ) pixstore_fifo_inst(
    .clk, .rst,
    .data_in(pixstore_fifo_in),
    .data_out(pixstore_fifo_out),
    .full(pixstore_fifo_full),
    .empty(pixstore_fifo_empty),
    .re(pixstore_fifo_re),
    .we(pixstore_fifo_we),
    .num_left_in_fifo(num_left_in_pixstore_fifo),
    .exists_in_fifo());


endmodule    
