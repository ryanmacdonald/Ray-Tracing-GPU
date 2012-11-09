
/*
  assume that we ONLY have radiacne rays HALLAYYYFUCKINGLUAH

  This is another Memory structure that is surounded by different ports with perform different operations
  the list structure is indexed by rayID.
  list_row = [hit, triID, bary_uv, t_int_cur, t_max_leaf] // TODO maybe seperate out these into different brams


  Incoming ports
    trav_to_list (2 ports) // New Leaf node
      write(t_max_leaf);

    int_to_list (Tells of a hit or a miss of last triangle in leaf) // FUCKING COMPLICATED AS FUCK
        if(hit_in) {
            list_row.hit <= 1;
            if(t_int_cur > t_int_hit) {
                update(triID,bary_uv, t_int_cur)
      
            }
        }
        if(last_of_leaf) {
            if(hit & (t_int_cur <= t_max_leaf) ) { // Note this is the hit status after the hit_in
                list_to_shade <= Hit!!
                Clear list_row // set hit to 0
            }
            else { // report miss (even in the case where it was a hit outside of leaf node
                list_to_ss <= miss!
            }
        }

  Outgoing ports

    list_to_shade

    list_to_ss


*/


module list_unit(

  input logic clk, rst,
  
  input logic trav0_to_list_valid,
  input trav_to_list_t trav0_to_list_data,
  output logic trav0_to_list_stall,


  input logic trav1_to_list_valid,
  input trav_to_list_t trav1_to_list_data,
  output logic trav1_to_list_stall,


  input logic int_to_list_valid,
  input int_to_list_t int_to_list_data,
  output logic int_to_list_stall,


  output logic list_to_ss_valid,
  output list_to_ss_t list_to_ss_data,
  input logic list_to_ss_stall,


  output logic list_to_rs_valid,
  output list_to_rs_t list_to_rs_data,
  input logic list_to_rs_stall,



  );

  struct packed {
    bari_uv_t uv;
    triID_t triID;
  } list_pipe_in, list_pipe_out;

  logic list_pipe_valid_us, list_pipe_stall_us;
  logic list_pipe_valid_ds, list_pipe_stall_ds;
  logic [2:0] num_in_list_fifo;

  always_comb begin
    list_pipe_in.uv = int_to_list_data.uv;
    list_pipe_in.triID = int_to_list_data.triID;
  end
  assign list_pipe_valid_us = int_to_list_valid;
  assign int_to_list_stall = list_pipe_stall_us;
  assign list_pipe_stall_ds = ; // need to move down down down to the burning ring of fire
  

  pipe_valid_stall #(.WIDTH($bits(list_pipe_in)), .DEPTH(4)) list_pipe_inst(
    .clk, .rst,
    .us_valid(list_pipe_valid_us),
    .us_data(list_pipe_in),
    .us_stall(list_pipe_stall_us),
    .ds_valid(list_pipe_valid_ds),
    .ds_data(list_pipe_out),
    .ds_stall(list_pipe_stall_ds),
    .num_in_fifo(num_in_list_fifo) );


