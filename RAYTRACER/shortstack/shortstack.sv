/*
  This unit is 2 memory strctures with surrounding port interfaces that support a few different operations

  ---------------------------------------------------
  Contents of shortstack indexed by rayID

  ss_row = [StackElement0, StackElement1, StackELement2, StackELement3 ]
  StackElement = [nodeID, t_max]; 
  
  Operations on the stack
    Push(new_SE): stack[ss_wptr] <= new_SE
    
    Pop         : 
    
  ----------------------------------------------------------------------

  Contents of restartnode indexed by rayID
  restartnode_row = [restartnode, t_max, t_max_scene] 
  operations on restartnode
    Write(new_restartnode) 
    Write(t_max_scene) 
    Read restartnode
    Read t_max_scene

  ----------------------------------------------------------------------

  ports of entire unit
    trav_to_ss_push (2 input ports)
      push(new_SE)
    
    trav_to_ss_update( 3 input ports) (2 from trav and 1 from sint)
      Write(new_restartnode)

    sceneint_to_ss (1 input port)
      write(t_max_scene)

    list_to_ss (1 input port) // Either a leaf node miss
        if(ElemCount !=0 ) {
            ss_to_tarb <= Pop; (t_max <= t_max, t_min <= t_max_leaf)
        }
        else {// ElemCount == 0
            if(t_max_leaf < t_max_scene) { // Need to restart
                ss_to_tarb <= Read restartnode (t_max <= t_max, t_min <= t_max_leaf)
            }
            else (t_max >= t_max_scene) { // Was a total miss.  t_max == t_max_scene will PROBABLY happen
               ss_to_shader <= Miss 
            }
        }
*/
typedef struct packed {
  nodeID_t nodeID;
  float_t t_max;
} ss_elem_t;

module shortstack_unit(

  input logic clk, rst,

  input logic trav0_to_ss_valid,
  input trav_to_ss_t trav0_to_ss_data,
  output logic trav0_to_ss_stall,


  input logic trav1_to_ss_valid,
  input trav_to_ss_t trav1_to_ss_data,
  output logic trav1_to_ss_stall,


  input logic sint_to_ss_valid,
  input sint_to_ss_t sint_to_ss_data,
  output logic sint_to_ss_stall,


  input logic list_to_ss_valid,
  input list_to_ss_t list_to_ss_data,
  output logic list_to_ss_stall,


  output logic ss_to_shader_valid,
  output ss_to_shader_t ss_to_shader_data,
  input logic ss_to_shader_stall,


  // This is for reading from the stack
  output logic ss_to_tarb_valid0,
  output tarb_t ss_to_tarb_data0,
  input logic ss_to_tarb_stall0,
  

  // this is for reading from the restart node
  output logic ss_to_tarb_valid1,
  output tarb_t ss_to_tarb_data1,
  input logic ss_to_tarb_stall1



  );

//------------------------------------------------------------------------
// Short Stack Path
//------------------------------------------------------------------------


// Short Stack Read fifos
  // 0 == trav0
  // 1 == trav1
  // 2 == list

  struct packed {
    ray_info_t ray_info; // This has wptr representing the readpointer (ss_wptr - 1)
    float_t t_min;
  } stack_read_fifo_in[3], stack_read_fifo_out[3];

  logic [2:0] stack_read_fifo_full;
  logic [2:0] stack_read_fifo_empty;
  logic [2:0] stack_read_fifo_re;
  logic [2:0] stack_read_fifo_we;
  always_comb begin
    stack_read_fifo_in[0].ray_info = trav0_to_ss_data.ray_info;
    stack_read_fifo_in[0].ray_info.ss_wptr = trav0_to_ss_data.ray_info.ss_wptr - 1'b1;
    stack_read_fifo_in[0].ray_info.ss_num = trav0_to_ss_data.ray_info.ss_num - 1'b1;
    stack_read_fifo_in[0].t_min =  trav0_to_ss_data.t_max;
    stack_read_fifo_in[1].ray_info = trav1_to_ss_data.ray_info;
    stack_read_fifo_in[1].ray_info.ss_wptr = trav1_to_ss_data.ray_info.ss_wptr - 1'b1;
    stack_read_fifo_in[1].ray_info.ss_num = trav1_to_ss_data.ray_info.ss_num - 1'b1;
    stack_read_fifo_in[1].t_min =  trav1_to_ss_data.t_max;
    stack_read_fifo_in[2].ray_info = list_to_ss_data.ray_info;
    stack_read_fifo_in[2].ray_info.ss_wptr = list_to_ss_data.ray_info.ss_wptr - 1'b1;
    stack_read_fifo_in[2].ray_info.ss_num = list_to_ss_data.ray_info.ss_num - 1'b1;
    stack_read_fifo_in[2].t_min = list_to_ss_data.t_max_leaf;
  end



  genvar i;
  generate
    for(i=0; i<3; i+=1) begin : stack_read_fifo
    fifo #(.DEPTH(3), .WIDTH($bits(stack_read_fifo_in[0])) ) stack_read_fifo_inst(
      .clk, .rst,
      .data_in(stack_read_fifo_in[i]),
      .data_out(stack_read_fifo_out[i]),
      .full(stack_read_fifo_full[i]),
      .empty(stack_read_fifo_empty[i]),
      .re(stack_read_fifo_re[i]),
      .we(stack_read_fifo_we[i]),
      .exists_in_fifo(),
      .num_left_in_fifo() );
    end : stack_read_fifo
  endgenerate

