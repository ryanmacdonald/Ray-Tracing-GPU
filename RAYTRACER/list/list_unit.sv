
/*
  assume that we ONLY have radiacne rays HALLAYYYFUCKINGLUAH

  This is another Memory structure that is surounded by different ports with perform different operations
  the list structure is indexed by rayID.
  list_row = [hit, triID, bary_uv, t_int_cur, t_max_leaf]


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
  input logic list_to_rs_stall



  );

  struct packed {
    ray_info_t ray_info;
    bari_uv_t uv;
    triID_t triID;
    logic is_last;
  } list_VSpipe_in, list_VSpipe_out;

  logic list_VSpipe_valid_us, list_VSpipe_stall_us;
  logic list_VSpipe_valid_ds, list_VSpipe_stall_ds;
  logic [2:0] num_left_in_last_fifo;

  always_comb begin
    list_VSpipe_in.ray_info = int_to_list_data.ray_info;
    list_VSpipe_in.uv = int_to_list_data.uv;
    list_VSpipe_in.triID = int_to_list_data.triID;
    list_VSpipe_in.is_last = int_to_list_data.is_last;
  end
  assign list_VSpipe_valid_us = int_to_list_valid;
  assign int_to_list_stall = list_VSpipe_stall_us;
  

  pipe_valid_stall #(.WIDTH($bits(list_VSpipe_in)), .DEPTH(4)) list_VSpipe_inst(
    .clk, .rst,
    .us_valid(list_VSpipe_valid_us),
    .us_data(list_VSpipe_in),
    .us_stall(list_VSpipe_stall_us),
    .ds_valid(list_VSpipe_valid_ds),
    .ds_data(list_VSpipe_out),
    .ds_stall(list_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_last_fifo) );


//------------------------------------------------------------------
  struct packed {
    logic hit_cur;
    float_t t_cur;
  } wrdata_t_cur, rddata_t_cur, rddata_t_cur_buf;

  rayID_t raddr_t_cur, waddr_t_cur;
  logic wren_t_cur;
  
  assign raddr_t_cur = int_to_list_data.ray_info.rayID;

  bram_dual_rw_512x33 t_cur_bram(
  //.aclr(rst),
  .rdaddress(raddr_t_cur),
  .wraddress(waddr_t_cur),
  .clock(clk),
  .data(wrdata_t_cur),
  .wren(wren_t_cur),
  .q(rddata_t_cur) );

//------------------------------------------------------------------

  struct packed {
    logic hit_in;
    float_t t_int_in;
  } listbuf_in, listbuf_out, listbuf_s3;
  
  always_comb begin
    listbuf_in.hit_in = int_to_list_data.hit;
    listbuf_in.t_int_in  = int_to_list_data.t_int;
  end

  buf_t3 #(.LAT(2), .WIDTH($bits(listbuf_in))) 
    listbuf_buf11(.data_in(listbuf_in), .data_out(listbuf_out), .clk, .rst);

  ff_ar #($bits(listbuf_s3),'h0) listbuf_s3_reg(.d(listbuf_out), .q(listbuf_s3), .clk, .rst);

//------------------------------------------------------------------
  logic leaf_read_valid, leaf_read_valid_n;
  rayID_t leaf_read_addr, leaf_read_addr_n;
  
  assign leaf_read_valid_n = int_to_list_valid & ~int_to_list_stall & int_to_list_data.is_last;
  assign leaf_read_addr_n = int_to_list_data.ray_info.rayID ;

  ff_ar #(1,1'b0) leaf_read_valid_reg(.d(leaf_read_valid_n), .q(leaf_read_valid), .clk, .rst);
  ff_ar #($bits(rayID_t),'h0) leaf_read_addr_reg(.d(leaf_read_addr_n), .q(leaf_read_addr), .clk, .rst);


  // The two trav_to_list are contending over port B of the leaf_max bram


//------------------------------------------------------------------
  rayID_t addrA_leaf_max, addrB_leaf_max;
  float_t wrdataA_leaf_max;
  float_t wrdataB_leaf_max;
  logic wrenA_leaf_max, wrenB_leaf_max;
  float_t rddataA_leaf_max;
  float_t rddataB_leaf_max;

	logic  rrp;
	logic leaf_contend;
	assign leaf_contend = trav0_to_list_valid & trav1_to_list_valid & leaf_read_valid;
	counter #(.W(1), .RV(1'b0)) tmax_leaf_arb_pointer(.cnt(rrp), .clr(1'b0), .inc(leaf_contend), .clk, .rst);


  // reading always has addrA priority
  assign addrA_leaf_max = leaf_read_valid ? leaf_read_addr : trav0_to_list_data.rayID ;
  assign wrdataA_leaf_max = trav0_to_list_data.t_max_leaf;
  assign wrenA_leaf_max = ~leaf_read_valid & trav0_to_list_valid;
  /*always_comb begin
    case({leaf_read_valid,trav0_to_list_valid,trav1_to_list_valid})
      3'b111 : addrB_leaf_max = rrp ? trav1_to_list_data.rayID : trav0_to_list_data.rayID ;
      3'b110 : addrB_leaf_max = trav0_to_list_data.rayID ;
      3'b101 : addrB_leaf_max = trav1_to_list_data.rayID ;
      3'b011 : addrB_leaf_max = trav1_to_list_data.rayID ;
      3'b001 : addrB_leaf_max = trav1_to_list_data.rayID ;
    endcase
  end
  assign addrB_leaf_max = (leaf_read_valid & trav0_to_list_valid & (~trav1_to_list_valid | ~rrp) ) ? 
                          trav0_to_list_data.rayID : trav1_to_list_data.rayID ;
  */
	// SKETCHY Changed this
  assign addrB_leaf_max = leaf_read_valid & ~rrp & trav0_to_list_valid ? trav0_to_list_data.rayID : trav1_to_list_data.rayID ;
  assign wrdataB_leaf_max = leaf_read_valid & trav0_to_list_valid & (~trav1_to_list_valid | ~rrp ) ? trav0_to_list_data.t_max_leaf : trav1_to_list_data.t_max_leaf ;
  assign wrenB_leaf_max = (trav0_to_list_valid & leaf_read_valid) | trav1_to_list_valid ;
  assign trav0_to_list_stall = leaf_contend & rrp ;
  assign trav1_to_list_stall = leaf_contend & ~rrp;


  bram_dual_2port_512x32 leaf_max_bram(
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

  ff_ar #($bits(rddata_t_cur_buf),'h0) t_cur_s3_buf(.d(rddata_t_cur), .q(rddata_t_cur_buf), .clk, .rst);

  
//------------------------------------------------------------------

  float_t inA_comp_t_int, inB_comp_t_int;
  logic out_agb_comp_t_int;
  assign inA_comp_t_int = listbuf_out.t_int_in;
  assign inB_comp_t_int = rddata_t_cur.t_cur;
  altfp_compare comp_t_int (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_t_int ),
  .datab(inB_comp_t_int ),
  .aeb(),
	.agb(out_agb_comp_t_int) );

  logic choose_t_in;
  assign choose_t_in =  listbuf_s3.hit_in & (~out_agb_comp_t_int | ~rddata_t_cur_buf.hit_cur);

  float_t t_int_win;
  assign t_int_win = choose_t_in ? listbuf_s3.t_int_in : rddata_t_cur_buf.t_cur ;

