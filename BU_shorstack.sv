/*
  This unit is 2 memory strctures with surrounding port interfaces that support a few different operations

  ---------------------------------------------------
  Contents of shortstack indexed by rayID

  ss_row = [StackElement0, StackElement1, StackELement2, StackELement3 ]
  StackElement = [nodeID, t_max]; // TODO seems we can infer t_min and this do not need to store
                                         // t_min = t_max(leaf node it just traversed)

  
  Operations on the stack
    Push(new_SE): stack[ss_wptr] <= new_SE
    
    Pop         : TODO
    
  ----------------------------------------------------------------------

  Contents of restartnode indexed by rayID (TODO might just want to seperate t_max_scene into different mem structure)
  restartnode_row = [restartnode, t_max, t_min, t_max_scene]  // TODO dont think we need to store t_min

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
            else (t_max >= t_max_scene) { // Was a total miss. TODO t_max == t_max_scene will PROBABLY happen
               ss_to_shader <= Miss 
            }
        }
*/
typedef struct packed {
  nodeID_t nodeID;
  float_t t_max;
} ss_elem_t;

module shortstack(

  input logic trav0_to_ss_valid,
  input trav_to_ss_t trav0_to_ss_data,
  output logic trav0_to_ss_stall,


  input logic trav1_to_ss_valid,
  input trav_to_ss_t trav1_to_ss_data,
  output logic trav1_to_ss_stall,


  input logic sint_to_ss_valid,
  input sint_to_ss_t si_to_ss_data,
  output logic sint_to_ss_stall,


  input logic list_to_ss_valid,
  input list_to_ss_t list_to_ss_data,
  output logic list_to_ss_stall,


  output logic ss_to_shader_valid,
  output ss_to_shader_t ss_to_shader_data,
  input logic ss_to_shader_stall,


  // This is for reading from the stack
  output logic ss_to_tarb_valid0,
  output tarb_t_t ss_to_tarb_data0,
  input logic ss_to_tarb_stall0
  

  // this is for reading from the restart node
  output logic ss_to_tarb_valid1,
  output tarb_t_t ss_to_tarb_data1,
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
    stack_read_fifo_in[2].t_min = list_to_ss_data.t_max;
  end

  assign stack_read_fifo_we = ;


genvar i;
generate begin
  for(i=0; i<3; i+=1) begin
  fifo #(.DEPTH(3), .WIDTH($bits(stack_read_fifo_in)) ) stack_read_fifo_inst(
    .clk, .rst,
    .data_in(stack_read_fifo_in[i]),
    .data_out(stack_read_fifo_out[i]),
    .full(stack_read_fifo_full[i]),
    .empty(stack_read_fifo_empty[i]),
    .re(stack_read_fifo_re[i]),
    .we(stack_read_fifo_we[i]),
    .exists_in_fifo(),
    .num_left_in_fifo(),
    .exists_in_fifo());
  end
end

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

  assign stack_write_fifo_re = ;


genvar i;
generate begin
  for(i=0; i<2; i+=1) begin
  fifo #(.DEPTH(3), .WIDTH($bits(stack_write_fifo_in)) ) stack_write_fifo_inst(
    .clk, .rst,
    .data_in(stack_write_fifo_in[i]),
    .data_out(stack_write_fifo_out[i]),
    .full(stack_write_fifo_full[i]),
    .empty(stack_write_fifo_empty[i]),
    .re(stack_write_fifo_re[i]),
    .we(stack_write_fifo_we[i]),
    .exists_in_fifo(),
    .num_left_in_fifo() );
  end
endgenerate