//------------------------------------------------------------------------
// Short Stack write fifos
  // 0 == trav0
  // 1 == trav1

  struct packed {
    rayID_t rayID;
    logic [1:0] ss_wptr;
    ss_elem_t elem;
  } stack_write_fifo_in[2], stack_write_fifo_out[2];

  // fifo to accumulate Definite misses and definite hits
  logic [1:0] stack_write_fifo_full;
  logic [1:0] stack_write_fifo_empty;
  logic [1:0] stack_write_fifo_re;
  logic [1:0] stack_write_fifo_we;
  always_comb begin
    stack_write_fifo_in[0].rayID = trav0_to_ss_data.ray_info.rayID;
    stack_write_fifo_in[0].ss_wptr = trav0_to_ss_data.ray_info.ss_wptr;
    stack_write_fifo_in[0].elem.nodeID =  trav0_to_ss_data.push_node_ID;
    stack_write_fifo_in[0].elem.t_max =  trav0_to_ss_data.t_max;
    stack_write_fifo_in[1].rayID = trav1_to_ss_data.ray_info.rayID;
    stack_write_fifo_in[1].ss_wptr = trav1_to_ss_data.ray_info.ss_wptr;
    stack_write_fifo_in[1].elem.nodeID =  trav1_to_ss_data.push_node_ID;
    stack_write_fifo_in[1].elem.t_max =  trav1_to_ss_data.t_max;
  end



  generate
    for(i=0; i<2; i+=1) begin : stack_write_fifo
    fifo #(.DEPTH(3), .WIDTH($bits(stack_write_fifo_in[0])) ) stack_write_fifo_inst(
      .clk, .rst,
      .data_in(stack_write_fifo_in[i]),
      .data_out(stack_write_fifo_out[i]),
      .full(stack_write_fifo_full[i]),
      .empty(stack_write_fifo_empty[i]),
      .re(stack_write_fifo_re[i]),
      .we(stack_write_fifo_we[i]),
      .exists_in_fifo(),
      .num_left_in_fifo() );
    end : stack_write_fifo
  endgenerate

  // VSpipe signals
  logic stack_VSpipe_valid_us, stack_VSpipe_stall_us;
  logic stack_VSpipe_valid_ds, stack_VSpipe_stall_ds;
  logic [1:0] num_left_in_stack_fifo;

