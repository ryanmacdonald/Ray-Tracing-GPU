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

  struct packed {
    
  }


//------------------------------------------------------------------------
// Short Stack