//------------------------------------------------------------------
  
  float_t inA_comp_leaf_max, inB_comp_leaf_max;
  logic out_agb_comp_leaf_max;
  logic out_aeb_comp_leaf_max;
  
  assign inA_comp_leaf_max = t_int_win;
  assign inB_comp_leaf_max = rddataA_leaf_max;
  altfp_compare comp_leaf_max (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_leaf_max ),
  .datab(inB_comp_leaf_max ),
  .aeb(out_aeb_comp_leaf_max),
	.agb(out_agb_comp_leaf_max) );


//------------------------------------------------------------------

  float_t t_leaf_max_s4, t_leaf_max_s4_n;
  assign t_leaf_max_s4_n = rddataA_leaf_max;
  ff_ar #($bits(float_t),'h0) t_leaf_max_s4_buf(.d(t_leaf_max_s4_n), .q(t_leaf_max_s4), .clk, .rst);

//------------------------------------------------------------------

  float_t t_best_s4, t_best_s4_n;
  assign t_best_s4_n = t_int_win;
  ff_ar #($bits(float_t),'h0) t_best_s4_buf(.d(t_best_s4_n), .q(t_best_s4), .clk, .rst);

  logic cur_hit_s4, cur_hit_s4_n;
  assign cur_hit_s4_n = listbuf_s3.hit_in | rddata_t_cur_buf.hit_cur ;
  ff_ar #(1,'h0) cur_hit_s4_buf(.d(cur_hit_s4_n), .q(cur_hit_s4), .clk, .rst);

  logic choose_t_in_s4, choose_t_in_s4_n;
  assign choose_t_in_s4_n = choose_t_in;
  ff_ar #(1,'h0) choose_t_in_s4_buf(.d(choose_t_in_s4_n), .q(choose_t_in_s4), .clk, .rst);