//------------------------------------------------------------------------
// Stack instantiations

  logic [2:0] stack_rfifo_valid, stack_rfifo_choice;
  logic [1:0] stack_r_rrptr, stack_r_rrptr_n;
  assign stack_r_rrptr_n = (|stack_rfifo_valid) ? (stack_r_rrptr == 2'h2 ? 2'h0 : stack_r_rrptr + 1'b1) : stack_r_rrptr ;
  
  ff_ar #(2,2'b0) stack_r_rrptr_buf(.d(stack_r_rrptr_n), .q(stack_r_rrptr), .clk, .rst);
  
  assign stack_rfifo_valid = ~stack_read_fifo_empty & ~{3{stack_VSpipe_stall_us}};
  logic [1:0] stack_r_rrptr1, stack_r_rrptr2;
  always_comb begin
    unique case(stack_r_rrptr) 
      2'b00 : begin
        stack_r_rrptr1 = 2'b01;
        stack_r_rrptr2 = 2'b10;
      end
      2'b01 : begin
        stack_r_rrptr1 = 2'b10;
        stack_r_rrptr2 = 2'b00;
      end
      2'b10 : begin
        stack_r_rrptr1 = 2'b00;
        stack_r_rrptr2 = 2'b01;
      end
    endcase
  end
  
  
  always_comb begin
    stack_rfifo_choice = 'h0;
    stack_rfifo_choice[stack_r_rrptr] = stack_rfifo_valid[stack_r_rrptr];
    stack_rfifo_choice[stack_r_rrptr1] = stack_rfifo_valid[stack_r_rrptr1] & ~stack_rfifo_valid[stack_r_rrptr] ;
    stack_rfifo_choice[stack_r_rrptr2] = stack_rfifo_valid[stack_r_rrptr2] & ~stack_rfifo_valid[stack_r_rrptr] & ~stack_rfifo_valid[stack_r_rrptr1];
  end
  
  assign stack_read_fifo_re = stack_rfifo_choice ;

  logic [3:0] stack_read_valid;
  logic [1:0] stack_cur_rptr;
  rayID_t stack_cur_raddr;
  always_comb begin
    stack_cur_rptr = 'h0;
    stack_read_valid = 'h0;
    case(stack_rfifo_choice)
      3'b100: begin
        stack_cur_rptr = stack_read_fifo_out[2].ray_info.ss_wptr;
        stack_cur_raddr = stack_read_fifo_out[2].ray_info.rayID;
        stack_read_valid[stack_cur_rptr] = 1'b1 ;
      end
      3'b010: begin
        stack_cur_rptr = stack_read_fifo_out[1].ray_info.ss_wptr;
        stack_cur_raddr = stack_read_fifo_out[1].ray_info.rayID;
        stack_read_valid[stack_cur_rptr] = 1'b1 ;
      end
      3'b001: begin
        stack_cur_rptr = stack_read_fifo_out[0].ray_info.ss_wptr;
        stack_cur_raddr = stack_read_fifo_out[0].ray_info.rayID;
        stack_read_valid[stack_cur_rptr] = 1'b1 ; // SKETCHY (BUG FIX) Was always asserting stack_read_valid 
      end
      default : stack_cur_raddr = `DC ;
    endcase
  end
  logic stack_is_reading;
  assign stack_is_reading = |stack_rfifo_valid;

  logic stack_w_rrptr, stack_w_rrptr_n;
  
  logic [1:0] stack_wfifo_valid; // if not stalling and there is something in the write fifo
  logic [1:0] stack_wfifo_choice; // Both bits CAN be set here (resolves read/write conflict)
  logic stack_same_w0w1_dest;
  logic stack_same_rw0_dest;
  logic stack_same_rw1_dest;
  assign stack_same_w0w1_dest = (stack_write_fifo_out[0].ss_wptr == stack_write_fifo_out[1].ss_wptr);
  assign stack_same_rw0_dest = (stack_cur_rptr == stack_write_fifo_out[0].ss_wptr);
  assign stack_same_rw1_dest = (stack_cur_rptr == stack_write_fifo_out[1].ss_wptr);
  
  assign stack_w_rrptr_n = (|stack_wfifo_valid) ?  ~stack_w_rrptr : stack_w_rrptr ;
  ff_ar #(1,1'b0) stack_w_rrptr_buf(.d(stack_w_rrptr_n), .q(stack_w_rrptr), .clk, .rst);

  assign stack_wfifo_valid = ~stack_write_fifo_empty;
  
  always_comb begin
    stack_wfifo_choice = 'h0;
    stack_wfifo_choice[stack_w_rrptr] = stack_wfifo_valid[stack_w_rrptr];
    stack_wfifo_choice[~stack_w_rrptr] = stack_wfifo_valid[~stack_w_rrptr] & ~(stack_same_w0w1_dest & stack_same_rw0_dest & 
                                                                                stack_is_reading & stack_wfifo_valid[stack_w_rrptr]) ;
  end
/*
  always_comb begin
    if(stack_w_rrptr) begin
      stack_wfifo_choice[1] = stack_wfifo_valid[1];
      stack_wfifo_choice[0] = stack_wfifo_valid[0] & ~(stack_same_w0w1_dest & stack_same_rw0_dest & 
                                                       stack_is_reading & stack_wfifo_valid[1]) ;
    else begin
      stack_wfifo_choice[0] = stack_wfifo_valid[0];
      stack_wfifo_choice[1] = stack_wfifo_valid[1] & ~(stack_same_w0w1_dest & stack_same_rw0_dest & 
                                                       stack_is_reading & stack_wfifo_valid[0]) ;
    end
  end
*/
  assign stack_write_fifo_re = stack_wfifo_choice;
  // port A = 0, port B = 1

  logic stack_w0_port;
  logic stack_w1_port;
  logic [1:0][1:0] stack_wptr;
  always_comb begin
    if(stack_w_rrptr) begin
      stack_w1_port = (stack_is_reading & stack_same_rw1_dest) ? 1'b1 : 1'b0 ;
      stack_w0_port = (stack_is_reading & stack_same_rw0_dest)|(stack_wfifo_choice[1] & stack_same_w0w1_dest) ? 1'b1 : 1'b0 ;
   end
    else begin
      stack_w0_port = (stack_is_reading & stack_same_rw0_dest) ? 1'b1 : 1'b0 ;
      stack_w1_port = (stack_is_reading & stack_same_rw1_dest)|(stack_wfifo_choice[0] & stack_same_w0w1_dest) ? 1'b1 : 1'b0 ;
    end
  end
  always_comb begin
    stack_wptr[0] = stack_write_fifo_out[0].ss_wptr;
    stack_wptr[1] = stack_write_fifo_out[1].ss_wptr;
  end
  
  rayID_t addrA_stack[4], addrB_stack[4];
  ss_elem_t wrdataA_stack[4];
  ss_elem_t wrdataB_stack[4];
  logic [3:0] wrenA_stack, wrenB_stack;
  ss_elem_t rddataA_stack[4];
  ss_elem_t rddataB_stack[4];
 
  always_comb begin
    for(int i=0; i<4; i++) begin
      wrenA_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1] == i & ~stack_w1_port) | (stack_wfifo_choice[0] & stack_wptr[0] == i & ~stack_w0_port) ;
      wrenB_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1] == i & stack_w1_port) | (stack_wfifo_choice[0] & stack_wptr[0] == i & stack_w0_port) ;
      if(stack_w_rrptr) begin
        addrA_stack[i] = (stack_read_valid[i] & stack_cur_rptr==i) ? stack_cur_raddr : 
                          (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].rayID : 
                           (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].rayID : `DC ;
        wrdataA_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].elem :
                           (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].elem : `DC;
        addrB_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].rayID :
                         (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].rayID : `DC;
        wrdataB_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].elem :
                           (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].elem : `DC;
      end
      else begin
        addrA_stack[i] = (stack_read_valid[i] & stack_cur_rptr==i) ? stack_cur_raddr : 
                          (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].rayID : 
                           (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].rayID : `DC ;
        wrdataA_stack[i] = (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].elem :
                           (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].elem : `DC;
        addrB_stack[i] = (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].rayID :
                         (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].rayID : `DC;
        wrdataB_stack[i] = (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].elem :
                           (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].elem : `DC;
    
      end
    end
  end


  //genvar s;
  generate
    for(i=0; i<4; i++) begin : stacks
      bram_dual_2port_512x48 stack_bram(
      //.aclr(rst),
      .address_a(addrA_stack[i]),
      .address_b(addrB_stack[i]),
      .clock(clk),
      .data_a(wrdataA_stack[i]),
      .data_b(wrdataB_stack[i]),
      .wren_a(wrenA_stack[i]),
      .wren_b(wrenB_stack[i]),
      .q_a(rddataA_stack[i]),
      .q_b());
    end : stacks

  endgenerate


//------------------------------------------------------------------------
// VS Pipe for stack
  struct packed {
    ray_info_t ray_info;
    float_t t_min;
  } stack_VSpipe_in, stack_VSpipe_out;

  /*
  logic stack_VSpipe_valid_us, stack_VSpipe_stall_us;
    send_int_to_list(8,0,0,1,-2);
  logic stack_VSpipe_valid_ds, stack_VSpipe_stall_ds;
  logic [2:0] num_left_in_stack_fifo;
  */
  always_comb begin
    unique case(stack_rfifo_choice)
      3'b100 : stack_VSpipe_in = stack_read_fifo_out[2];
      3'b010 : stack_VSpipe_in = stack_read_fifo_out[1];
      3'b001 : stack_VSpipe_in = stack_read_fifo_out[0];
      3'b000 : stack_VSpipe_in = `DC;
    endcase
  end
  assign stack_VSpipe_valid_us = stack_is_reading;
  

  pipe_valid_stall #(.WIDTH($bits(stack_VSpipe_in)), .DEPTH(2)) stack_VSpipe_inst(
    .clk, .rst,
    .us_valid(stack_VSpipe_valid_us),
    .us_data(stack_VSpipe_in),
    .us_stall(stack_VSpipe_stall_us),
    .ds_valid(stack_VSpipe_valid_ds),
    .ds_data(stack_VSpipe_out),
    .ds_stall(stack_VSpipe_stall_ds),
    .num_left_in_fifo(num_left_in_stack_fifo) );


//------------------------------------------------------------------------
// Stack fifo
  struct packed {
    ray_info_t ray_info;
    float_t t_max;
    float_t t_min;
    nodeID_t nodeID;
  } stack_fifo_in, stack_fifo_out;

