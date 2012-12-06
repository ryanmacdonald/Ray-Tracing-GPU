
module dirpint (
  input logic clk, rst,
  
  input ray_vec_t wdata_dirpint,  // origin has p_int, dir has dir
  input rayID_t waddr_dirpint,
  input logic we_dirpint,
  
  
  input scache_to_dirpint_t scache_to_dirpint_data,
  input logic scache_to_dirpint_valid,
  output logic scache_to_dirpint_stall,
  
  
  input logic dirpint_to_calcdirect_stall,
  output dirpint_to_calc_direct_t dirpint_to_calc_direct_data,
  output logic dirpint_to_calc_direct_valid,

  input logic dirpint_to_sendreflect_stall,
  output dirpint_to_sendreflect_t dirpint_to_sendreflect_data,
  output logic dirpint_to_sendreflect_valid
  
  
  );




//------------------------------------------------------------------------
  // dirpint bram

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
  struct packed {
    rayID_t rayID;
    vector24_t normal;
    float24_T f_color;
    logic is_miss;
    logic is_shadow;
    logic is_last;
  } dirpint_VSpipe_in, dirpint_VSpipe_out;

  logic dirpint_VSpipe_valid_us, dirpint_VSpipe_stall_us;
  logic dirpint_VSpipe_valid_ds, dirpint_VSpipe_stall_ds;
  logic [1:0] num_left_in_dirpint_fifo;

  assign dirpint_VSpipe_valid_us = arb_to_dirpint_valid;
  assign dirpint_VSpipe_in = arb_to_dirpint_data.f_color;

  always_comb begin
    dirpint_VSpipe_in.rayID = scache_to_dirpnt.rayID;
    dirpint_VSpipe_in.normal = scache_to_dirpnt.normal;
    dirpint_VSpipe_in.f_color = scache_to_dirpnt.f_color;
    dirpint_VSpipe_in.is_miss = scache_to_dirpnt.is_miss;
    dirpint_VSpipe_in.is_shadow = scache_to_dirpnt.is_shadow;
    dirpint_VSpipe_in.is_last = scache_to_dirpnt.is_last;
  end

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
  //fifo for dirpnt


  dirpint_to_cc_t dirpint_fifo_in, dirpint_fifo_out;
  
  logic dirpint_fifo_full;
  logic dirpint_fifo_empty;
  logic dirpint_fifo_re;
  logic dirpint_fifo_we;

  always_comb begin
    dirpint_fifo_in.rayID = rddata_dirpint;
    dirpint_fifo_in.f_color = dirpint_VSpipe_out; 
 // add more shit 
  
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

  logic good_to_sendreflect;
  assign good_to_sendreflect = dirpint_fifo_out.is_last & dirpint_fifo_out.is_shadow

  logic ds_stall;
  assign ds_stall = dirpint_to_calc_direct_stall | 
                   (dirpint_to_sendreflect_stall & ~dirpint_fifo_out.is_last);

  

  // Output to sendreflect
  always_comb begin
    dirpint_to_sendreflect = 
  end
  assign 


typedef struct packed {
  rayID_t rayID;
  vector_t dir;
  vector_t p_int; 
  vector_t normal;
} dirpint_to_sendreflect_t;


typedef struct packed {
  rayID_t rayID;
  float_t A; // ambient color of scene
  float_t K; // color of triangle
  float_t C; // 
  logic is_shadow;
  logic is_miss;
  logic is_last;
  vector_t N; // Normal
  vector_t p_int;  // point of intersection
  vector_t L; // Light Position  // TODO get rid of this vector and do the L calculation within directcalc
} dirpint_to_calc_direct_t;



endmodule    
