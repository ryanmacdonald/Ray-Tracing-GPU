
module pix_store (
  input logic clk, rst,
  
  input pixelID_t wdata_pix_store,
  input rayID_t waddr_pix_store,
  input logic we_pix_store,
  
    
  input rayID_t arb_to_pix_store_data,
  input logic arb_to_pix_store_valid,
  output logic arb_to_pix_store_stall,
  
  
  input logic pix_store_to_cc_stall,
  output pix_store_t pix_store_to_cc_data,
  output logic pix_store_to_cc_vald


  );




//------------------------------------------------------------------------
  // pix_store bram

  logic wren_pix_store;
  

  bram_dual_rw_512x19 pix_store_bram(
  //.aclr(rst),
  .rdaddress(raddr_pix_store),
  .wraddress(waddr_pix_store),
  .clock(clk),
  .data(wrdata_pix_store),
  .wren(wren_pix_store),
  .q(rddata_pix_store) );


//------------------------------------------------------------------------
  pixelID_t pix_store_VSpipe_in, pix_store_VSpipe_out;

  logic pix_store_VSpipe_valid_us, pix_store_VSpipe_stall_us;
  logic pix_store_VSpipe_valid_ds, pix_store_VSpipe_stall_ds;
  logic [1:0] num_left_in_pix_store_fifo;



  pipe_valid_stall #(.WIDTH($bits(pix_store_VSpipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(pix_store_VSpipe_valid_us),
    .us_data(pix_store_VSpipe_in),
    .us_stall(pix_store_VSpipe_stall_us),
    .ds_valid(pix_store_VSpipe_valid_ds),
    .ds_data(pix_store_VSpipe_out),
    .ds_stall(pix_store_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_pix_store_fifo) );

  
//------------------------------------------------------------------------
  //fifo for pixel buffer


  struct packed {
    pixelID_t pixelID;
    float_color_t f_color;
  } pix_store_fifo_in, pix_store_fifo_out;
  
  logic pix_store_fifo_full;
  logic pix_store_fifo_empty;
  logic pix_store_fifo_re;
  logic pix_store_fifo_we;

  always_comb begin
    pix_store_fifo_in.pixelID = rddata_pix_store;
    pix_store_fifo_in.triID = pix_store_VSpipe_out.triID;
    pix_store_fifo_in.is_hit = pix_store_VSpipe_out.is_hit;
    pix_store_fifo_in.bb_miss = pix_store_VSpipe_out.bb_miss; // added bb_miss for testing
    pix_store_fifo_in.is_shadow = pix_store_VSpipe_out.is_shadow; 
  end
  assign pix_store_fifo_re = ~pb_full & ~pix_store_fifo_empty;
  assign pix_store_fifo_we = pix_store_VSpipe_valid_ds;
  assign pix_store_VSpipe_stall_ds = pb_full & ~pix_store_fifo_empty;
  assign pb_we = pix_store_fifo_re ;

  fifo #(.DEPTH(3), .WIDTH($bits(pix_store_fifo_in)) ) pix_store_fifo_inst(
    .clk, .rst,
    .data_in(pix_store_fifo_in),
    .data_out(pix_store_fifo_out),
    .full(pix_store_fifo_full),
    .empty(pix_store_fifo_empty),
    .re(pix_store_fifo_re),
    .we(pix_store_fifo_we),
    .num_left_in_fifo(num_left_in_pix_store_fifo),
    .exists_in_fifo());


endmodule    