//------------------------------------------------------------------------
// Stack instantiations

  logic [2:0] stack_rfifo_valid, stack_rfifo_choice;
  logic [1:0] stack_r_rrptr, stack_r_rrptr_n;
  assign stack_r_rrptr_n = (|stack_rfifo_valid) ? (stack_r_rrptr == 2'h2 ? 2''h0 : stack_r_rrptr + 1'b1) : stack_r_rrptr ;
  
  
  
  ff_ar #(2,2'b0) stack_r_rrptr_buf(.d(stack_r_rrptr_n), .q(stack_r_rrptr), .clk, .rst);
  
  assign stack_rfifo_valid = ~stack_read_fifo_empty & {3{stack_VSpipe_stall_us}};
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
     3'b010: begin
        stack_cur_rptr = stack_read_fifo_out[1].ray_info.ss_wptr;
        stack_cur_raddr = stack_read_fifo_out[1].ray_info.rayID;
     3'b001: begin
        stack_cur_rptr = stack_read_fifo_out[0].ray_info.ss_wptr;
        stack_cur_raddr = stack_read_fifo_out[0].ray_info.rayID;
      end
    endcase
    stack_read_valid[stack_cur_rptr] = 1'b1 ;
  end
  logic stack_is_reading;
  assign stack_is_reading = |stack_rfifo_valid;

  logic stack_w_rrptr, stack_w_rrptr_n;
  assign stack_w_rrptr_n = ( ) ?  ~stack_w_rrptr : stacK_w_rrptr ;
  ff_ar #(1,1'b0) stack_w_rrptr_buf(.d(stack_w_rrptr_n), .q(stack_w_rrptr), .clk, .rst);
  
  logic [1:0] stack_wfifo_valid; // if not stalling and there is something in the write fifo
  logic [1:0] stack_wfifo_choice; // Both bits CAN be set here (resolves read/write conflict)
  logic stack_same_w0w1_dest;
  logic stack_same_rw0_dest;
  logic stack_same_rw1_dest;
  assign stack_same_w0w1_dest = (stack_write_fifo_out[0].ss_wptr == stack_write_fifo_out[1].ss_wptr);
  assign stack_same_rw0_dest = (stack_cur_rptr == stack_write_fifo_out[0].ss_wptr);
  assign stack_same_rw1_dest = (stack_cur_rptr == stack_write_fifo_out[1].ss_wptr);

  assign stack_wfifo_valid = ~stack_write_fifo_empty;
  
  
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

  assign stack_write_fifo_re = stack_wfifo_choice;
  // port A = 0, port B = 1

  logic stack_w0_port;
  logic stack_w1_port;
  logic [1:0][1:0] stack_wptr;
  rayID_t 
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
  
  
  rayID_t addrA_stack[4], addrB_stack[4];
  ss_elem_t wrdataA_stack[4];
  ss_elem_t wrdataB_stack[4];
  logic [3:0] wrenA_stack, wrenB_stack;
  ss_elem_t rddataA_stack[4];
  ss_elem_t rddataB_stack[4];
 
  always_comb begin
    for(int i=0; i<3; i++) begin
      wrenA_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1] == i & ~stack_w1_port) | (stack_wfifo_choic[0] & stack_wptr[0] == i & ~stack_w0_port) ;
      wrenB_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1] == i & stack_w1_port) | (stack_wfifo_choic[0] & stack_wptr[0] == i & stack_w0_port) ;
      if(stack_w_rrptr) begin
        addrA_stack[i] = (stack_read_valid[i] & cur_rptr==i) ? stack_cur_raddr : 
                         ( (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].rayID : 
                           (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].rayID) : `DC ;
        wrdataA_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].elem :
                           (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].elem : `DC;
        addrB_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].rayID :
                         (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].rayID : `DC;
        wrdataB_stack[i] = (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].elem :
                           (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].elem : `DC;
      end
      else begin
        addrA_stack[i] = (stack_read_valid[i] & cur_rptr==i) ? stack_cur_raddr : 
                         ( (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].rayID : 
                           (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].rayID) : `DC ;
        wrdataA_stack[i] = (stack_wfifo_choice[0] & stack_wptr[0]==i & ~stack_w0_port) ? stack_write_fifo_out[0].elem :
                           (stack_wfifo_choice[1] & stack_wptr[1]==i & ~stack_w1_port) ? stack_write_fifo_out[1].elem : `DC;
        addrB_stack[i] = (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].rayID :
                         (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].rayID : `DC;
        wrdataB_stack[i] = (stack_wfifo_choice[0] & stack_wptr[0]==i & stack_w0_port) ? stack_write_fifo_out[0].elem :
                           (stack_wfifo_choice[1] & stack_wptr[1]==i & stack_w1_port) ? stack_write_fifo_out[1].elem : `DC;
    
      end
    end
  end
  


  genvar s;
  generate
    for(s=0; s<4; s++) begin
      bram_dual_2port_512x stack_bram(
      .aclr(rst[i]),
      .address_a(addrA_stack[i]),
      .address_b(addrB_stack[i]),
      .clock(clk[i]),
      .data_a(wrdataA_stack[i]),
      .data_b(wrdataB_stack[i]),
      .wren_a(wrenA_stack[i]),
      .wren_b(wrenB_stack[i]),
      .q_a(rddataA_stack[i]),
      .q_b());
    end

  endgenerate