//------------------------------------------------------------------
  // Bari, triID (intersection) ports
  
  struct packed {
    bari_uv_t uv;
    triID_t triID;
  } wrdata_int_info, rddata_int_info;

  rayID_t raddr_int_info, waddr_int_info;
  logic wren_int_info;
  always_comb begin
    wrdata_int_info.uv = list_VSpipe_out.uv;
    wrdata_int_info.triID = list_VSpipe_out.triID;
  end
  assign waddr_int_info = list_VSpipe_out.ray_info.rayID;
  assign wren_int_info = list_VSpipe_valid_ds & choose_t_in_s4 ;

  
  bram_dual_rw_512x80 int_info_bram(
  //.aclr(rst),
  .wraddress(waddr_int_info),
  .rdaddress(raddr_int_info),
  .clock(clk),
  .data(wrdata_int_info),
  .wren(wren_int_info),
  .q(rddata_int_info) );


  assign waddr_t_cur = list_VSpipe_out.ray_info.rayID;
  assign wren_t_cur = list_VSpipe_valid_ds & (choose_t_in_s4 | (list_VSpipe_valid_ds & list_VSpipe_out.is_last & last_fifo_in.is_hit ) );
  always_comb begin
    if(list_VSpipe_valid_ds & list_VSpipe_out.is_last & last_fifo_in.is_hit) wrdata_t_cur = 'h0 ;
    else begin
      wrdata_t_cur.hit_cur = cur_hit_s4;
      wrdata_t_cur.t_cur = t_best_s4 ;
    end
  end
  
  

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
  always_comb begin
    last_fifo_in.ray_info = list_VSpipe_out.ray_info ;
    last_fifo_in.is_hit = cur_hit_s4 & (~out_agb_comp_leaf_max | out_aeb_comp_leaf_max) ; // Only if there is a hit LESS than t_max_leaf
    last_fifo_in.t = last_fifo_in.is_hit ? t_best_s4 : t_leaf_max_s4 ;
  end
  assign last_fifo_we = list_VSpipe_valid_ds & list_VSpipe_out.is_last;

  fifo #(.DEPTH(5), .WIDTH($bits(last_fifo_in)) ) last_fifo_inst(
    .clk, .rst,
    .data_in(last_fifo_in),
    .data_out(last_fifo_out),
    .full(last_fifo_full),
    .empty(last_fifo_empty),
    .re(last_fifo_re),
    .we(last_fifo_we),
    .num_left_in_fifo(num_left_in_last_fifo),
    .exists_in_fifo());
  
  


//------------------------------------------------------------------
  // Hit path (list_to_rs)