typedef struct packed {
  ray_info_t ray_info;
  nodeID_t nodeID;
  logic restnode_search; // set if still have not found restart node
  float_t t_max;
  float_t t_min;
} tarb_t ;

  logic stack_fifo_full;
  logic stack_fifo_empty;
  logic stack_fifo_re;
  logic stack_fifo_we;
  always_comb begin
    stack_fifo_in.ray_info = stack_VSpipe_out.ray_info;
    stack_fifo_in.t_max =  rddataA_stack[stack_VSpipe_out.ray_info.ss_wptr].t_max; // has been decreased
    stack_fifo_in.t_min =  stack_VSpipe_out.t_min; 
    stack_fifo_in.nodeID =  rddataA_stack[stack_VSpipe_out.ray_info.ss_wptr].nodeID; 
  end
  assign stack_fifo_we = stack_VSpipe_valid_ds;

  fifo #(.DEPTH(3), .WIDTH($bits(stack_fifo_in)) ) stack_fifo_inst(
    .clk, .rst,
    .data_in(stack_fifo_in),
    .data_out(stack_fifo_out),
    .full(stack_fifo_full),
    .empty(stack_fifo_empty),
    .re(stack_fifo_re),
    .we(stack_fifo_we),
    .exists_in_fifo(),
    .num_left_in_fifo(num_left_in_stack_fifo) );

  assign ss_to_tarb_valid0 = ~stack_fifo_empty;
  always_comb begin
    ss_to_tarb_data0.ray_info = stack_fifo_out.ray_info ;
    ss_to_tarb_data0.nodeID = stack_fifo_out.nodeID ;
    ss_to_tarb_data0.restnode_search = 1'b0 ;
    ss_to_tarb_data0.t_max = stack_fifo_out.t_max ;
    ss_to_tarb_data0.t_min = stack_fifo_out.t_min ;
  end
  
  assign stack_fifo_re = ss_to_tarb_valid0 & ~ss_to_tarb_stall0 ;
  assign stack_VSpipe_stall_ds = ss_to_tarb_stall0;


//------------------------------------------------------------------------------------------------------
// Restart Path
//------------------------------------------------------------------------------------------------------


// restart Read fifos
  // 0 == trav0
  // 1 == trav1
  // 2 == list

  struct packed {
    rayID_t rayID;
    logic is_shadow;
    float_t t_min;
  } rest_read_fifo_in[3], rest_read_fifo_out[3];

  logic [2:0] rest_read_fifo_full;
  logic [2:0] rest_read_fifo_empty;
  logic [2:0] rest_read_fifo_re;
  logic [2:0] rest_read_fifo_we;
  always_comb begin
    rest_read_fifo_in[0].rayID = trav0_to_ss_data.ray_info.rayID;
    rest_read_fifo_in[0].is_shadow = trav0_to_ss_data.ray_info.is_shadow;
    rest_read_fifo_in[0].t_min =  trav0_to_ss_data.t_max;
    rest_read_fifo_in[1].rayID = trav1_to_ss_data.ray_info.rayID;
    rest_read_fifo_in[1].is_shadow = trav1_to_ss_data.ray_info.is_shadow;
    rest_read_fifo_in[1].t_min =  trav1_to_ss_data.t_max;
    rest_read_fifo_in[2].rayID = list_to_ss_data.ray_info.rayID;
    rest_read_fifo_in[2].is_shadow = list_to_ss_data.ray_info.is_shadow;
    rest_read_fifo_in[2].t_min = list_to_ss_data.t_max_leaf;
  end



generate
  for(i=0; i<3; i+=1) begin : rest_read_fifo
  fifo #(.DEPTH(3), .WIDTH($bits(rest_read_fifo_in[0])) ) rest_read_fifo_inst(
    .clk, .rst,
    .data_in(rest_read_fifo_in[i]),
    .data_out(rest_read_fifo_out[i]),
    .full(rest_read_fifo_full[i]),
    .empty(rest_read_fifo_empty[i]),
    .re(rest_read_fifo_re[i]),
    .we(rest_read_fifo_we[i]),
    .exists_in_fifo(),
    .num_left_in_fifo() );
  end : rest_read_fifo
endgenerate

//------------------------------------------------------------------------
// rest write fifos
  // 0 == trav0
  // 1 == trav1
  // 2 == sint

  struct packed {
    rayID_t rayID;
    nodeID_t nodeID;
    logic nodeID_valid;
    float_t t_max_scene;
    logic t_max_scene_valid;
  } rest_write_fifo_in[3], rest_write_fifo_out[3];

  // fifo to accumulate Definite misses and definite hits
  logic [2:0] rest_write_fifo_full;
  logic [2:0] rest_write_fifo_empty;
  logic [2:0] rest_write_fifo_re;
  logic [2:0] rest_write_fifo_we;
  always_comb begin
    rest_write_fifo_in[0].rayID = trav0_to_ss_data.ray_info.rayID;
    rest_write_fifo_in[0].t_max_scene =  trav0_to_ss_data.t_max;
    rest_write_fifo_in[0].t_max_scene_valid = trav0_to_ss_data.update_maxscene_req | trav0_to_ss_data.update_restnode_req ;
    rest_write_fifo_in[0].nodeID =  trav0_to_ss_data.rest_node_ID;
    rest_write_fifo_in[0].nodeID_valid =  trav0_to_ss_data.update_restnode_req;

    rest_write_fifo_in[1].rayID = trav1_to_ss_data.ray_info.rayID;
    rest_write_fifo_in[1].t_max_scene =  trav1_to_ss_data.t_max;
    rest_write_fifo_in[1].t_max_scene_valid = trav1_to_ss_data.update_maxscene_req | trav1_to_ss_data.update_restnode_req;
    rest_write_fifo_in[1].nodeID =  trav1_to_ss_data.rest_node_ID;
    rest_write_fifo_in[1].nodeID_valid =  trav1_to_ss_data.update_restnode_req;
    
    rest_write_fifo_in[2].rayID = sint_to_ss_data.rayID;
    rest_write_fifo_in[2].t_max_scene =  sint_to_ss_data.t_max_scene;
    rest_write_fifo_in[2].t_max_scene_valid = 1'b1 ;
    rest_write_fifo_in[2].nodeID = 'h0 ;
    rest_write_fifo_in[2].nodeID_valid =  1'b1 ;
  
  end



  generate 
    for(i=0; i<3; i+=1) begin : rest_write_fifo
    fifo #(.DEPTH(3), .WIDTH($bits(rest_write_fifo_in[0])) ) rest_write_fifo_inst(
      .clk, .rst,
      .data_in(rest_write_fifo_in[i]),
      .data_out(rest_write_fifo_out[i]),
      .full(rest_write_fifo_full[i]),
      .empty(rest_write_fifo_empty[i]),
      .re(rest_write_fifo_re[i]),
      .we(rest_write_fifo_we[i]),
      .exists_in_fifo(),
      .num_left_in_fifo() );
    end : rest_write_fifo
  endgenerate

  // early declaration of vspipe signals
  logic rest_VSpipe_valid_us, rest_VSpipe_stall_us;
  logic rest_VSpipe_valid_ds, rest_VSpipe_stall_ds;
  logic [2:0] rest_min_num_left;

