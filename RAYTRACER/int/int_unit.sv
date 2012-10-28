/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/



module int_unit(
  input logic clk,
  input logic rst,
  
  input logic raystore_to_int_valid,
  output logic raystore_to_int_stall,
  input rayID_t raystore_to_int_rayID,
  input raystore_to_int_t raystore_to_int_data,

  // int to shortstack EM miss
  output logic int_to_shortstack_EM_valid,
  output rayID_t int_to_shortstack_EM_rayID,
  input logic int_to_shortstack_EM_stall,

  // int to shortstack miss
  output logic int_to_shortstack_valid,
  output rayID_t int_to_shortstack_rayID,
  input logic int_to_shortstack_stall,
 
  // int to shader
  output logic int_to_shader_valid,
  output rayID_t int_to_shader_rayID,
  output intersection_t int_to_shader_intersection,
  input logic int_to_shader_stall
  );
  

  logic v0, v1, v2;

  //inputs to math 
  logic valid_in;
  int_cacheline_t tri0_cacheline;
  
  int_cacheline_t tri1_cacheline;
  int_pipe1_t int_pipe1_in;
  ray_vec_t ray_vec_in;


  logic valid_out;
  logic hit_out;  // 1 if hit //0 if miss
  rayID_t rayID_out;
  intersection_t intersection_out;
  //output float_t tMax;

  // Early Miss outputs
  rayID_t EM_rayID_out;   // Early Miss Ray
  logic EM_miss;      // 1 if miss, 0 if hit
 

  always_comb begin
    tri0_cacheline = raystore_to_int_data.tri0_cacheline;
    tri1_cacheline = raystore_to_int_data.tri1_cacheline;
    int_pipe1_in.t_max = raystore_to_int_data.t_max;
    int_pipe1_in.tri0_ID = raystore_to_int_data.tri0_ID;
    int_pipe1_in.tri1_ID = raystore_to_int_data.tri1_ID;
    int_pipe1_in.tri1_valid = raystore_to_int_data.tri1_valid;
    int_pipe1_in.rayID = raystore_to_int_rayID;
  end

  int_math int_math_inst(.*);

  // Probably WAYYYY too conservative // TODO 
  assign raystore_to_int_stall = (int_to_shortstack_stall|int_to_shortstack_EM_stall|int_to_shader_stall)
                                  | (~v0);


  // EM fifo
  rayID_t EM_fifo_in, EM_fifo_out;
  logic EM_fifo_full, EM_fifo_empty, EM_fifo_we, EM_fifo_re;
  
  assign EM_fifo_in = EM_rayID_out;
  assign EM_fifo_we = EM_miss;
  
  `ifndef SYNTH
  //assert(!(EM_fifo_we & EM_fifo_full));
  `endif
  assign int_to_shortstack_EM_valid = ~int_to_shortstack_EM_stall & ~EM_fifo_empty;
  assign EM_fifo_re = int_to_shortstack_EM_valid;
  assign int_to_shortstack_EM_rayID = EM_fifo_out;

  fifo #(.K(4), .WIDTH($bits(rayID_t))) EM_fifo(
    .clk, .rst,
    .data_in(EM_fifo_in),
    .data_out(EM_fifo_out),
    .re(EM_fifo_re),
    .we(EM_fifo_we),
    .full(EM_fifo_full),
    .empty(EM_fifo_empty) );



  // Norm Miss fifo
  rayID_t normM_fifo_in, normM_fifo_out;
  logic normM_fifo_full, normM_fifo_empty, normM_fifo_we, normM_fifo_re;

  assign normM_fifo_in = rayID_out;
  assign normM_fifo_we = valid_out & ~hit_out;
  
  `ifndef SYNTH
  //assert(!(normM_fifo_we & normM_fifo_full));
  `endif
  assign int_to_shortstack_valid = ~int_to_shortstack_stall & ~normM_fifo_empty;
  assign normM_fifo_re = int_to_shortstack_valid;
  assign int_to_shortstack_rayID = normM_fifo_out;
  
  fifo #(.K(4), .WIDTH($bits(rayID_t))) normM_fifo(
    .clk, .rst,
    .data_in(normM_fifo_in),
    .data_out(normM_fifo_out),
    .re(normM_fifo_re),
    .we(normM_fifo_we),
    .full(normM_fifo_full),
    .empty(normM_fifo_empty) );



  // Hit fifo
  struct packed {
    rayID_t rayID;
    intersection_t intersection;
  } hit_fifo_in, hit_fifo_out;

  logic hit_fifo_full, hit_fifo_empty, hit_fifo_we, hit_fifo_re;

  assign hit_fifo_in = rayID_out;
  assign hit_fifo_we = valid_out & hit_out;
  
  `ifndef SYNTH
  //assert(!(hit_fifo_we & hit_fifo_full));
  `endif
  assign int_to_shader_valid = ~int_to_shader_stall & ~hit_fifo_empty;
  assign hit_fifo_re = int_to_shader_valid;
  assign int_to_shader_rayID = hit_fifo_out.rayID;
  assign int_to_shader_intersection = hit_fifo_out.intersection;

  fifo #(.K(4), .WIDTH($bits(hit_fifo_in))) hit_fifo(
    .clk, .rst,
    .data_in(hit_fifo_in),
    .data_out(hit_fifo_out),
    .re(hit_fifo_re),
    .we(hit_fifo_we),
    .full(hit_fifo_full),
    .empty(hit_fifo_empty) );




  logic [1:0] cnt_nV, cntV;

	assign cnt_nV = ((cntV == 2'b10) ? 2'b00 : cntV + 1'b1);
	
	ff_ar #(2,0) cnt(.q(cntV),.d(cnt_nV),.clk,.rst);

	assign v0 = (cntV == 2'b00);
	assign v1 = (cntV == 2'b01);
	assign v2 = (cntV == 2'b10);



endmodule




