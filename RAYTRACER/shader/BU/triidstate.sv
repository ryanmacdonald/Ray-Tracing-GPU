
module triidstate(
  input clk, rst,

  input logic [3:0] max_reflect;

  input logic triidstate_valid_us,
  input shadow_or_miss_t triidstate_data_us,
  output logic triidstate_stall_us,

  input logic wren_triid,
  input rayID_t waddr_triid,
  input logic is_spec_wdata,
  input triID_t triid_wdata,
  
  
  output logic triidstate_to_scache_valid,
  output triidstate_to_scache_t triidstate_to_scache_data,
  input logic triidstate_to_scache_stall

  );

  
  
  
  
  
 //---------------------------------------------------------------------------
  struct packed {
    rayID_t rayID;
    logic is_shadow;
    logic is_miss;
  } triidstate_VSpipe_in, triidstate_VSpipe_out;

  logic triidstate_VSpipe_valid_us, triidstate_VSpipe_stall_us;
  logic triidstate_VSpipe_valid_ds, triidstate_VSpipe_stall_ds;
  logic [1:0] num_left_in_triidstate_fifo;

  assign triidstate_VSpipe_valid_us = triidstate_valid_us;
  always_comb begin
    triidstate_VSpipe_in.rayID = triidstate_data_us.rayID;
    triidstate_VSpipe_in.is_shadow = triidstate_data_us.is_shadow;
    triidstate_VSpipe_in.is_miss = triidstate_data_us.is_miss;
  end

  pipe_valid_stall #(.WIDTH($bits(triidstate_VSpipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(triidstate_VSpipe_valid_us),
    .us_data(triidstate_VSpipe_in),
    .us_stall(triidstate_VSpipe_stall_us),
    .ds_valid(triidstate_VSpipe_valid_ds),
    .ds_data(triidstate_VSpipe_out),
    .ds_stall(triidstate_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_triidstate_fifo) );

 
  
  
  
  
  
  
  // triid block ram
  rayID_t raddr_triid;
  struct packed {
    triID_t triID;
    logic is_spec;
  } wdata_triid_bram, rddata_triid;
  
  always_comb begin
    wdata_triid_bram.triID = triid_wdata;
    wdata_triid_bram.is_spec = is_spec_wdata;
  end
  assign raddr_triid = triidstate_data_us.rayID;
  
  bram_dual_rw_512x16 triid_bram(
  //.aclr(rst),
  .rdaddress(raddr_triid),
  .wraddress(waddr_triid),
  .clock(clk),
  .data(wdata_triid_bram),
  .wren(wren_triid),
  .q(rddata_triid) );

  
//---------------------------------------------------------------------------
  // state block ram // needs to be initialized to 0s.  ZEROS!!!!!!

  logic wren_state;
  rayID_t raddr_state;
  logic [3:0] rddata_state, wrdata_state;
  assign raddr_state = triidstate_data_us.rayID;
  assign waddr_state = triidstate_VSpipe_out.rayID;
  
  assign wren_state = triidstate_VSpipe_valid_ds;
  


  bram_dual_rw_512x4 state_bram(
  //.aclr(rst),
  .rdaddress(raddr_state),
  .wraddress(waddr_state),
  .clock(clk),
  .data(wdata_state),
  .wren(wren_state),
  .q(rddata_state) );

   logic is_last;
  assign is_last =   (triidstate_VSpipe_out.is_miss & ~triidstate_VSpipe_out.is_shadow) 
                   | (triidstate_VSpipe_out.is_shadow & raddr_state == max_reflect)
                   | (triidstate_VSpipe_out.is_shadow & ~rddata_triid.is_spec;

  assign wdata_state = is_last ? 4'h0 : raddr_state + 1'b1 ;
 


  `ifndef SYNTH
    always @(posedge clk) assert(rayID3.valid==triIDstate_valid_ds);
  `endif
 
  
//---------------------------------------------------------------------------
  
  triidstate_to_scache_t toscache_fifo_in, toscache_fifo_out;

  // fifo to accumulate Definite misses and definite hits
  logic toscache_fifo_full;
  logic toscache_fifo_empty;
  logic toscache_fifo_re;
  logic toscache_fifo_we;
  
  assign toscache_fifo_we = triidstate_VSpipe_valid_ds;
  always_comb begin
    toscache_fifo_in.rayID = tridstate_VSpipe_out.rayID ;
    toscache_fifo_in.triID = rddata_triid.triID ;
    toscache_fifo_in.is_shadow = tridstate_VSpipe_out.is_shadow ;
    toscache_fifo_in.is_miss = tridstate_VSpipe_out.is_miss ;
    toscache_fifo_in.is_last = is_last;
  end

  
  fifo #(.DEPTH(5), .WIDTH($bits(triidstate_to_scache_t)) ) scache_fifo_inst(
    .clk, .rst,
    .data_in(toscache_fifo_in),
    .data_out(toscache_fifo_out),
    .full(toscache_fifo_full),
    .empty(toscache_fifo_empty),
    .re(toscache_fifo_re),
    .we(toscache_fifo_we),
    .num_left_in_fifo(num_left_in_toscache_fifo),
    .exists_in_fifo());

  assign triidstate_to_scache_data = toscache_fifo_out;
  assign triidstate_to_scache_valid = ~toscache_fifo_empty ;
  assign toscache_fifo_re = triidstate_to_scache_valid & ~triidstate_to_scache_stall ;


endmodule