//------------------------------------------------------------------
  struct packed {
    logic hit_cur;
    float_t t_cur;
  } wrdata_t_cur, rddata_t_cur;

  logic [8:0] addr_t_cur;
  logic wren_t_cur;
  
  assign wrdata_t_cur = ; // later !
  assign addr_t_cur = int_to_list_data.ray_info.rayID;
  assign wren_t_cur = ;

  bram_512x33 t_cur_bram(
  .aclr(rst),
  .address(addr_t_cur),
  .clock(clk),
  .data(wrdata_t_cur),
  .wren(wren_t_cur),
  .q(rddata_t_cur),

//------------------------------------------------------------------

  struct {
    logic is_last;
    logic hit_in;
    logic t_int_in;
  } listbuf_in, listbuf_out, list_buf;
  
  always_comb begin
    listbuf_in.is_last = int_to_list.is_last;
    listbuf_in.hit_in = int_to_list.hit_in;
    listbuf_in.t_int_in  = int_to_list.t_int;
  end

  buf_t3 #(.LAT(2), .WIDTH($bits(listbuf_in))) 
    listbuf_buf11(.data_in(listbuf_in), .data_out(listbuf_out), .clk, .rst);

  ff_ar #($bits(list_buf),'h0) list_buf_reg(.d(listbuf_out), .q(list_buf), .clk, .rst);

//------------------------------------------------------------------
  logic leaf_read_valid, leaf_read_valid_n;
  rayID_t leaf_read_addr, leaf_read_addr_n;
  
  assign leaf_read_valid_n = ;
  assign leaf_read_addr_n = ;
  assign trav0_to_list_stall = ;
  assign trav1_to_list_stall = ;

  ff_ar #(1,1'b0) leaf_read_valid_reg(.d(leaf_read_valid_n), .q(leaf_read_valid), .clk, .rst);
  ff_ar #($bits(rayID_t),'h0) leaf_read_addr_reg(.d(leaf_read_addr_n), .q(leaf_read_addr), .clk, .rst);


  // The two trav_to_list are contending over port B of the leaf_max bram


//------------------------------------------------------------------
  logic [8:0] addrA_leaf_max, addrB_leaf_max;
  float_t wrdataA_leaf_max;
  float_t wrdataB_leaf_max;
  logic wrenA_leaf_max, wrenB_leaf_max;
  float_t rddataA_leaf_max;
  float_t rddataB_leaf_max;

  // reading always has addrA priority
  assign addrA_leaf_max = leaf_read_valid ? leaf_read_addr : trav0_to_list_data.rayID ;
  assign wrdataA_leaf_max = ;
  assign wrenA_leaf_max = ;
  assign addrB_leaf_max = ;
  assign wrdataB_leaf_max = ;
  assign wrenB_leaf_max = ;


    // TODO create my own fucking bram
   leaf_max rbram(
  .aclr(rst),
  .address_a(addrA_leaf_max),
  .address_b(addrB_leaf_max),
  .clock(clk),
  .data_a(wrdataA_leaf_max),
  .data_b(wrdataB_leaf_max),
  .wren_a(wrenA_leaf_max),
  .wren_b(wrenB_leaf_max),
  .q_a(rddataA_leaf_max),
  .q_b(rddataB_leaf_max));


//------------------------------------------------------------------


  float_t t_int_in_s3, t_int_in_s3_n;
  assign t_int_in_s3_n = ;
  ff_ar #($bits(float_t),'h0) t_int_in_s3_buf(.d(t_int_in_s3_n), .q(t_int_in_s3), .clk, .rst);



//------------------------------------------------------------------

  float_t t_cur_s3, t_cur_s3_n;
  assign t_cur_s3_n = ;
  ff_ar #($bits(float_t),'h0) t_cur_s3_buf(.d(t_cur_s3_n), .q(t_cur_s3), .clk, .rst);

  
//------------------------------------------------------------------

  float_t inA_comp_t_int, inB_comp_t_int;
  logic out_agb_comp_t_int;
  assign inA_comp_t_int = ;
  assign inB_comp_t_int = ;
  altfp_compare comp_t_int (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_t_int ),
  .datab(inB_comp_t_int ),
  //.aeb(out_aeb_comp_t_int),
	.agb(out_agb_comp_t_int) );


//------------------------------------------------------------------
  
  float_t inA_comp_leaf_max, inB_comp_leaf_max;
  logic out_agb_comp_leaf_max;
  logic out_aeb_comp_leaf_max;
  
  assign inA_comp_leaf_max = ;
  assign inB_comp_leaf_max = ;
  altfp_compare comp_leaf_max (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_leaf_max ),
  .datab(inB_comp_leaf_max ),
  .aeb(out_aeb_comp_leaf_max),
	.agb(out_agb_comp_leaf_max) );


//------------------------------------------------------------------

  float_t t_leaf_max_s4, t_leaf_max_s4_n;
  assign t_leaf_max_s4_n = ;
  ff_ar #($bits(float_t),'h0) t_leaf_max_s4_buf(.d(t_leaf_max_s4_n), .q(t_leaf_max_s4), .clk, .rst);

//------------------------------------------------------------------

  float_t t_best_s4, t_best_s4_n;
  assign t_best_s4_n = ;
  ff_ar #($bits(float_t),'h0) t_best_s4_buf(.d(t_best_s4_n), .q(t_best_s4), .clk, .rst);

