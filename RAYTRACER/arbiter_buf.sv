/* This module is the buffer / arbitor logic for sending work downstream
TODO THIS MODULE INCOMPLETE


*/
module arbitor_buf
  #(
  parameter NUM_TOP = 3;
  parameter NUM_BOT = 4;
  parameter TOP_to_BOT_W = 16;
  parameter BOT_to_TOP_W = 20;
  )
  (
  input clk;
  input rst;

  // Top -> Arb (This will be buffered)
  input logic [NUM_TOP-1:0] top_to_arb_request,
  output logic [NUM_TOP-1:0] top_to_arb_accept,
  input logic [NUM_TOP-1:0][TOP_to_BOT_W-1:0] top_to_arb_data_in,

  // Arb -> Bot
  input logic [NUM_BOT-1:0] arb_to_bot_free,
  output logic [NUM_BOT-1:0] arb_to_bot_put,
  output logic [NUM_BOT-1:0][TOP_to_BOT_W-1:0] arb_to_bot_data_out,

  // Bot -> Arb (This will be buffered)
  input logic [NUM_BOT-1:0] bot_to_arb_request,
  output logic [NUM_BOT-1:0] bot_to_arb_accept,
  input logic [NUM_BOT-1:0][BOT_to_TOP-1:0] bot_to_arg_data_in,
  
  // Arb -> Top
  output logic [NUM_TOP-1:0] arb_to_top_free,
  output logic [NUM_TOP-1:0] arb_to_top_put,
  output logic [NUM_TOP-1:0][BOT_to_TOP-1:0] arb_to_top_data_out
  );

  logic [NUM_TOP-1:0] downstream_has_data;
  logic [NUM_TOP-1:0] downstream_taken_data;
  logic [NUM_TOP-1:0][TOP_to_BOT_W-1:0] downstream_data;
 
  genvar topi;
  generate
    for(topi = 0; topi < NUM_TOP; topi= topi+1) begin
      req_acc_buf #(TOP_to_BOT_W) 
        top_to_arb_buf(.request(top_to_arb_request[topi]), .accept(top_to_arb_accept[topi]),
                       .data_in(top_to_arb_data_in[i]), .has_data(downstream_has_data[i]),
                       .taken_data(downstream_taken_data[i]), .data_out(downstream_data[i]) );
    end
  endgenerate

  logic [NUM_TOP-1:0][$clog2(NUM_TOP)-1:0] rr_top_pri;

  // assign rr_top_pri to contain the index of the most important in 0 to least important in 1
  always_comb begin
    for(logic  i = 0; i<NUM_TOP; i++) begin
      rr_top_pri[i] = (rr_top + i
    end
  end

  logic [NUM_TOP_W-1:0] rr_top;
  logic [NUM_TOP_W-1:0] neg_rr_top

  //construct transaction_en matrix
  logic [NUM_TOP-1:0][NUM_BOT-1:0] dec_matrix;
  
  logic [NUM_BOT-1:0][NUM_BOT_W-1:0] free_bot_ports;
  logic [NUM_BOT-1:0] free_bot_ports_mask;
  

  if(arb_to_bot_free[0])
    
  for(int i=0; i<NUM_BOT; i++) begin
    
  end


endmodule

module req_acc_buf(
  parameter DATA_W = 8;

  input logic request,
  output logic accept,
  input logic [DATA_W-1:0] data_in,

  output logic has_data,
  input logic taken_data,
  output logic [DATA_W-1:0] data_out,
);

  logic ld, clr;
  
  logic data_valid;
  logic data_valid_n;
  
  assign ld = request & (~data_valid | taken_data);
  assign clr = taken_data & ~request ;
  assign data_valid_n = ld ? 1'b1 : ( clr ? 1'b0 : data_valid);

  DQFF_EN #(DATA_W) data_reg(.D(data_in), .Q(data_out), .EN(ld), .*);
  DQFF #(1) data_valid_reg(.D(data_valid_n), .Q(data_valid), .*);


  assign accept = ld;
  assign has_data = data_valid;

endmodule
