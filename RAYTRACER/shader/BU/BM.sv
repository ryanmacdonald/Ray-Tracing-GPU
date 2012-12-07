
module BM(
  input logic clk, rst,
  input logic v0,v1,v2,

  input is_init,
  rayID_t init_rayID,

  input calc_direct_to_BM_t calc_direct_to_BM_data,
  input logic calc_direct_to_BM_valid,
  output logic calc_direct_to_BM_stall,
  
  
  input logic BM_to_raydone_stall,
  output raydone_t BM_to_raydone_data,
  output logic BM_to_raydone_valid


  );

  logic stall_TMP_us, valid_TMP_us;
  calc_direct_to_BM_t data_TMP_us, data_TMP_buf;


  VS_buf #(.WIDTH($bits(calc_direct_to_BM_t) VS_buf1 (
    .clk, .rst,
    .stall_us(calc_direct_to_BM_stall),
    .data_us(calc_direct_to_BM_data),
    .valid_us(calc_direct_to_BM_valid),
    .stall_ds(stall_TMP_us),
    .data_ds(data_TMP_us),
    .valid_ds(valid_TMP_us)
  );

  assign stall_TMP_us = (~v0 | pipevs_stall_us) & valid_TMP_us;

  ff_ar_en #($bits(calc_direct_to_BM_t), 0) (.q(data_TMP_buf), .d(data_TMP_us), .en(valid_TMP_us & ~stall_TMP_us), .clk, .rst)
 

  
  struct packed {
    rayID_t rayID;
    logic is_last;
  } pipevs_in, pipevs_out;

  logic pipevs_valid_us, pipevs_stall_us;
  logic pipevs_valid_ds, pipevs_stall_ds;
  logic [4:0] num_left_in_BM_fifo;

  assign pipevs_valid_us = valid_TMP_us;
  always_comb begin
    pipevs_in.rayID = data_TMP_us.rayID;
    pipevs_in.is_last = data_TMP_us.is_last;
  end

  pipe_valid_stall #(.WIDTH($bits(pipevs_in)), .DEPTH(16)) pipe_inst(
    .clk, .rst,
    .us_valid(pipevs_valid_us),
    .us_data(pipevs_in),
    .us_stall(pipevs_stall_us),
    .ds_valid(pipevs_valid_ds),
    .ds_data(pipevs_out),
    .ds_stall(pipevs_stall_ds),
    .num_left_in_fifo(num_left_in_BM_fifo) );
 
  
  
  
  
  //------------------------------------------------------------------------
  // bmstore bram

  struct packed {
    float_color_t B;
    float_color_t M;
  } rddata_bmstore, wdata_bmstore;
  
  logic we_bmstore;
  rayID_t raddr_bmstore, waddr_bmstore, waddr_bmstore_internal;

  assign raddr_bmstore = v0 ? data_TMP_us.rayID : data_TMP_buf.rayID ;


  bram_dual_rw_512x bmstore_bram(
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
    buf1_in.direct = v0 ? data_TMP_us.f_color.red : (v1 ? data_TMP_buf.f_color.green : data_TMP_buf.f_color.blue);
    buf1_in.spec = v0 ? data_TMP_us.spec : data_TMP_buf.spec;
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


  
   float_t buf3_in, buf3_out;

  assign buf3_in = out_mult_M;
  buf_t3 #(.LAT(7), .WIDTH($bits(float_t))) 
      buf3(.data_in(buf3_in), .data_out(buf3_out), .clk, .rst);
 

  // Add X
  float_t inA_add_B, inB_add_B, out_add_B;
  logic nan_add_B, overflow_add_B, underflow_add_B, zero_add_B;

  assign inA_add_B = out_mult_B;
  assign inB_add_B = buf2_out;
  altfp_add add_B(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_B ),
  .datab(inB_add_B ),
  .nan(nan_add_B ),
  .overflow(overflow_add_B ),
  .result(out_add_B ),
  .underflow(underflow_add_B ),
	.zero(zero_add_B) );

  float_t outbuf1, outbuf1_n, outbuf2, outbuf2_n; 
  
  struct packed {
    float_t b;
    float_t m;
  } math_out, outbuf1, outbuf2;

  always_comb begin
    math_out.b = out_add_B;
    math_out.m = buf3_out;
  end
  ff_ar_en #($bits(math_out), 0) outbuf1_inst(.q(outbuf1), .d(math_out), .en(v2 ), .clk, .rst)
  ff_ar_en #($bits(math_out), 0) outbuf2_inst(.q(outbuf2), .d(math_out), .en(v0 ), .clk, .rst)

  `ifndef SYNTH
    always @(posedge clk) assert(pipeVS_valid_ds ? v0 : 1);
  `endif

  assign we_bmstore = is_init | pipeVS_valid_ds ;
  
  float_color_t finB, finM;
  
  always_comb begin
    finB.red = outbuf1.b;
    finB.green = outbuf2.b;
    finB.blue = math_out.b;
    finM.red = outbuf1.m;
    finM.green = outbuf2.m;
    finM.blue = math_out.m;
 end


  always_comb begin
    if(is_init | pipeVS_out.is_last) begin
      wdata_bmstore.B = {`FP0,`FP0,`FP0};
      wdata_bmstore.M = {`FP1,`FP1,`FP1};
      waddr_bmstore = init_rayID;
    end
      wdata_bmstore.B = finB;
      wdata_bmstore.M = finM;
      waddr_bmstore = pipevs_out.rayID;
    end
  end

//------------------------------------------------------------------------
  
  raydone_t BM_fifo_in, BM_fifo_out;
  
  logic BM_fifo_full;
  logic BM_fifo_empty;
  logic BM_fifo_re;
  logic BM_fifo_we;
  
  always_comb begin
    BM_fifo_in.rayID = pipevs_out.rayID ;
    BM_fifo_in.f_color = out_add_B ;
  end

  assign BM_fifo_we = pipevs_valid_ds & pipevs_out.is_last;

  fifo #(.DEPTH(17), .WIDTH($bits(float_t)) ) BM_fifo_inst(
    .clk, .rst,
    .data_in(BM_fifo_in),
    .data_out(BM_fifo_out),
    .full(BM_fifo_full),
    .empty(BM_fifo_empty),
    .re(BM_fifo_re),
    .we(BM_fifo_we),
    .num_left_in_fifo(num_left_in_BM_fifo),
    .exists_in_fifo());

  assign BM_to_raysdone_data = BM_fifo_out;
  assign BM_to_raydone_valid = ~BM_fifo_empty;

  assign BM_fifo_re = ~BM_fifo_empty & ~BM_to_raydone_stall;


endmodule

