/* 
  Fully pipelined 1/1 intersection unit.
  Takes in a cacheline (Matrix + translate)
  A ray_vec
  and does a intersection test with them (t_int > epsilon && bari_test)  NO MAX test unless add mailbox
  
  // This also decides if it is the last triangle / decrements the triangle count // inc list index

*/

module int_unit(
  input logic clk, rst,
  
  input logic rs_to_int_valid,
  input rs_to_int_t rs_to_int_data,
  output logic rs_to_int_stall,

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
  assign int_cacheline = rs_to_int_data.tri_cacheline;
  assign ray_vec = rs_to_int_data.ray_vec;
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

	logic	  list_full;
	logic	  larb_full;
  
  logic [7:0] list_num_in_fifo, larb_num_in_fifo;
  logic [8:0] list_num_fifo, larb_num_fifo ;
  assign list_num_fifo = {list_full,list_num_in_fifo};
  assign larb_num_fifo = {larb_full,larb_num_in_fifo};



  always_comb begin
    int_pipe_in.ray_info = rs_to_int_data.ray_info ;
    int_pipe_in.triID = rs_to_int_data.triID ;
    int_pipe_in.ln_tri.lnum_left = rs_to_int_data.ln_tri.lnum_left - 1'b1;
    int_pipe_in.ln_tri.lindex = rs_to_int_data.ln_tri.lindex + 1'b1;
  end
  
  logic int_us_stall;
  logic [8:0] min_num_left_in_fifo;
  assign min_num_left_in_fifo = 9'd256 - (list_num_fifo>larb_num_fifo ? list_num_fifo : larb_num_fifo) ;
  // The math pipleile is 45 latency
  pipe_valid_stall #(.WIDTH($bits(int_pipe_in)), .DEPTH(45), .NUM_W(9)) pipe_inst(
    .clk, .rst,
    .us_valid(rs_to_int_valid),
    .us_data(int_pipe_in),
    .us_stall(int_us_stall),
    .ds_valid(pipe_ds_valid),
    .ds_data(int_pipe_out),
    .ds_stall(pipe_ds_stall),
    .num_left_in_fifo(min_num_left_in_fifo) );
 
  assign pipe_ds_stall = int_to_larb_stall | int_to_list_stall ;
  assign rs_to_int_stall = int_us_stall & rs_to_int_valid ;

  logic	  list_rdreq;
	logic	  list_wrreq;
	logic	  list_empty;

  int_to_list_t list_fifo_in, list_fifo_out;

	logic	  larb_rdreq;
	logic	  larb_wrreq;
	logic	  larb_empty;
  
  struct packed {
    ray_info_t ray_info;
    logic [14:0] lindex;
    logic [5:0] lnum_left;
  } larb_fifo_in, larb_fifo_out;
  
  logic is_last;
  assign is_last = (int_pipe_out.ln_tri.lnum_left == 0) ;
  
  always_comb begin
    list_fifo_in.ray_info = int_pipe_out.ray_info;
    list_fifo_in.triID = int_pipe_out.triID;
    list_fifo_in.hit = hit;
    list_fifo_in.is_last = is_last ;
    list_fifo_in.t_int = t_int;
    list_fifo_in.uv = uv;
  end

  always_comb begin
    larb_fifo_in.ray_info = int_pipe_out.ray_info;
    larb_fifo_in.lindex = int_pipe_out.ln_tri.lindex[14:0];
    larb_fifo_in.lnum_left =  int_pipe_out.ln_tri.lnum_left;
  end
  
   
  
  `ifndef SYNTH
    always @(*) assert(!((list_full|larb_full) & pipe_ds_valid));
    initial $display("list_fifo width= %d\nlarb_fifo width=%d\n",$bits(int_to_list_t),$bits(leaf_info_t));
  `endif

  assign list_wrreq = pipe_ds_valid & (hit | is_last);
  assign larb_wrreq = pipe_ds_valid & (~is_last);

  altbramfifo_w129_d256 list_fifo(
	.aclr(rst),
  .clock (clk),
	.data ( list_fifo_in),
	.rdreq(list_rdreq),
	.wrreq(list_wrreq),
	.empty(list_empty),
	.full(list_full),
	.q(list_fifo_out ),
  .usedw(list_num_in_fifo));

  // Should be 36
  altbramfifo_w36_d256 larb_fifo(
	.aclr(rst),
  .clock (clk),
	.data ( larb_fifo_in),
	.rdreq(larb_rdreq),
	.wrreq(larb_wrreq),
	.empty(larb_empty),
	.full(larb_full),
	.q(larb_fifo_out ),
  .usedw(larb_num_in_fifo));

  assign int_to_list_data = list_fifo_out;
  assign int_to_list_valid = ~list_empty;
  assign list_rdreq = int_to_list_valid & ~int_to_list_stall;

  always_comb begin
    int_to_larb_data.ray_info = larb_fifo_out.ray_info;
    int_to_larb_data.ln_tri.lindex = larb_fifo_out.lindex;
    int_to_larb_data.ln_tri.lnum_left = larb_fifo_out.lnum_left;
  end
  assign int_to_larb_valid = ~larb_empty;
  assign larb_rdreq = int_to_larb_valid & ~int_to_larb_stall;


endmodule