//------------------------------------------------------------------------
  // rest read arbitration logic
  logic [1:0] rest_r_rrptr, rest_r_rrptr_n;
  
  logic [2:0] rest_rfifo_valid, rest_rfifo_choice;
  assign rest_rfifo_valid = ~rest_read_fifo_empty & ~{3{rest_VSpipe_stall_us}};
   
  assign rest_r_rrptr_n = (|rest_rfifo_valid) ? (rest_r_rrptr == 2'h2 ? 2'h0 : rest_r_rrptr + 1'b1) : rest_r_rrptr ;
  ff_ar #(2,2'b0) rest_r_rrptr_buf(.d(rest_r_rrptr_n), .q(rest_r_rrptr), .clk, .rst);
 
  logic [1:0] rest_r_rrptr1, rest_r_rrptr2;
  always_comb begin
    unique case(rest_r_rrptr) 
      2'b00 : begin
        rest_r_rrptr1 = 2'b01;
        rest_r_rrptr2 = 2'b10;
      end
      2'b01 : begin
        rest_r_rrptr1 = 2'b10;
        rest_r_rrptr2 = 2'b00;
      end
      2'b10 : begin
        rest_r_rrptr1 = 2'b00;
        rest_r_rrptr2 = 2'b01;
      end
    endcase
  end
  
  always_comb begin
    rest_rfifo_choice = 'h0;
    rest_rfifo_choice[rest_r_rrptr] = rest_rfifo_valid[rest_r_rrptr];
    rest_rfifo_choice[rest_r_rrptr1] = rest_rfifo_valid[rest_r_rrptr1] & ~rest_rfifo_valid[rest_r_rrptr] ;
    rest_rfifo_choice[rest_r_rrptr2] = rest_rfifo_valid[rest_r_rrptr2] & ~rest_rfifo_valid[rest_r_rrptr] & ~rest_rfifo_valid[rest_r_rrptr1];
  end

  assign rest_read_fifo_re = rest_rfifo_choice;
  
  rayID_t rest_cur_raddr;
  float_t rest_cur_t_min;
  always_comb begin
    unique case(rest_rfifo_choice)
      3'b100: begin
        rest_cur_raddr = rest_read_fifo_out[2].rayID;
        rest_cur_t_min = rest_read_fifo_out[2].t_min;
      end
      3'b010: begin
        rest_cur_raddr = rest_read_fifo_out[1].rayID;
        rest_cur_t_min = rest_read_fifo_out[1].t_min;
      end
      3'b001: begin
        rest_cur_raddr = rest_read_fifo_out[0].rayID;
        rest_cur_t_min = rest_read_fifo_out[0].t_min;
      end
      3'b00 : begin
        rest_cur_raddr = 'h0;
        rest_cur_t_min = 'h0;
      end
    endcase
  end
  logic rest_is_reading;
  assign rest_is_reading = |rest_rfifo_valid;

  logic [2:0] rest_wfifo_valid; // if not stalling and there is something in the write fifo
  logic [2:0] rest_wfifo_choice; // Both bits CAN be set here (resolves read/write conflict)

  logic [1:0] rest_w_rrptr, rest_w_rrptr_n;
  assign rest_w_rrptr_n = (|rest_wfifo_choice) ? (rest_w_rrptr == 2'h2 ? 2'h0 : rest_w_rrptr + 1'b1) : rest_w_rrptr ;
  ff_ar #(2,2'b0) rest_w_rrptr_buf(.d(rest_w_rrptr_n), .q(rest_w_rrptr), .clk, .rst);
  
  logic [1:0] rest_w_rrptr1, rest_w_rrptr2;
  always_comb begin
    unique case(rest_w_rrptr) 
      2'b00 : begin
        rest_w_rrptr1 = 2'b01;
        rest_w_rrptr2 = 2'b10;
      end
      2'b01 : begin
        rest_w_rrptr1 = 2'b10;
        rest_w_rrptr2 = 2'b00;
      end
      2'b10 : begin
        rest_w_rrptr1 = 2'b00;
        rest_w_rrptr2 = 2'b01;
      end
    endcase
  end


  
  assign rest_wfifo_valid = ~rest_write_fifo_empty;
  
  always_comb begin
    rest_wfifo_choice = 'h0;
    rest_wfifo_choice[rest_w_rrptr] = rest_wfifo_valid[rest_w_rrptr];
    rest_wfifo_choice[rest_w_rrptr1] = rest_wfifo_valid[rest_w_rrptr1] & ~(rest_wfifo_valid[rest_w_rrptr] & rest_is_reading);
    rest_wfifo_choice[rest_w_rrptr2] = rest_wfifo_valid[rest_w_rrptr2] & ( rest_wfifo_valid[rest_w_rrptr] + rest_wfifo_valid[rest_w_rrptr1] + rest_is_reading <= 1);
  end

  assign rest_write_fifo_re = rest_wfifo_choice;

  logic [5:0] beA_rest, beB_rest;
  rayID_t addrA_rest, addrB_rest;
  ss_elem_t wrdataA_rest;
  ss_elem_t wrdataB_rest;
  logic wrenA_rest, wrenB_rest;
  ss_elem_t rddataA_rest;
  ss_elem_t rddataB_rest;

  always_comb begin
    case({rest_is_reading,rest_wfifo_choice})
      4'b1_100 : begin
				beA_rest = 6'b11_1111 ;
				beB_rest = { {2{rest_write_fifo_out[2].nodeID_valid}}, {4{rest_write_fifo_out[2].t_max_scene_valid}} } ;
        addrA_rest = rest_cur_raddr;
        addrB_rest = rest_write_fifo_out[2].rayID ; 
        wrdataA_rest = `DC ;
        wrdataB_rest = {rest_write_fifo_out[2].nodeID, rest_write_fifo_out[2].t_max_scene} ; 
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b1_010 : begin
				beA_rest = 6'b11_1111;
				beB_rest = { {2{rest_write_fifo_out[1].nodeID_valid}}, {4{rest_write_fifo_out[1].t_max_scene_valid}} } ;
        addrA_rest = rest_cur_raddr;
        addrB_rest = rest_write_fifo_out[1].rayID ; 
        wrdataA_rest = `DC ;
        wrdataB_rest = {rest_write_fifo_out[1].nodeID, rest_write_fifo_out[1].t_max_scene} ; 
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b1_001 : begin
				beA_rest = 6'b11_1111;
				beB_rest = { {2{rest_write_fifo_out[0].nodeID_valid}}, {4{rest_write_fifo_out[0].t_max_scene_valid}} } ;
        addrA_rest = rest_cur_raddr;
        addrB_rest = rest_write_fifo_out[0].rayID ; 
        wrdataA_rest = `DC ;
        wrdataB_rest = {rest_write_fifo_out[0].nodeID, rest_write_fifo_out[0].t_max_scene} ; 
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b1_000 : begin
				beA_rest = 6'b11_1111;
				beB_rest = 'h0 ;
        addrA_rest = rest_cur_raddr;
        addrB_rest = `DC;
        wrdataA_rest = `DC ;
        wrdataB_rest = `DC;
        wrenA_rest = 0;
        wrenB_rest = 0;
      end
      4'b0_100 : begin
				beA_rest = 6'b0;
				beB_rest = { {2{rest_write_fifo_out[2].nodeID_valid}}, {4{rest_write_fifo_out[2].t_max_scene_valid}} } ;
        addrA_rest = `DC;
        addrB_rest = rest_write_fifo_out[2].rayID ; 
        wrdataA_rest = `DC ;
        wrdataB_rest = {rest_write_fifo_out[2].nodeID, rest_write_fifo_out[2].t_max_scene} ; 
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b0_010 : begin
				beA_rest = 6'b0;
				beB_rest = { {2{rest_write_fifo_out[1].nodeID_valid}}, {4{rest_write_fifo_out[1].t_max_scene_valid}} } ;
        addrA_rest = `DC;
        addrB_rest = rest_write_fifo_out[1].rayID ; 
        wrdataA_rest = `DC ;
        wrdataB_rest = {rest_write_fifo_out[1].nodeID, rest_write_fifo_out[1].t_max_scene} ; 
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b0_001 : begin
				beA_rest = 6'b0;
				beB_rest = { {2{rest_write_fifo_out[0].nodeID_valid}}, {4{rest_write_fifo_out[0].t_max_scene_valid}} } ;
        addrA_rest = `DC;
        addrB_rest = rest_write_fifo_out[0].rayID ; 
        wrdataA_rest = `DC ;
        wrdataB_rest = {rest_write_fifo_out[0].nodeID, rest_write_fifo_out[0].t_max_scene} ; 
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b0_000 : begin
				beA_rest = 6'b0;
				beB_rest = 6'b0;
        addrA_rest = `DC;
        addrB_rest = `DC;
        wrdataA_rest = `DC ;
        wrdataB_rest = `DC;
        wrenA_rest = 0;
        wrenB_rest = 0;
      end     
      4'b0_110 : begin
				beA_rest = { {2{rest_write_fifo_out[1].nodeID_valid}}, {4{rest_write_fifo_out[1].t_max_scene_valid}} } ;
				beB_rest = { {2{rest_write_fifo_out[2].nodeID_valid}}, {4{rest_write_fifo_out[2].t_max_scene_valid}} } ;
        addrA_rest = rest_write_fifo_out[1].rayID ; 
        addrB_rest = rest_write_fifo_out[2].rayID ; 
        wrdataA_rest = {rest_write_fifo_out[1].nodeID, rest_write_fifo_out[1].t_max_scene } ; 
        wrdataB_rest = {rest_write_fifo_out[2].nodeID, rest_write_fifo_out[2].t_max_scene} ; 
        wrenA_rest = 1;
        wrenB_rest = 1;
      end
      4'b0_101 : begin
				beA_rest = { {2{rest_write_fifo_out[0].nodeID_valid}}, {4{rest_write_fifo_out[0].t_max_scene_valid}} } ;
				beB_rest = { {2{rest_write_fifo_out[2].nodeID_valid}}, {4{rest_write_fifo_out[2].t_max_scene_valid}} } ;
        addrA_rest = rest_write_fifo_out[0].rayID ; 
        addrB_rest = rest_write_fifo_out[2].rayID ; 
        wrdataA_rest = {rest_write_fifo_out[0].nodeID, rest_write_fifo_out[0].t_max_scene } ; 
        wrdataB_rest = {rest_write_fifo_out[2].nodeID, rest_write_fifo_out[2].t_max_scene} ; 
        wrenA_rest = 1;
        wrenB_rest = 1;
      end
      4'b0_011 : begin
				beA_rest = { {2{rest_write_fifo_out[0].nodeID_valid}}, {4{rest_write_fifo_out[0].t_max_scene_valid}} } ;
				beB_rest = { {2{rest_write_fifo_out[1].nodeID_valid}}, {4{rest_write_fifo_out[1].t_max_scene_valid}} } ;
        addrA_rest = rest_write_fifo_out[0].rayID ; 
        addrB_rest = rest_write_fifo_out[1].rayID ; 
        wrdataA_rest = {rest_write_fifo_out[0].nodeID, rest_write_fifo_out[0].t_max_scene } ; 
        wrdataB_rest = {rest_write_fifo_out[1].nodeID, rest_write_fifo_out[1].t_max_scene} ; 
        wrenA_rest = 1;
        wrenB_rest = 1;
      end
      default : begin
        beA_rest = 'h0;
        beB_rest = 'h0;
        addrA_rest = `DC ;
        addrB_rest = `DC ;
        wrdataA_rest = `DC ;
        wrdataB_rest = `DC ;
        wrenA_rest = 1'b0;
        wrenB_rest = 1'b0;
      end
    endcase
  end

  `ifndef SYNTH
    always @(posedge clk) 
      assert({rest_is_reading,rest_wfifo_choice} 
      //inside(1_000,1_001,1_010, 1_100, 0_000, 0_001, 0_010, 0_100, 0_110, 0_101, 0_011);
      inside{8,9,10, 12, 0, 1, 2, 4, 6, 5, 3 } );
  `endif

  bram_dual_2port_be_512x48 rest_bram(
  //.aclr(rst),
  .address_a(addrA_rest),
  .address_b(addrB_rest),
  .byteena_a(beA_rest),
	.byteena_b(beB_rest),
  .clock(clk),
  .data_a(wrdataA_rest),
  .data_b(wrdataB_rest),
  .wren_a(wrenA_rest),
  .wren_b(wrenB_rest),
  .q_a(rddataA_rest),
  .q_b());


//------------------------------------------------------------------------
  // Buffer for t_maxc cur and a compparison against the tmax of the scene
  float_t minbuf_in, minbuf_out, minbuf_s3;
  float_t maxscene_s3;
  nodeID_t restnode_s3;

  assign minbuf_in = rest_cur_t_min;
  buf_t3 #(.LAT(2), .WIDTH($bits(minbuf_in))) 
    minbuf_buf(.data_in(minbuf_in), .data_out(minbuf_out), .clk, .rst);

  ff_ar #($bits(float_t),'h0) minbuf_s3_reg(.d(minbuf_out), .q(minbuf_s3), .clk, .rst);
  ff_ar #($bits(float_t),'h0) maxscene_s3_reg(.d(rddataA_rest.t_max), .q(maxscene_s3), .clk, .rst);
  ff_ar #($bits(nodeID_t),'h0) restnode_s3_reg(.d(rddataA_rest.nodeID), .q(restnode_s3), .clk, .rst);

  float_t inA_comp_max_scene, inB_comp_max_scene;
  logic out_agb_comp_max_scene;
  logic out_aeb_comp_max_scene;
  assign inA_comp_max_scene = minbuf_out;
  assign inB_comp_max_scene = rddataA_rest.t_max;
  altfp_compare comp_max_scene (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_comp_max_scene ),
  .datab(inB_comp_max_scene ),
  .aeb(out_aeb_comp_max_scene),
	.agb(out_agb_comp_max_scene) );

  // if aeb | agb then a MISS
  // Else a NOTMISS
  logic miss_s3;
  logic notmiss_s3;
  assign miss_s3 = out_aeb_comp_max_scene | out_agb_comp_max_scene ;
  assign notmiss_s3 = ~miss_s3;

//------------------------------------------------------------------------
// VS Pipe for rest
  struct packed {
    rayID_t rayID;
    logic is_shadow;
  } rest_VSpipe_in, rest_VSpipe_out;

/*
  logic rest_VSpipe_valid_us, rest_VSpipe_stall_us;
  logic rest_VSpipe_valid_ds, rest_VSpipe_stall_ds;
  logic [2:0] rest_min_num_left;
*/  
  
  always_comb begin
    unique case(rest_rfifo_choice)
      3'b100 : begin 
        rest_VSpipe_in.rayID = rest_read_fifo_out[2].rayID;
        rest_VSpipe_in.is_shadow = rest_read_fifo_out[2].is_shadow;
      end
      3'b010 : begin 
        rest_VSpipe_in.rayID = rest_read_fifo_out[1].rayID;
        rest_VSpipe_in.is_shadow = rest_read_fifo_out[1].is_shadow;
      end
      3'b001 : begin 
        rest_VSpipe_in.rayID = rest_read_fifo_out[0].rayID;
        rest_VSpipe_in.is_shadow = rest_read_fifo_out[0].is_shadow;
      end
      3'b000 : rest_VSpipe_in = `DC;
    endcase
  end
  assign rest_VSpipe_valid_us = rest_is_reading;
  

  pipe_valid_stall #(.WIDTH($bits(rest_VSpipe_in)), .DEPTH(3)) rest_VSpipe_inst(
    .clk, .rst,
    .us_valid(rest_VSpipe_valid_us),
    .us_data(rest_VSpipe_in),
    .us_stall(rest_VSpipe_stall_us),
    .ds_valid(rest_VSpipe_valid_ds),
    .ds_data(rest_VSpipe_out),
    .ds_stall(rest_VSpipe_stall_ds),
    .num_left_in_fifo(rest_min_num_left) );