//------------------------------------------------------------------------
// VS Pipe for stack
  struct packed {
    ray_info_t ray_info;
    float_t t_min;
  } stack_VSpipe_in, stack_VSpipe_out;

  logic stack_VSpipe_valid_us, stack_VSpipe_stall_us;
  logic stack_VSpipe_valid_ds, stack_VSpipe_stall_ds;
  logic [2:0] num_left_in_stack_fifo;
  
  always_comb begin
    unique case(stack_rfifo_choice);
      3'b100 : stack_VS_pipe_in = stack_read_fifo_out[2];
      3'b010 : stack_VS_pipe_in = stack_read_fifo_out[1];
      3'b001 : stack_VS_pipe_in = stack_read_fifo_out[0];
      3'b000 : stack_VS_pipe_in = `DC;
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
    .exists_in_fifo(),
    .num_left_in_fifo(num_left_in_stack_fifo) );

//------------------------------------------------------------------------
// Stack fifo
  struct packed {
    ray_info_t ray_info;
    float_t t_max;
    float_t t_min;
    nodeID_t nodeID;
  } stack_fifo_in, stack_fifo_out;

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

  assign ss_to_tarb0_valid = ~stack_fifo_empty;
  assign ss_to_tarb0_data = stack_fifo_out;
  assign stack_fifo_re = ss_to_tarb0_valid & ~ss_to_tarb0_stall ;



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
  } maxscene_read_fifo_in[3], maxscene_read_fifo_out[3];

  logic [2:0] maxscene_read_fifo_full;
  logic [2:0] maxscene_read_fifo_empty;
  logic [2:0] maxscene_read_fifo_re;
  logic [2:0] maxscene_read_fifo_we;
  always_comb begin
    maxscene_read_fifo_in[0].rayID = trav0_to_ss_data.rayID;
    maxscene_read_fifo_in[0].is_shadow = trav0_to_ss_data.is_shadow;
    maxscene_read_fifo_in[0].t_min =  trav0_to_ss_data.t_max;
    maxscene_read_fifo_in[1].rayID = trav1_to_ss_data.rayID;
    maxscene_read_fifo_in[1].is_shadow = trav1_to_ss_data.is_shadow;
    maxscene_read_fifo_in[1].t_min =  trav1_to_ss_data.t_max;
    maxscene_read_fifo_in[2].rayID = list_to_ss_data.rayID;
    maxscene_read_fifo_in[2].is_shadow = list_to_ss_data.is_shadow;
    maxscene_read_fifo_in[2].t_min = list_to_ss_data.t_max;
  end

  assign maxscene_read_fifo_we = ;


genvar i;
generate begin
  for(i=0; i<3; i+=1) begin
  fifo #(.DEPTH(3), .WIDTH($bits(maxscene_read_fifo_in)) ) maxscene_read_fifo_inst(
    .clk, .rst,
    .data_in(maxscene_read_fifo_in[i]),
    .data_out(maxscene_read_fifo_out[i]),
    .full(maxscene_read_fifo_full[i]),
    .empty(maxscene_read_fifo_empty[i]),
    .re(maxscene_read_fifo_re[i]),
    .we(maxscene_read_fifo_we[i]),
    .exists_in_fifo(),
    .num_left_in_fifo() );
  end
end

//------------------------------------------------------------------------
// maxscene write fifos
  // 0 == trav0
  // 1 == trav1
  // 2 == sint

  struct packed {
    rayID_t rayID;
    float_t t_max_scene;
  } maxscene_write_fifo_in[3], maxscene_write_fifo_out[3];

  // fifo to accumulate Definite misses and definite hits
  logic [2:0] maxscene_write_fifo_full;
  logic [2:0] maxscene_write_fifo_empty;
  logic [2:0] maxscene_write_fifo_re;
  logic [2:0] maxscene_write_fifo_we;
  always_comb begin
    maxscene_write_fifo_in[0].rayID = trav0_to_ss_data.ray_info.rayID;
    maxscene_write_fifo_in[0].t_max_scene =  trav0_to_ss_data.t_max;
    maxscene_write_fifo_in[1].rayID = trav1_to_ss_data.ray_info.rayID;
    maxscene_write_fifo_in[1].t_max_scene =  trav1_to_ss_data.t_max;
    maxscene_write_fifo_in[2].rayID = sint_to_ss_data.rayID;
    maxscene_write_fifo_in[2].t_max_scene =  sint_to_ss_data.t_max.t_max_scene;
  end

  assign maxscene_write_fifo_re = ;


