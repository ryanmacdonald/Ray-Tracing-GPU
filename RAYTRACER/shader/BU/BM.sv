
module BM(
  input clk, rst,
 
  input is_init,
  rayID_t init_rayID,

  input calc_direct_to_BM_t calc_direct_to_BM_data,
  input logic calc_direct_to_BM_valid,
  output logic calc_direct_to_BM_stall,
  
  
  input logic BM_to_raydone_stall,
  output raydone_t BM_to_raydone_data,
  output logic BM_to_raydone_valid,


  );

  
  
  
  
  
  
  //------------------------------------------------------------------------
  // bmstore bram

  struct packed {
    float_t B;
    float_t M;
  } rddata_bmstore, wdata_bmstore;
  
  
  rayID_t raddr_bmstore, waddr_bmstore, waddr_bmstore_internal;

  assign raddr_bmstore = calc_direct_to_BM_data.rayID;
  assign waddr_bm_store = is_init ? init_rayID : waddr_bmstore_internal;


  bram_dual_rw_512xaa bmstore_bram(
  //.aclr(rst),
  .rdaddress(raddr_bmstore),
  .wraddress(waddr_bmstore),
  .clock(clk),
  .data(wdata_bmstore),
  .wren(we_bmstore),
  .q(rddata_bmstore) );




  //------------------------------------------------------------------------

  struct packed {
    float_t direct;
    float16_t spec;
  } buf1_in, buf1_out;
  always_comb begin
    buf1_in.direct = calc_direct_to_BM_data.color;
    buf1_in.spec = calc_direct_to_BM_data.spec;
  end
  
  buf_t3 #(.LAT(2), .WIDTH($bits(buf1_in))) 
      buf1(.data_in(buf1_in), .data_out(buf1_out), .clk, .rst);




   // Multiply signals
  float_t inA_mult_B, inB_mult_B, out_mult_B;
  logic nan_mult_B, overflow_mult_B, underflow_mult_B, zero_mult_B;
 
  assign inA_mult_B = rddata_bmstore.M;
  assign inB_mult_B = buf1_out.direct;
  altfp_mult mult_B (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_B),
  .datab(inB_mult_B),
  .nan(nan_mult_B ),
  .overflow(overflow_mult_B ),
  .result(out_mult_B ),
  .underflow(underflow_mult_B ),
	.zero(zero_mult_B));

  
  
  float_t buf2_in, buf2_out;

  assign buf2_in = rddata_bmstore.B;
  buf_t3 #(.LAT(5), .WIDTH($bits(float_t))) 
      buf2(.data_in(buf2_in), .data_out(buf2_out), .clk, .rst);




   // Multiply signals
  float_t inA_mult_M, inB_mult_M, out_mult_M;
  logic nan_mult_M, overflow_mult_M, underflow_mult_M, zero_mult_M;
 
  assign inA_mult_M = rddata_bmstore.M;
  assign inB_mult_M = buf1_out.spec;
  altfp_mult mult_M (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_M),
  .datab(inB_mult_M),
  .nan(nan_mult_M ),
  .overflow(overflow_mult_M ),
  .result(out_mult_M ),
  .underflow(underflow_mult_M ),
	.zero(zero_mult_M));


  
  









  always_comb begin
    if(is_init) begin
      wdata_bmstore.B = `FP0;
      wdata_bmstore.M = `FP1;
    end
      wdata_bmstore
    end
  end



endmodule