//------------------------------------------------------------------------
// notmiss fifo
  struct packed {
    rayID_t rayID;
    logic is_shadow;
    nodeID_t nodeID;
    float_t t_min;
    float_t t_max;
  } notmiss_fifo_in, notmiss_fifo_out;

  logic notmiss_fifo_full;
  logic notmiss_fifo_empty;
  logic notmiss_fifo_re;
  logic notmiss_fifo_we;
  logic [2:0] num_left_in_notmiss_fifo;
  always_comb begin
    notmiss_fifo_in.rayID= rest_VSpipe_out.rayID;
    notmiss_fifo_in.is_shadow = rest_VSpipe_out.is_shadow;
    notmiss_fifo_in.nodeID =  restnode_s3; 
    notmiss_fifo_in.t_min =  minbuf_s3; 
    notmiss_fifo_in.t_max =  maxscene_s3; 
  end
  assign notmiss_fifo_we = rest_VSpipe_valid_ds & notmiss_s3;

  fifo #(.DEPTH(4), .WIDTH($bits(notmiss_fifo_in)) ) notmiss_fifo_inst(
    .clk, .rst,
    .data_in(notmiss_fifo_in),
    .data_out(notmiss_fifo_out),
    .full(notmiss_fifo_full),
    .empty(notmiss_fifo_empty),
    .re(notmiss_fifo_re),
    .we(notmiss_fifo_we),
    .exists_in_fifo(),
    .num_left_in_fifo(num_left_in_notmiss_fifo) );

  assign notmiss_fifo_re = ss_to_tarb_valid1 & ~ss_to_tarb_stall1;
  assign ss_to_tarb_valid1 = ~notmiss_fifo_empty;
  always_comb begin
    ss_to_tarb_data1.ray_info = 'h0 ;
    ss_to_tarb_data1.ray_info.rayID = notmiss_fifo_out.rayID ;
    ss_to_tarb_data1.ray_info.is_shadow = notmiss_fifo_out.is_shadow;
    ss_to_tarb_data1.nodeID = notmiss_fifo_out.nodeID;
    ss_to_tarb_data1.restnode_search = 1'b0 ;
    ss_to_tarb_data1.t_max = notmiss_fifo_out.t_max ;
    ss_to_tarb_data1.t_min = notmiss_fifo_out.t_min ;
  end