genvar i;
generate begin
  for(i=0; i<2; i+=1) begin
  fifo #(.DEPTH(3), .WIDTH($bits(maxscene_write_fifo_in)) ) maxscene_write_fifo_inst(
    .clk, .rst,
    .data_in(maxscene_write_fifo_in[i]),
    .data_out(maxscene_write_fifo_out[i]),
    .full(maxscene_write_fifo_full[i]),
    .empty(maxscene_write_fifo_empty[i]),
    .re(maxscene_write_fifo_re[i]),
    .we(maxscene_write_fifo_we[i]),
    .exists_in_fifo(),
    .num_left_in_fifo() );
  end
endgenerate


//------------------------------------------------------------------------
  // maxscene read arbitration logic
  logic [1:0] maxscene_r_rrptr, maxscene_r_rrptr_n;
  assign maxscene_r_rrptr_n = (|maxscene_rfifo_valid) ? (maxscene_r_rrptr == 2'h2 ? 2''h0 : maxscene_r_rrptr + 1'b1) : maxscene_r_rrptr ;
  ff_ar #(2,2'b0) maxscene_r_rrptr_buf(.d(maxscene_r_rrptr_n), .q(maxscene_r_rrptr), .clk, .rst);
  
  logic [2:0] maxscene_rfifo_valid, maxscene_rfifo_choice;
  assign maxscene_rfifo_valid = ~maxscene_read_fifo_empty & {3{maxscene_VSpipe_stall_us}};
  
  logic [1:0] maxscene_r_rrptr1, maxscene_r_rrptr2;
  always_comb begin
    unique case(maxscene_r_rrptr) 
      2'b00 : begin
        maxscene_r_rrptr1 = 2'b01;
        maxscene_r_rrptr2 = 2'b10;
      end
      2'b01 : begin
        maxscene_r_rrptr1 = 2'b10;
        maxscene_r_rrptr2 = 2'b00;
      end
      2'b10 : begin
        maxscene_r_rrptr1 = 2'b00;
        maxscene_r_rrptr2 = 2'b01;
      end
    endcase
  end
  
  always_comb begin
    maxscene_rfifo_choice = 'h0;
    maxscene_rfifo_choice[maxscene_r_rrptr] = maxscene_rfifo_valid[maxscene_r_rrptr];
    maxscene_rfifo_choice[maxscene_r_rrptr1] = maxscene_rfifo_valid[maxscene_r_rrptr1] & ~maxscene_rfifo_valid[maxscene_r_rrptr] ;
    maxscene_rfifo_choice[maxscene_r_rrptr2] = maxscene_rfifo_valid[maxscene_r_rrptr2] & ~maxscene_rfifo_valid[maxscene_r_rrptr] & ~maxscene_rfifo_valid[maxscene_r_rrptr1];
  end

  
  rayID_t maxscene_cur_raddr;
  float_t maxscene_cur_t_min;
  always_comb begin
    maxscene_cur_rptr = 'h0;
    maxscene_read_valid = 'h0;
    case(maxscene_rfifo_choice)
      3'b100: begin
        maxscene_cur_raddr = maxscene_read_fifo_out[2].rayID;
        maxscene_cur_t_min = maxscene_read_fifo_out[2].t_min;
      3'b010: begin
        maxscene_cur_raddr = maxscene_read_fifo_out[1].rayID;
        maxscene_cur_t_min = maxscene_read_fifo_out[1].t_min;
      3'b001: begin
        maxscene_cur_raddr = maxscene_read_fifo_out[0].rayID;
        maxscene_cur_t_min = maxscene_read_fifo_out[0].t_min;
      end
    endcase
  end
  logic maxscene_is_reading;
  assign maxscene_is_reading = |maxscene_rfifo_valid;


  logic [1:0] maxscene_w_rrptr, maxscene_w_rrptr_n;
  assign maxscene_w_rrptr_n = (|maxscene_wfifo_choice) ? (maxscene_w_rrptr == 2'h2 ? 2''h0 : maxscene_w_rrptr + 1'b1) : maxscene_w_rrptr ;
  ff_ar #(2,2'b0) maxscene_w_rrptr_buf(.d(maxscene_w_rrptr_n), .q(maxscene_w_rrptr), .clk, .rst);
  
  logic [1:0] maxscene_w_rrptr1, maxscene_w_rrptr2;
  always_comb begin
    unique case(maxscene_w_rrptr) 
      2'b00 : begin
        maxscene_w_rrptr1 = 2'b01;
        maxscene_w_rrptr2 = 2'b10;
      end
      2'b01 : begin
        maxscene_w_rrptr1 = 2'b10;
        maxscene_w_rrptr2 = 2'b00;
      end
      2'b10 : begin
        maxscene_w_rrptr1 = 2'b00;
        maxscene_w_rrptr2 = 2'b01;
      end
    endcase
  end


  logic [2:0] maxscene_wfifo_valid; // if not stalling and there is something in the write fifo
  logic [2:0] maxscene_wfifo_choice; // Both bits CAN be set here (resolves read/write conflict)
  
  assign maxscene_wfifo_valid = ~maxscene_write_fifo_empty;
  
  always_comb begin
    maxscene_wfifo_choice[maxscene_w_rrptr] = maxscene_wfifo_valid[maxscene_w_rrptr];
    maxscene_wfifo_choice[maxscene_w_rrptr1] = maxscene_wfifo_valid[maxscene_w_rrptr1] & ~(maxscene_wfifo_valid[maxscene_w_rrptr] & maxscene_is_reading);
    maxscene_wfifo_choice[maxscene_w_rrptr2] = maxscene_wfifo_valid[maxscene_w_rrptr2] & ( maxscene_wfifo_valid[maxscene_w_rrptr] + maxscene_wfifo_valid[maxscene_w_rrptr1] + maxscene_is_reading <= 1);
  end

  assign maxscene_write_fifo_re = maxscene_wfifo_choice;

  rayID_t addrA_maxscene, addrB_maxscene;
  float_t wrdataA_maxscene;
  float_t wrdataB_maxscene;
  logic wrenA_maxscene, wrenB_maxscene;
  float_t rddataA_maxscene;
  float_t rddataB_maxscene;

  
  always_comb begin
    unique case({maxscene_is_reading,maxscene_wfifo_choice})
      4'b1_100 : begin
        addrA_maxscene = maxscene_cur_raddr;
        addrB_maxscene = maxscene_write_fifo_out[2].rayID;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = maxscene_write_fifo_out[2].t_max_scene;
        wrenA_maxscene = 0;
        wrenB_maxscene = 1;
      end
      4'b1_010 : begin
        addrA_maxscene = maxscene_cur_raddr;
        addrB_maxscene = maxscene_write_fifo_out[1].rayID;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = maxscene_write_fifo_out[1].t_max_scene;
        wrenA_maxscene = 0;
        wrenB_maxscene = 1;
      end
      4'b1_001 : begin
        addrA_maxscene = maxscene_cur_raddr;
        addrB_maxscene = maxscene_write_fifo_out[0].rayID;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = maxscene_write_fifo_out[0].t_max_scene;
        wrenA_maxscene = 0;
        wrenB_maxscene = 1;
      end
      4'b1_000 : begin
        addrA_maxscene = maxscene_cur_raddr;
        addrB_maxscene = `DC;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = `DC;
        wrenA_maxscene = 0;
        wrenB_maxscene = 0;
      end
      4'b0_100 : begin
        addrA_maxscene = `DC;
        addrB_maxscene = maxscene_write_fifo_out[2].rayID;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = maxscene_write_fifo_out[2].t_max_scene;
        wrenA_maxscene = 0;
        wrenB_maxscene = 1;
      end
      4'b0_010 : begin
        addrA_maxscene = `DC;
        addrB_maxscene = maxscene_write_fifo_out[1].rayID;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = maxscene_write_fifo_out[1].t_max_scene;
        wrenA_maxscene = 0;
        wrenB_maxscene = 1;
      end
      4'b0_001 : begin
        addrA_maxscene = `DC;
        addrB_maxscene = maxscene_write_fifo_out[0].rayID;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = maxscene_write_fifo_out[0].t_max_scene;
        wrenA_maxscene = 0;
        wrenB_maxscene = 1;
      end
      4'b0_000 : begin
        addrA_maxscene = `DC;
        addrB_maxscene = `DC;
        wrdataA_maxscene = `DC ;
        wrdataB_maxscene = `DC;
        wrenA_maxscene = 0;
        wrenB_maxscene = 0;
      end     
      4'b0_110 : begin
        addrA_maxscene = maxscene_write_fifo_out[1].rayID;
        addrB_maxscene = maxscene_write_fifo_out[2].rayID;
        wrdataA_maxscene = maxscene_write_fifo_out[1].t_max_scene ;
        wrdataB_maxscene = maxscene_write_fifo_out[2].t_max_scene;
        wrenA_maxscene = 1;
        wrenB_maxscene = 1;
      end
      4'b0_101 : begin
        addrA_maxscene = maxscene_write_fifo_out[0].rayID;
        addrB_maxscene = maxscene_write_fifo_out[2].rayID;
        wrdataA_maxscene = maxscene_write_fifo_out[0].t_max_scene ;
        wrdataB_maxscene = maxscene_write_fifo_out[2].t_max_scene;
        wrenA_maxscene = 1;
        wrenB_maxscene = 1;
      end
      4'b0_011 : begin
        addrA_maxscene = maxscene_write_fifo_out[0].rayID;
        addrB_maxscene = maxscene_write_fifo_out[1].rayID;
        wrdataA_maxscene = maxscene_write_fifo_out[0].t_max_scene ;
        wrdataB_maxscene = maxscene_write_fifo_out[1].t_max_scene;
        wrenA_maxscene = 1;
        wrenB_maxscene = 1;
      end
    endcase
  end

  bram_dual_2port_512x32 maxscene_bram(
  .aclr(rst),
  .address_a(addrA_maxscene),
  .address_b(addrB_maxscene),
  .clock(clk),
  .data_a(wrdataA_maxscene),
  .data_b(wrdataB_maxscene),
  .wren_a(wrenA_maxscene),
  .wren_b(wrenB_maxscene),
  .q_a(rddataA_maxscene),
  .q_b());


//------------------------------------------------------------------------
  // Buffer for t_maxc cur and a compparison against the tmax of the scene
  float_t minbuf_in, minbuf_out, minbuf_s3;
  float_t maxscene_s3;

  assign minbuf_in = rest_cur_t_min;
  buf_t3 #(.LAT(2), .WIDTH($bits(minbuf_in))) 
    minbuf_buf(.data_in(minbuf_in), .data_out(minbuf_out), .clk, .rst);

  ff_ar #($bits(float_t),'h0) minbuf_s3_reg(.d(minbuf_out), .q(minbuf_s3), .clk, .rst);
  ff_ar #($bits(float_t),'h0) maxscene_s3_reg(.d(rddata_max_scene), .q(maxscene_s3), .clk, .rst);

  float_t inA_comp_max_scene, inB_comp_max_scene;
  logic out_agb_comp_max_scene;
  logic out_aeb_comp_max_scene;
  assign inA_comp_max_scene = minbuf_out;
  assign inB_comp_max_scene = rddata_max_scene;
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

  logic rest_VSpipe_valid_us, rest_VSpipe_stall_us;
  logic rest_VSpipe_valid_ds, rest_VSpipe_stall_ds;
  logic [2:0] rest_min_num_left;
  
  always_comb begin
    unique case(rest_rfifo_choice);
      3'b100 : begin 
        rest_VS_pipe_in.rayID = rest_read_fifo_out[2].rayID;
        rest_VS_pipe_in.is_shadow = rest_read_fifo_out[2].is_shadow;
      end
      3'b010 : begin 
        rest_VS_pipe_in.rayID = rest_read_fifo_out[1].rayID;
        rest_VS_pipe_in.is_shadow = rest_read_fifo_out[1].is_shadow;
      end
      3'b001 : begin 
        rest_VS_pipe_in.rayID = rest_read_fifo_out[0].rayID;
        rest_VS_pipe_in.is_shadow = rest_read_fifo_out[0].is_shadow;
      end
      3'b000 : rest_VS_pipe_in = `DC;
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
    float_t t_min;
    float_t t_max;
  } notmiss_fifo_in, notmiss_fifo_out;

  logic notmiss_fifo_full;
  logic notmiss_fifo_empty;
  logic notmiss_fifo_re;
  logic notmiss_fifo_we;
  always_comb begin
    notmiss_fifo_in.rayID= rest_VSpipe_out.rayID;
    notmiss_fifo_in.is_shadow = rest_VSpipe_out.is_shadow;
    notmiss_fifo_in.t_min =  minbuf_s3; 
    notmiss_fifo_in.t_max =  maxscene_s3; 
  end
  assign notmiss_fifo_we = notmiss_VSpipe_valid_ds & notmiss_s3;

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
  assign miss_fifo_we = miss_VSpipe_valid_ds & miss_s3;

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

