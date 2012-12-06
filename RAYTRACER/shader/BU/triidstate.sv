
module triidstate(
  input clk, rst,

  input logic is_init,
  input rayID_T 

  input logic triidstate_valid_us,
  input shadow_or_miss_t triidstate_data_us,
  output logic triidstate_stall_us,

  input logic wren_triID,
  input triID_t triid_wrdata,

  output logic triidstate_to_scache_valid,
  output triidstate_to_scache_t triidstate_to_scache_data,
  input logic triidstate_to_scache_stall,

  output logic early_miss_valid,
  output raydone_t early_miss_data,
  input logic early_miss_stall

  );

  // triid block ram

  logic wren_triid;
  rayID_t raddr_triid;
  pixelID_t rddata_triid;
  assign raddr_triid = arb_to_triid_data;

  bram_dual_rw_512x16 triid_bram(
  //.aclr(rst),
  .rdaddress(raddr_triid),
  .wraddress(waddr_triid),
  .clock(clk),
  .data(wdata_triid),
  .wren(wren_triid),
  .q(rddata_triid) );

  
//---------------------------------------------------------------------------
  // state block ram // needs to be initialized to 0s.  ZEROS!!!!!!

  logic wren_state;
  rayID_t raddr_state;
  logic [3:0] rddata_state;
  assign raddr_state = arb_to_state_data;

  bram_dual_rw_512x4 state_bram(
  //.aclr(rst),
  .rdaddress(raddr_state),
  .wraddress(waddr_state),
  .clock(clk),
  .data(wdata_state),
  .wren(wren_state),
  .q(rddata_state) );

  

//---------------------------------------------------------------------------
  struct packed {
    rayID_t rayID;
    logic is_shadow;
    logic is_miss;
  } triidstate_VSpipe_in, triidstate_VSpipe_out;

  logic triidstate_VSpipe_valid_us, triidstate_VSpipe_stall_us;
  logic triidstate_VSpipe_valid_ds, triidstate_VSpipe_stall_ds;
  logic [1:0] num_left_in_triidstate_fifo;

  assign triidstate_VSpipe_valid_us = arb_to_triidstate_valid;
  assign triidstate_VSpipe_in = arb_to_triidstate_data.f_color;

  pipe_valid_stall #(.WIDTH($bits(triidstate_VSpipe_in)), .DEPTH(4)) pipe_inst(
    .clk, .rst,
    .us_valid(triidstate_VSpipe_valid_us),
    .us_data(triidstate_VSpipe_in),
    .us_stall(triidstate_VSpipe_stall_us),
    .ds_valid(triidstate_VSpipe_valid_ds),
    .ds_data(triidstate_VSpipe_out),
    .ds_stall(triidstate_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_triidstate_fifo) );

  




endmodule
