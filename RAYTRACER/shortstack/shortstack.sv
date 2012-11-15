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
    ray_info_t ray_info;
    float_t t_min;
  } stack_read_fifo_in[3], stack_read_fifo_out[3];

  logic [2:0] stack_read_fifo_full;
  logic [2:0] stack_read_fifo_empty;
  logic [2:0] stack_read_fifo_re;
  logic [2:0] stack_read_fifo_we;
  always_comb begin
    stack_read_fifo_in.ray_info[0] = trav0_to_ss_data.ray_info;
    stack_read_fifo_in.t_min[0] =  trav0_to_ss_data.t_max;
    stack_read_fifo_in.ray_info[1] = trav1_to_ss_data.ray_info;
    stack_read_fifo_in.t_min[1] =  trav1_to_ss_data.t_max;
    stack_read_fifo_in.ray_info[2] = list_to_ss_data.ray_info;
    stack_read_fifo_in.t_min[2] = list_to_ss_data.t_max;
  end

  assign stack_read_fifo_we = ;


genvar i;
generate begin
  for(i=0; i<3; i+=1) begin
  fifo #(.K(2), .WIDTH($bits(stack_read_fifo_in)) ) stack_read_fifo_inst(
    .clk, .rst,
    .data_in(stack_read_fifo_in[i]),
    .data_out(stack_read_fifo_out[i]),
    .full(stack_read_fifo_full[i]),
    .empty(stack_read_fifo_empty[i]),
    .re(stack_read_fifo_re[i]),
    .we(stack_read_fifo_we[i]),
    .num_in_fifo() );
  end
end

//------------------------------------------------------------------------
// Short Stack write fifos
  // 0 == trav0
  // 1 == trav1

  struct packed {
    rayID_t rayID;
    ss_elem_t elem;
  } stack_write_fifo_in[2], stack_write_fifo_out[2];

  // fifo to accumulate Definite misses and definite hits
  logic stack_write_fifo_full[2];
  logic stack_write_fifo_empty[2];
  logic stack_write_fifo_re[2];
  logic stack_write_fifo_we[2];
  always_comb begin
    stack_write_fifo_in.ray_info[0] = trav0_to_ss_data.ray_info;
    stack_write_fifo_in.elem.nodeID[0] =  trav0_to_ss_data.push_node_ID;
    stack_write_fifo_in.elem.t_max[0] =  trav0_to_ss_data.t_max;
    stack_write_fifo_in.ray_info[1] = trav1_to_ss_data.ray_info;
    stack_write_fifo_in.elem.nodeID[1] =  trav1_to_ss_data.push_node_ID;
    stack_write_fifo_in.elem.t_max[1] =  trav1_to_ss_data.t_max;
  end

  assign stack_write_fifo_re = ;
  assign stack_write_fifo_we = ;


genvar i;
generate begin
  for(i=0; i<2; i+=1) begin
  fifo #(.K(2), .WIDTH($bits(stack_write_fifo_in)) ) stack_write_fifo_inst(
    .clk, .rst,
    .data_in(stack_write_fifo_in[i]),
    .data_out(stack_write_fifo_out[i]),
    .full(stack_write_fifo_full[i]),
    .empty(stack_write_fifo_empty[i]),
    .re(stack_write_fifo_re[i]),
    .we(stack_write_fifo_we[i]),
    .num_in_fifo() );
  end
endgenerate


//------------------------------------------------------------------------
// Stack instantiations
  rayID_t addrA_stack[4], addrB_stack[4];
  ss_elem_t wrdataA_stack[4];
  ss_elem_t wrdataB_stack[4];
  logic [3:0] wrenA_stack, wrenB_stack;
  ss_elem_t rddataA_stack[4];
  ss_elem_t rddataB_stack[4];

  logic [1:0] stack_rr_ptr, stack_rr_ptr_n;
  assign rr_ptr_n = ( ) ? (stack_rr_ptr == 2'h2 ? 2''h0 : stack_rr_ptr + 1'b1) : stacK_rr_ptr ;
  ff_ar #(1,1'b0) stack_rr_ptr_buf(.d(stack_rr_ptr_n), .q(stack_rr_ptr), .clk, .rst);
  
  logic [2:0] trans_valid, trans_choice;
  assign trans_valid = ~stack_write_fifo_empty & {3{stack_VSpipe_stall_us}};
  always_comb begin
    trans_choice = 'h0;
    trans_choice[stack_rr_ptr] = trans_valid[stack_rr_ptr];
    trans_choice[stack_rr_ptr+2'b01] = trans_valid[stack_rr_ptr+2'b01] & ~trans_choice[stack_rr_ptr] ;
    trans_choice[stack_rr_ptr+2'b10] = trans_valid[stack_rr_ptr+2'b10] & ~trans_choice[stack_rr_ptr] & ~trans_chocie[stack_rr_ptr+2'b01];
  end
  
  assign stack_read_fifo_re = trans_choice;
  
  
  // reading always has addrA priority
  
  assign addrA_stack = ;
  assign wrdataA_stack = ;
  assign wrenA_stack = ;
  assign addrB_stack = ;
  assign wrdataB_stack = ;
  assign wrenB_stack = ;

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
    .q_b(rddataB_stack[i]));
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
  logic [2:0] num_in_stack_fifo;
  
  always_comb begin
    unique case(trans_choice);
      3'b100 : stack_VS_pipe_in = read_fifo_out[2];
      3'b010 : stack_VS_pipe_in = read_fifo_out[1];
      3'b001 : stack_VS_pipe_in = read_fifo_out[0];
      3'b000 : stack_VS_pipe_in = 'hX;
    endcase
  end
  assign stack_VSpipe_valid_us = ;
  

  pipe_valid_stall #(.WIDTH($bits(stack_VSpipe_in)), .DEPTH(4)) stack_VSpipe_inst(
    .clk, .rst,
    .us_valid(stack_VSpipe_valid_us),
    .us_data(stack_VSpipe_in),
    .us_stall(stack_VSpipe_stall_us),
    .ds_valid(stack_VSpipe_valid_ds),
    .ds_data(stack_VSpipe_out),
    .ds_stall(stack_VSpipe_stall_ds),
    .num_in_fifo(num_in_stack_fifo) );

//------------------------------------------------------------------------
// Stack fifo
  struct packed {
    ray_info_t ray_info;
    float_t t_max;
    float_t t_min;
    nodeID_t nodeID;
  } stack_fifo_in, stack_fifo_out;

  // fifo to accumulate Definite misses and definite hits
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

  fifo #(.K(1), .WIDTH($bits(stack_fifo_in)) ) stack_fifo_inst(
    .clk, .rst,
    .data_in(stack_fifo_in),
    .data_out(stack_fifo_out),
    .full(stack_fifo_full),
    .empty(stack_fifo_empty),
    .re(stack_fifo_re),
    .we(stack_fifo_we),
    .num_in_fifo(num_in_stack_fifo) );

  assign ss_to_tarb0_valid = ~stack_fifo_empty;
  assign ss_to_tarb0_data = stack_fifo_out;
  assign stack_fifo_re = ss_to_tarb0_valid & ~ss_to_tarb0_stall ;



















//------------------------------------------------------------------------
// Restart Path

//------------------------------------------------------------------------










endmodule