//------------------------------------------------------------------------
// rest write fifos
  // 0 == trav0
  // 1 == trav1
  // 2 == sint

  struct packed {
    rayID_t rayID;
    nodeID_t nodeID;
  } rest_write_fifo_in[3], rest_write_fifo_out[3];

  // fifo to accumulate Definite misses and definite hits
  logic [2:0] rest_write_fifo_full;
  logic [2:0] rest_write_fifo_empty;
  logic [2:0] rest_write_fifo_re;
  logic [2:0] rest_write_fifo_we;
  always_comb begin
    rest_write_fifo_in[0].rayID = trav0_to_ss_data.ray_info.rayID;
    rest_write_fifo_in[0].elem.nodeID =  trav0_to_ss_data.rest_node_ID;
    rest_write_fifo_in[0].elem.t_max =  trav0_to_ss_data.t_max;
    rest_write_fifo_in[1].rayID = trav1_to_ss_data.ray_info.rayID;
    rest_write_fifo_in[1].elem.nodeID =  trav1_to_ss_data.rest_node_ID;
    rest_write_fifo_in[1].elem.t_max =  trav1_to_ss_data.t_max;
    rest_write_fifo_in[2].rayID = sint_to_ss_data.ray_info.rayID;
    rest_write_fifo_in[2].elem.nodeID =  sint_to_ss_data.rest_node_ID;
    rest_write_fifo_in[2].elem.t_max =  sint_to_ss_data.t_max_scene;
  end

  assign rest_write_fifo_re = ;
  assign rest_write_fifo_we = ;