//------------------------------------------------------------------
  // pipe_valid_stall for int_info
  struct packed {
    rayID_t rayID;
    float_t t_int;
  } int_VSpipe_in, int_VSpipe_out;

  logic int_VSpipe_valid_us, int_VSpipe_stall_us;
  logic int_VSpipe_valid_ds, int_VSpipe_stall_ds;
  logic [1:0] num_left_in_int_fifo;
  logic hit_stall;

  always_comb begin
    int_VSpipe_in.rayID = last_fifo_out.ray_info.rayID;
    int_VSpipe_in.t_int = last_fifo_out.t;
  end
  assign int_VSpipe_valid_us = ~last_fifo_empty & last_fifo_out.is_hit & ~int_VSpipe_stall_us;
  assign int_VSpipe_stall_ds = list_to_rs_stall ; 
  assign hit_stall = ~last_fifo_empty & last_fifo_out.is_hit & int_VSpipe_stall_us ;

  pipe_valid_stall #(.WIDTH($bits(int_VSpipe_in)), .DEPTH(2)) pipe_inst(
    .clk, .rst,
    .us_valid(int_VSpipe_valid_us),
    .us_data(int_VSpipe_in),
    .us_stall(int_VSpipe_stall_us),
    .ds_valid(int_VSpipe_valid_ds),
    .ds_data(int_VSpipe_out),
    .ds_stall(int_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_int_fifo) );

// Reading from int_into_ram

  assign raddr_int_info = last_fifo_out.ray_info.rayID;

//------------------------------------------------------------------
  // fifo for hits
  list_to_rs_t int_fifo_in, int_fifo_out;

  logic int_fifo_full;
  logic int_fifo_empty;
  logic int_fifo_re;
  logic int_fifo_we;
  
  always_comb begin
    int_fifo_in.rayID = int_VSpipe_out.rayID;
    int_fifo_in.t_int = int_VSpipe_out.t_int;
    int_fifo_in.uv = rddata_int_info.uv;
    int_fifo_in.triID = rddata_int_info.triID;
  end
  assign int_fifo_we = int_VSpipe_valid_ds;
  assign int_fifo_re = ~int_fifo_empty & ~list_to_rs_stall;

  fifo #(.DEPTH(3), .WIDTH($bits(int_fifo_in)) ) int_fifo_inst(
    .clk, .rst,
    .data_in(int_fifo_in),
    .data_out(int_fifo_out),
    .full(int_fifo_full),
    .empty(int_fifo_empty),
    .re(int_fifo_re),
    .we(int_fifo_we),
    .num_left_in_fifo(num_left_in_int_fifo),
    .exists_in_fifo());    

//------------------------------------------------------------------

  // output logic for intersection 
  assign list_to_rs_valid = ~int_fifo_empty;
  assign list_to_rs_data = int_fifo_out;


//------------------------------------------------------------------
  // Buffer for misses and output logic
  logic miss_stall;
  
  logic valid_miss;

  list_to_ss_t to_ss, to_ss_n;
  logic to_ss_valid, to_ss_valid_n;
  
  assign valid_miss = ~last_fifo_empty & ~last_fifo_out.is_hit & (~to_ss_valid | ~list_to_ss_stall) ;
  
  always_comb begin
    if( valid_miss) begin
      to_ss_n.ray_info = last_fifo_out.ray_info;
      to_ss_n.t_max_leaf = last_fifo_out.t;
    end
    else to_ss_n = to_ss ;
  end
  assign to_ss_valid_n = (~to_ss_valid | ~list_to_ss_stall) ? (~last_fifo_empty & ~last_fifo_out.is_hit) : to_ss_valid ;
  
  ff_ar #($bits(list_to_ss_t),'h0) to_ss_buf(.d(to_ss_n), .q(to_ss), .clk, .rst);
  ff_ar #(1,'h0) to_ss_valid_buf(.d(to_ss_valid_n), .q(to_ss_valid), .clk, .rst);
 
  assign list_to_ss_valid = to_ss_valid ;
  assign list_to_ss_data = to_ss ;
  assign miss_stall = ~last_fifo_empty & ~last_fifo_out.is_hit & to_ss_valid & list_to_ss_stall ;

//------------------------------------------------------------------

  assign last_fifo_re = valid_miss | int_VSpipe_valid_us ;
  
  `ifndef SYNTH
    always @(*) begin
      assert(!(valid_miss & int_VSpipe_valid_us));
      assert(!(miss_stall & hit_stall));
    end
  `endif
  assign list_VSpipe_stall_ds = miss_stall | hit_stall ;

endmodule