//------------------------------------------------------------------------
// miss fifo
  ss_to_shader_t miss_fifo_in, miss_fifo_out;

  logic miss_fifo_full;
  logic miss_fifo_empty;
  logic miss_fifo_re;
  logic miss_fifo_we;
  logic [2:0] num_left_in_miss_fifo;
  always_comb begin
    miss_fifo_in.rayID = rest_VSpipe_out.rayID;
    miss_fifo_in.is_shadow = rest_VSpipe_out.is_shadow ; 
  end
  assign miss_fifo_we = rest_VSpipe_valid_ds & miss_s3;

  fifo #(.DEPTH(4), .WIDTH($bits(miss_fifo_in)) ) miss_fifo_inst(
    .clk, .rst,
    .data_in(miss_fifo_in),
    .data_out(miss_fifo_out),
    .full(miss_fifo_full),
    .empty(miss_fifo_empty),
    .re(miss_fifo_re),
    .we(miss_fifo_we),
    .exists_in_fifo(),
    .num_left_in_fifo(num_left_in_miss_fifo) );

  assign miss_fifo_re = ss_to_shader_valid & ~ss_to_shader_stall;
  assign ss_to_shader_valid = ~miss_fifo_empty;
  assign ss_to_shader_data = miss_fifo_out;
  assign rest_min_num_left = (num_left_in_miss_fifo > num_left_in_notmiss_fifo) ? num_left_in_notmiss_fifo : num_left_in_miss_fifo ;

  assign rest_VSpipe_stall_ds = ss_to_tarb_stall1 | ss_to_shader_stall ;

  // trav0
  assign rest_write_fifo_we[2] = sint_to_ss_valid & ~rest_write_fifo_full[2] ;
  assign sint_to_ss_stall = sint_to_ss_valid & rest_write_fifo_full[2] ;


  logic list_rest_read_valid;
  logic list_stack_read_valid;
  assign list_rest_read_valid = list_to_ss_valid & list_to_ss_data.ray_info.ss_num == 'h0 & ~rest_read_fifo_full[2] ;
  assign list_stack_read_valid = list_to_ss_valid & list_to_ss_data.ray_info.ss_num != 'h0 & ~stack_read_fifo_full[2] ;
  
  assign rest_read_fifo_we[2] = list_rest_read_valid ;
  assign stack_read_fifo_we[2] = list_stack_read_valid ;
  assign list_to_ss_stall = list_to_ss_valid & ~(list_rest_read_valid | list_stack_read_valid) ;


  // Case on (pop, update_maxscene, push, update_restnode)
  always_comb begin
    rest_read_fifo_we[0] = 1'b0;
    rest_write_fifo_we[0] = 1'b0;
    stack_read_fifo_we[0] = 1'b0;
    stack_write_fifo_we[0] = 1'b0;
    trav0_to_ss_stall = 1'b0 ;
    if(trav0_to_ss_valid) begin
      unique case({trav0_to_ss_data.pop_req,trav0_to_ss_data.update_maxscene_req,trav0_to_ss_data.push_req,trav0_to_ss_data.update_restnode_req})
        4'b1000 : begin
          if(trav0_to_ss_data.ray_info.ss_num=='h0) begin
            rest_read_fifo_we[0] =  ~rest_read_fifo_full[0];
            trav0_to_ss_stall =  rest_read_fifo_full[0] ;
          end
          else begin
            stack_read_fifo_we[0] =  ~stack_read_fifo_full[0];
            trav0_to_ss_stall =  stack_read_fifo_full[0];
          end
        end
        4'b0100 : begin
          rest_write_fifo_we[0] = ~rest_write_fifo_full[0];
          trav0_to_ss_stall = rest_write_fifo_full[0];
        end
        4'b0010 : begin
          stack_write_fifo_we[0] = ~stack_write_fifo_full[0]; 
          trav0_to_ss_stall = stack_write_fifo_full[0]; 
        end
        4'b0011 : begin
          stack_write_fifo_we[0] = ~stack_write_fifo_full[0] & ~rest_write_fifo_full[0];
          rest_write_fifo_we[0] = ~stack_write_fifo_full[0] & ~rest_write_fifo_full[0];
          trav0_to_ss_stall = stack_write_fifo_full[0] | rest_write_fifo_full[0] ;
        end
      endcase
    end

  end
  
  always_comb begin
    rest_read_fifo_we[1] = 1'b0;
    rest_write_fifo_we[1] = 1'b0;
    stack_read_fifo_we[1] = 1'b0;
    stack_write_fifo_we[1] = 1'b0;
    trav1_to_ss_stall = 1'b0 ;
    if(trav1_to_ss_valid) begin
      unique case({trav1_to_ss_data.pop_req,trav1_to_ss_data.update_maxscene_req,trav1_to_ss_data.push_req,trav1_to_ss_data.update_restnode_req})
        4'b1000 : begin
          if(trav1_to_ss_data.ray_info.ss_num=='h0) begin
            rest_read_fifo_we[1] =  ~rest_read_fifo_full[1];
            trav1_to_ss_stall =  rest_read_fifo_full[1] ;
          end
          else begin
            stack_read_fifo_we[1] =  ~stack_read_fifo_full[1];
            trav1_to_ss_stall =  stack_read_fifo_full[1];
          end
        end
        4'b0100 : begin
          rest_write_fifo_we[1] = ~rest_write_fifo_full[1];
          trav1_to_ss_stall = rest_write_fifo_full[1];
        end
        4'b0010 : begin
          stack_write_fifo_we[1] = ~stack_write_fifo_full[1]; 
          trav1_to_ss_stall = stack_write_fifo_full[1]; 
        end
        4'b0011 : begin
          stack_write_fifo_we[1] = ~stack_write_fifo_full[1] & ~rest_write_fifo_full[1];
          rest_write_fifo_we[1] = ~stack_write_fifo_full[1] & ~rest_write_fifo_full[1];
          trav1_to_ss_stall = stack_write_fifo_full[1] | rest_write_fifo_full[1] ;
        end
      endcase
    end

  end

endmodule