genvar i;
generate begin
  for(i=0; i<2; i+=1) begin
  fifo #(.DEPTH(3), .WIDTH($bits(rest_write_fifo_in)) ) rest_write_fifo_inst(
    .clk, .rst,
    .data_in(rest_write_fifo_in[i]),
    .data_out(rest_write_fifo_out[i]),
    .full(rest_write_fifo_full[i]),
    .empty(rest_write_fifo_empty[i]),
    .re(rest_write_fifo_re[i]),
    .we(rest_write_fifo_we[i]),
    .exists_in_fifo(),
    .num_left_in_fifo() );
  end
endgenerate


//------------------------------------------------------------------------
  logic [1:0] rest_w_rrptr, rest_w_rrptr_n;
  assign rest_w_rrptr_n = ( ) ? (rest_w_rrptr == 2'h2 ? 2''h0 : rest_w_rrptr + 1'b1) : rest_w_rrptr ;
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
  
  //logic notmiss_fifo_empty;
  
  logic [2:0] rest_wfifo_valid; // if not stalling and there is something in the write fifo
  logic [2:0] rest_wfifo_choice; // Both bits CAN be set here (resolves read/write conflict)
  
  assign rest_wfifo_valid = ~rest_write_fifo_empty;
  
  always_comb begin
    rest_wfifo_choice[rest_w_rrptr] = rest_wfifo_valid[rest_w_rrptr];
    rest_wfifo_choice[rest_w_rrptr1] = rest_wfifo_valid[rest_w_rrptr1] & ~(rest_wfifo_valid[rest_w_rrptr] & rest_is_reading);
    rest_wfifo_choice[rest_w_rrptr2] = rest_wfifo_valid[rest_w_rrptr2] & ( rest_wfifo_valid[rest_w_rrptr] + rest_wfifo_valid[rest_w_rrptr1] + rest_is_reading <= 1);
  end

  assign rest_write_fifo_re = rest_wfifo_choice;

  rayID_t addrA_rest, addrB_rest;
  float_t wrdataA_rest;
  float_t wrdataB_rest;
  logic wrenA_rest, wrenB_rest;
  float_t rddataA_rest;
  float_t rddataB_rest;

  
  always_comb begin
    unique case({rest_is_reading,rest_wfifo_choice})
      4'b1_100 : begin
        addrA_rest = rest_cur_raddr;
        addrB_rest = rest_write_fifo_out[2].rayID;
        wrdataA_rest = `DC ;
        wrdataB_rest = rest_write_fifo_out[2].t_max_scene;
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b1_010 : begin
        addrA_rest = rest_cur_raddr;
        addrB_rest = rest_write_fifo_out[1].rayID;
        wrdataA_rest = `DC ;
        wrdataB_rest = rest_write_fifo_out[1].t_max_scene;
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b1_001 : begin
        addrA_rest = rest_cur_raddr;
        addrB_rest = rest_write_fifo_out[0].rayID;
        wrdataA_rest = `DC ;
        wrdataB_rest = rest_write_fifo_out[0].t_max_scene;
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b1_000 : begin
        addrA_rest = rest_cur_raddr;
        addrB_rest = `DC;
        wrdataA_rest = `DC ;
        wrdataB_rest = `DC;
        wrenA_rest = 0;
        wrenB_rest = 0;
      end
      4'b0_100 : begin
        addrA_rest = `DC;
        addrB_rest = rest_write_fifo_out[2].rayID;
        wrdataA_rest = `DC ;
        wrdataB_rest = rest_write_fifo_out[2].t_max_scene;
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b0_010 : begin
        addrA_rest = `DC;
        addrB_rest = rest_write_fifo_out[1].rayID;
        wrdataA_rest = `DC ;
        wrdataB_rest = rest_write_fifo_out[1].t_max_scene;
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b0_001 : begin
        addrA_rest = `DC;
        addrB_rest = rest_write_fifo_out[0].rayID;
        wrdataA_rest = `DC ;
        wrdataB_rest = rest_write_fifo_out[0].t_max_scene;
        wrenA_rest = 0;
        wrenB_rest = 1;
      end
      4'b0_000 : begin
        addrA_rest = `DC;
        addrB_rest = `DC;
        wrdataA_rest = `DC ;
        wrdataB_rest = `DC;
        wrenA_rest = 0;
        wrenB_rest = 0;
      end     
      4'b0_110 : begin
        addrA_rest = rest_write_fifo_out[1].rayID;
        addrB_rest = rest_write_fifo_out[2].rayID;
        wrdataA_rest = rest_write_fifo_out[1].t_max_scene ;
        wrdataB_rest = rest_write_fifo_out[2].t_max_scene;
        wrenA_rest = 1;
        wrenB_rest = 1;
      end
      4'b0_101 : begin
        addrA_rest = rest_write_fifo_out[0].rayID;
        addrB_rest = rest_write_fifo_out[2].rayID;
        wrdataA_rest = rest_write_fifo_out[0].t_max_scene ;
        wrdataB_rest = rest_write_fifo_out[2].t_max_scene;
        wrenA_rest = 1;
        wrenB_rest = 1;
      end
      4'b0_011 : begin
        addrA_rest = rest_write_fifo_out[0].rayID;
        addrB_rest = rest_write_fifo_out[1].rayID;
        wrdataA_rest = rest_write_fifo_out[0].t_max_scene ;
        wrdataB_rest = rest_write_fifo_out[1].t_max_scene;
        wrenA_rest = 1;
        wrenB_rest = 1;
      end
    endcase
  end

  bram_dual_2port_512x32 rest_bram(
  .aclr(rst),
  .address_a(addrA_rest),
  .address_b(addrB_rest),
  .clock(clk),
  .data_a(wrdataA_rest),
  .data_b(wrdataB_rest),
  .wren_a(wrenA_rest),
  .wren_b(wrenB_rest),
  .q_a(rddataA_rest),
  .q_b());





//------------------------------------------------------------------------

endmodule
