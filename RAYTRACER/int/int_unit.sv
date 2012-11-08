/* 
  Fully pipelined 1/1 intersection unit.
  Takes in a cacheline (Matrix + translate)
  A ray_vec
  and does a intersection test with them (t_int > epsilon && bari_test)  NO MAX test unless add mailbox
  
  // This also decides if it is the last triangle / decrements the triangle count // inc list index

*/

// TODO TODO TODO
/*
  Update to have 2 seperate fifos for the outports. Then port the higher of the two fifo counts
  to the pipe_num_in_fifo port.  Also inc/dec the ln_tri stuff before you put in the vs_pipe

*/

module int_unit(
  input logic clk, rst,
  
  input logic icache_to_int_valid,
  input icache_to_int_t icache_to_int_data,
  output logic icache_to_int_stall,

  output logic int_to_list_valid,
  output int_to_list_t int_to_list_data,
  input logic int_to_list_stall,


  output logic int_to_larb_valid,
  output leaf_info_t int_to_larb_data,
  input logic int_to_larb_stall

  );



  // int_math signals
   int_cacheline_t int_cacheline;
   ray_vec_t ray_vec;

   logic hit;
   logic t_int_lt1;
   float_t t_int;
   bari_uv_t uv;


  // int_math instantiation
  assign int_cacheline = icache_to_int_data.tri_cacheline;
  assign ray_vec = icache_to_int_data.ray_vec;
  int_math fat_ass_unit(.*);

   
  // valid stall pipe 
  struct packed {
    ray_info_t ray_info;
    triID_t triID;
    ln_tri_t ln_tri;
  } int_pipe_in, int_pipe_out;
  
  logic pipe_ds_valid;
  logic pipe_ds_stall;
  logic [5:0] num_in_fifo;


  logic [5:0] list_num_fifo, larb_num_fifo ;


  always_comb begin
    int_pipe_in.ray_info = icache_to_int_data.ray_info ;
    int_pipe_in.triID = icache_to_int_data.triID ;
    int_pipe_in.ln_tri.lnum_left = icache_to_int_data.ln_tri.lnum_left - 1'b1;
    int_pipe_in.ln_tri.lindex = icache_to_int_data.ln_tri.lindex + 1'b1;
  end
  
  // The math pipleile is 45 latency
  pipe_valid_stall #(.WIDTH($bits(int_pipe_in)), .DEPTH(45)) pipe_inst(
    .clk, .rst,
    .us_valid(icache_to_int_valid),
    .us_data(int_pipe_in),
    .us_stall(icache_to_int_stall),
    .ds_valid(pipe_ds_valid),
    .ds_data(int_pipe_out),
    .ds_stall(pipe_ds_stall),
    .num_in_fifo(list_num_fifo>larb_num_fifo ? list_num_fifo : larb_num_fifo ) );
 
  assign pipe_ds_stall = int_to_larb_stall | int_to_list_stall ;

  logic	  list_rdreq;
	logic	  list_wrreq;
	logic	  list_empty;
	logic	  list_full;

  int_to_list_t list_fifo_in, list_fifo_out;

	logic	  larb_rdreq;
	logic	  larb_wrreq;
	logic	  larb_empty;
	logic	  larb_full;
  
  leaf_info_t larb_fifo_in, larb_fifo_out;
  
  logic is_last;
  logic is_occ_hit;
  assign is_occ_hit = int_pipe_out.ray_info.is_occular & hit & t_int_lt1;

  assign is_last = (int_pipe_out.ln_tri.lnum_left == 0) ;
  
  always_comb begin
    list_fifo_in.ray_info = int_pipe_out.ray_info;
    list_fifo_in.triID = int_pipe_out.triID;
    list_fifo_in.hit = hit | is_occ_hit;
    list_fifo_in.is_last = is_last ;
    list_fifo_in.t_int = t_int;
    list_fifo_in.uv = uv;
  end

  always_comb begin
    larb_fifo_in.ray_info = int_pipe_out.ray_info;
    larb_fifo_in.ln_tri.lindex = int_pipe_out.ln_tri.lindex;
    larb_fifo_in.ln_tri.lnum_left =  int_pipe_out.ln_tri.lnum_left;
  end
  
  
  `ifndef SYNTH
    always @(*) assert(!((list_full|larb_full) & pipe_ds_valid));
  `endif

  assign list_wrreq = pipe_ds_valid & (hit | is_last);
  assign larb_wrreq = pipe_ds_valid & (~is_last) & (~is_occ_hit);

  altbramfifo_w144_d45 list_fifo(
	.clock (clk),
	.data ( list_fifo_in),
	.rdreq(list_rdreq),
	.wrreq(list_wrreq),
	.empty(list_empty),
	.full(list_full),
	.q(list_fifo_out ),
  .usedw(list_num_fifo));

  altbramfifo_w144_d45 larb_fifo(
	.clock (clk),
	.data ( larb_fifo_in),
	.rdreq(larb_rdreq),
	.wrreq(larb_wrreq),
	.empty(larb_empty),
	.full(larb_full),
	.q(larb_fifo_out ),
  .usedw(larb_num_fifo));

  assign int_to_list_data = list_fifo_out;
  assign int_to_list_valid = ~list_empty;
  assign list_rdreq = int_to_list_valid & ~int_to_list_stall;

  assign int_to_larb_data = larb_fifo_out;
  assign int_to_larb_valid = ~larb_empty;
  assign larb_rdreq = int_to_larb_valid & ~int_to_larb_stall;


endmodule