//------------------------------------------------------------------
  // Bari, triID (intersection) ports
  
  struct packed {
    bari_uv_t uv;
    triID_t triID;
  } wrdata_int_info, rddata_int_info;

  logic [8:0] addr_int_info;
  logic wren_int_info;
  
  assign wrdata_int_info = ;
  assign addr_int_info = ;
  assign wren_int_info = ;

/*
  bram_84xx512 int_info_bram(
  .aclr(rst),
  .address(addr_int_info),
  .clock(clk),
  .data(wrdata_int_info),
  .wren(wren_int_info),
  .q(rddata_int_info),
*/


//------------------------------------------------------------------
 
  struct packed {
    ray_info_t ray_info;
    logic is_hit;
    float_t t;
  } last_fifo_in, last_fifo_out;

  // fifo to accumulate Definite misses and definite hits
  logic last_fifo_full;
  logic last_fifo_empty;
  logic last_fifo_re;
  logic last_fifo_we;
  logic [2:0] num_in_last_fifo;

  assign last_fifo_in = ;
  assign last_fifo_we = ;
  assign last_fifo_re = ;

  fifo #(.K(2), .WIDTH($bits(last_fifo_in)) ) last_fifo_inst(
    .clk, .rst,
    .data_in(last_fifo_in),
    .data_out(last_fifo_out),
    .full(last_fifo_full),
    .empty(last_fifo_empty),
    .re(last_fifo_re),
    .we(last_fifo_we),
    .num_in_fifo(num_in_last_fifo) );
  
  


//------------------------------------------------------------------
  // Hit path (list_to_rs)
//------------------------------------------------------------------
  // pipe_valid_stall for int_info
  struct packed {
    bari_uv_t uv;
    triID_t triID;
  } int_pipe_in, int_pipe_out;

  logic int_pipe_valid_us, int_pipe_stall_us;
  logic int_pipe_valid_ds, int_pipe_stall_ds;
  logic [2:0] num_in_int_fifo;

  assign int_pipe_in = ;
  assign int_pipe_valid_us = ;
  assign int_pipe_stall_ds = ; // need to move down down down to the burning ring of fire
  
  pipe_valid_stall #(.WIDTH($bits(int_pipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(int_pipe_valid_us),
    .us_data(int_pipe_in),
    .us_stall(int_pipe_stall_us),
    .ds_valid(int_pipe_valid_ds),
    .ds_data(int_pipe_out),
    .ds_stall(int_pipe_stall_ds),
    .num_in_fifo(num_in_int_fifo) );


//------------------------------------------------------------------
  // fifo for intersection
  struct packed {
    ray_info_t ray_info;
    logic is_hit;
    float_t t_int;
  } last_fifo_in, last_fifo_out;

  // fifo to accumulate Definite misses and definite hits
  logic last_fifo_full;
  logic last_fifo_empty;
  logic last_fifo_re;
  logic last_fifo_we;
  logic [2:0] num_in_last_fifo;

  assign last_fifo_in = ;
  assign last_fifo_we = ;
  assign last_fifo_re = ;

  fifo #(.K(2), .WIDTH($bits(last_fifo_in)) ) last_fifo_inst(
    .clk, .rst,
    .data_in(last_fifo_in),
    .data_out(last_fifo_out),
    .full(last_fifo_full),
    .empty(last_fifo_empty),
    .re(last_fifo_re),
    .we(last_fifo_we),
    .num_in_fifo(num_in_last_fifo) );


//------------------------------------------------------------------

  // output logic for intersection 
  assign trav_to_rs_valid = ;
  assign trav_to_rs_data = ;


//------------------------------------------------------------------
  // Buffer for misses and output logic
  
  trav_to_ss_t to_ss, to_ss_n;
  assign to_ss_n = ;
  ff_ar #($bits(trav_to_ss),'h0) to_ss_buf(.d(to_ss_n), .q(to_ss), .clk, .rst);
 
  assign trav_to_ss_valid = ;
  assign trav_to_ss_data = ;


//------------------------------------------------------------------

endmodule
