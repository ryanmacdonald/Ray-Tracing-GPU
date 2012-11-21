module negedge_detector(
    output logic ed,
    input logic in, clk, rst);

    logic ff_q;
    assign ed = ff_q & ~in;
    ff_ar #(1,0) ff(.q(ff_q), .d(in), .clk, .rst);

endmodule

module shifter #(parameter W=8, RV={W{1'b0}}) (
    output logic [W-1:0] q,
    input logic d, en, clr,
    input logic clk, rst);

    logic [W-1:0] shifted_bits, d_bits;
    assign shifted_bits[W-1] = d;
    assign shifted_bits[W-2:0] = q[W-1:1];

	logic en_ff;
    assign en_ff = en | clr;
    assign d_bits = (clr) ? RV : shifted_bits;
    ff_ar_en #(W,RV) r(.q, .d(d_bits), .en(en_ff), .clk, .rst);

endmodule

module counter #(parameter W=8, RV={W{1'b0}}) (
    output logic [W-1:0] cnt,
    input logic clr, inc,
    input logic clk, rst);

    logic [W-1:0] count_d;
    logic en;
    assign count_d = (clr) ? RV : (cnt+1'b1);
    assign en = inc || clr;
    ff_ar_en #(W, RV) count(.q(cnt), .d(count_d), .en, .clk, .rst);

endmodule

module ff_ar_en #(parameter W=1, RV={W{1'b0}}) (
    output logic [W-1:0] q,
    input logic [W-1:0] d,
    input logic en, clk, rst);

    logic [W-1:0] mux_out;
    assign mux_out = (en) ? d : q;

    ff_ar #(W,RV) ff(.q, .d(mux_out), .clk, .rst);

endmodule

// flip flop with asynchronous reset
// bit width and reset value are parameters
module ff_ar #(parameter W=1, RV={W{1'b0}}) (
    output logic [W-1:0] q,
    input logic [W-1:0] d,
    input logic clk, rst);

    always @(posedge clk, posedge rst) begin
        if(rst)
            q <= RV;
        else
            q <= d;
    end

endmodule

module compare
    #(parameter W=1) (
    output logic eq, aGT, bGT,
    input logic [W-1:0] a, b);

    assign eq = (a == b) ? 1'b1 : 1'b0;
    assign aGT = (a > b) ? 1'b1 : 1'b0;
    assign bGT = (b > a) ? 1'b1 : 1'b0;
endmodule

module addSub
    #(parameter W=1) (
    output logic [W-1:0] result,
    output logic z, n,
    input logic [W-1:0] a, b,
    input logic add);

    assign result = (add) ? (a+b) : (a-b);
    assign z = (result == 0) ? 1'b1 : 1'b0;
    assign n = result[W-1];

endmodule

module range_check
    #(parameter W=1) (
    output logic is_between,
    input logic [W-1:0] val, low, high);

    assign is_between = ((val >= low) && (val <= high)) ? 1'b1 : 1'b0;

endmodule

module sync_to_v
  #(parameter V=0) (
  output logic synced_signal,
  input logic clk, rst,
  input logic v0,v1,v2,
  input logic signal_to_sync );

  logic [1:0] CS, NS;
  
  logic d0, d1, d2;
  always_comb begin
    case(V)
      2'b00 : begin
        d0 = v0;
        d1 = v2;
        d2 = v1;
      end
      2'b01 : begin
        d0 = v1;
        d1 = v0;
        d2 = v2;
      end
      2'b10 : begin
        d0 = v2;
        d1 = v1;
        d2 = v0;
      end
    endcase
  end

  always_comb begin
    synced_signal = 1'b0;
    NS = 2'b00;
    case(CS)
      2'b00 : begin
        if(signal_to_sync) begin
          synced_signal = d0;
          NS = d2 ? 2'b10 : (d1 ? 2'b01 : 2'b00);
        end
      end
      2'b01 : begin
        NS = 2'b00;
        synced_signal = 1'b1;
      end
      2'b10 : begin
        NS = 2'b01;
      end
    endcase
  end

  ff_ar #(2,2'b00) ff(.q(CS), .d(NS), .clk, .rst);

endmodule

// depth 2^k
module fifo
#(  parameter WIDTH = 32, DEPTH = 10, NUM_W = $clog2(DEPTH+1))
(
  input logic clk, rst,
  input logic [WIDTH-1:0] data_in,
  input logic we,
  input logic re,
  output logic full,
  output logic exists_in_fifo,
  output logic empty,
  output logic [WIDTH-1:0] data_out,
  output logic [NUM_W-1:0] num_left_in_fifo);

  localparam K = NUM_W;

  logic write_valid, read_valid;

  logic [K-1:0] rPtr, rPtr_n;
  logic [K-1:0] wPtr, wPtr_n;
  logic [K:0] zero_cnt, zero_cnt_n;
  logic [K:0] one_cnt, one_cnt_n;

  assign num_left_in_fifo = zero_cnt;

  // actual queue
  logic [DEPTH-1:0][WIDTH:0] queue; // not -1 because of valid bit (for exists_in_fifo)
  logic [DEPTH-1:0][WIDTH:0] queue_n;

  //output assigns
  assign data_out = queue[rPtr][WIDTH-1:0]; // exclude valid bit
  assign empty = (one_cnt == 'h0 );
  assign full = (zero_cnt == 'h0);

  assign write_valid = we & ~full ;
  assign read_valid = re & ~empty ;
  always_comb begin
    case({write_valid,read_valid})
      2'b00 : one_cnt_n = one_cnt;
      2'b01 : one_cnt_n = one_cnt - 1'b1 ;
      2'b10 : one_cnt_n = one_cnt + 1'b1 ;
      2'b11 : one_cnt_n = one_cnt;
    endcase
  end

  always_comb begin
    case({write_valid,read_valid})
      2'b00 : zero_cnt_n = zero_cnt;
      2'b01 : zero_cnt_n = zero_cnt + 1'b1 ;
      2'b10 : zero_cnt_n = zero_cnt - 1'b1 ;
      2'b11 : zero_cnt_n = zero_cnt;
    endcase
  end

  always_comb begin
    queue_n = queue ;
    if(write_valid) queue_n[wPtr[K-1:0]] = {1'b1,data_in}; // set the valid bit
    if(read_valid) queue_n[rPtr[K-1:0]] = 'h0;
  end
 
  assign rPtr_n = read_valid ? (rPtr == DEPTH-1 ? 'h0 : rPtr + 1'b1) : rPtr ;
  assign wPtr_n = write_valid ? (wPtr == DEPTH-1 ? 'h0 : wPtr + 1'b1) : wPtr ;

  ff_ar #(K,'h0) ff_r(.q(rPtr), .d(rPtr_n), .clk, .rst);
  ff_ar #(K,'h0) ff_w(.q(wPtr), .d(wPtr_n), .clk, .rst);
  ff_ar #(DEPTH*(WIDTH+1),'h0) ff_q(.q(queue), .d(queue_n), .clk, .rst); 
  ff_ar #(K+1,DEPTH) ff_zero_cnt(.q(zero_cnt), .d(zero_cnt_n), .clk, .rst);
  ff_ar #(K+1,'h0) ff_one_cnt(.q(one_cnt), .d(one_cnt_n), .clk, .rst);

  int i;
  always_comb begin
    exists_in_fifo = 1'b0;
    for(i=0; i < DEPTH; i++) begin
      if(queue[i][WIDTH-1:0] == data_in && queue[i][WIDTH]) // AND with valid bit
        exists_in_fifo = 1'b1;
    end
  end

endmodule

/* This has the 3 types of buffers  
  t3: data 3/3 of clocks
  t2: data 2/3 of clocks
  t1: data 1/3 of clocks
*/

module buf_t1 #(parameter LAT = 10, WIDTH = 10) (
  input logic clk,
  input logic rst,
  input logic v0,

  input logic[WIDTH-1:0] data_in,
  output logic[WIDTH-1:0] data_out
  );

  localparam NUMREGS = (LAT+2)/3; // CEILING of LAT/3

  logic[NUMREGS-1:0][WIDTH-1:0] data_buf, data_buf_n;

  assign data_out = data_buf[NUMREGS-1];

  

  always_ff @(posedge clk, posedge rst) begin
    if(rst) data_buf <= 'h0;
    else if(v0) data_buf <= {data_buf[NUMREGS-2:0], data_in} ;
  end

endmodule


module buf_t3 #(parameter LAT = 10, WIDTH = 10) (
  input logic clk,
  input logic rst,

  input logic[WIDTH-1:0] data_in,
  output logic[WIDTH-1:0] data_out
  );

  logic[LAT-1:0][WIDTH-1:0] data_buf;
  assign data_out = data_buf[LAT-1];

  always_ff @(posedge clk, posedge rst) begin
    if(rst) data_buf <= 'h0;
    else data_buf <= {data_buf[LAT-2:0],data_in};
  end

endmodule

module VS_buf #(parameter WIDTH = 8) (
  input logic clk, rst,
  input logic valid_us,
  input logic [WIDTH-1:0] data_us,
  output logic stall_us,

  output logic valid_ds,
  output logic [WIDTH-1:0] data_ds,
  input logic stall_ds );

  logic stall;
  logic tmp_valid, tmp_valid_n;
  logic [WIDTH-1:0] tmp_data, tmp_data_n;

  


  `ifdef SYNTH
    assign data_ds = tmp_valid ? tmp_data : data_us ;
    assign valid_ds = tmp_valid | valid_us ;
    assign stall_us = stall & valid_us;
    assign tmp_data_n = stall ? tmp_data : data_us ;
    assign tmp_valid_n = stall_ds ? (stall ? tmp_valid : valid_us ) : 1'b0;
  `else
    assign data_ds = tmp_valid ? tmp_data : (valid_us ? data_us : 'hX) ;
    assign valid_ds = tmp_valid | valid_us ;
    assign stall_us = stall & valid_us;

    always_comb begin // stall_ds assumes that valid_ds is asserted
      case({stall_ds, stall})
        2'b00 : tmp_data_n = 'hX;
        2'b10 : tmp_data_n = valid_ds ? data_us : 'hX ;
        2'b01 : tmp_data_n = 'hX ;
        2'b11 : tmp_data_n = tmp_valid ? tmp_data : 'hX ;
      endcase
      case({stall_ds, stall})
        2'b00 : tmp_valid_n = 0;
        2'b10 : tmp_valid_n = valid_us ? 1 : 0 ;
        2'b01 : tmp_valid_n =  0 ;
        2'b11 : tmp_valid_n = tmp_valid ? 1 : 0 ;
      endcase
    end
  `endif

  always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
      stall <= 0;
      tmp_valid <= 'h0;
      tmp_data <= 0;
    end
    else begin
      stall <= stall_ds;
      tmp_valid <= tmp_valid_n;
      tmp_data <= tmp_data_n;
    end
  end

endmodule


module minimum3 #(parameter WIDTH = 4)
		(output logic[WIDTH-1:0] out,
		 input  logic[WIDTH-1:0] in1, in2, in3);

	logic[WIDTH-1:0] temp;

	minimum2 #(.WIDTH(WIDTH)) m1(temp,in1,in2);
	minimum2 #(.WIDTH(WIDTH)) m2(out,temp,in3);

endmodule: minimum3


module minimum2 #(parameter WIDTH = 4)
	 (output logic[WIDTH-1:0] out,
	  input  logic[WIDTH-1:0] in1, in2);

	assign out = (in1 < in2) ? in1 : in2;

endmodule: minimum2


module pipe_valid_stall #(parameter WIDTH = 8, DEPTH = 20, NUM_W = $clog2(DEPTH+2)) (
  input logic clk, rst,
  input logic us_valid,
  input logic [WIDTH-1:0] us_data,
  output logic us_stall,

  output logic ds_valid,
  output logic [WIDTH-1:0] ds_data,
  input logic ds_stall,

  input logic [NUM_W-1:0] num_left_in_fifo);

  logic [DEPTH-1:0] valid_buf, valid_buf_n;
  assign valid_buf_n = {~us_stall & us_valid,valid_buf[DEPTH-1:1]};
  assign ds_valid = valid_buf[0];

  ff_ar #(DEPTH,0) valid_inst(.d(valid_buf_n),.q(valid_buf),.clk,.rst);

  buf_t3 #(.LAT(DEPTH), .WIDTH(WIDTH)) data_buf(.clk,.rst,.data_in(us_data),.data_out(ds_data));

  logic [NUM_W-1:0] one_cnt, one_cnt_n;
  always_comb begin
    case({valid_buf_n[DEPTH-1],valid_buf[0]})
      2'b00 : one_cnt_n = one_cnt;
      2'b10 : one_cnt_n = one_cnt + 1;
      2'b01 : one_cnt_n = one_cnt - 1;
      2'b11 : one_cnt_n = one_cnt ;
    endcase
  end

  ff_ar #(NUM_W,0) cnt_inst(.d(one_cnt_n),.q(one_cnt),.clk,.rst);

  assign us_stall = ds_stall & (one_cnt >= num_left_in_fifo); // Used to & with us_valid

endmodule
/*
module lshape #(parameter SIDE_W = 10, UNSTALL_W = 100, DEPTH = 20)
  (

  input logic clk, rst,
  input logic us_valid,
  input logic [SIDE_W-1:0] us_side_data,
  output logic us_stall,
  
  input logic [UNSTALL_W-1:0] us_unstall_data,

  output logic empty,
  output logic [SIDE_W + UNSTALL_W-1:0] ds_data,
  input logic rdreq,
  input logic ds_stall
  
  );
  
  logic ds_valid;
  logic [SIDE_W-1:0] sb_to_fifo;
  logic full;
  logic [$clog2(DEPTH+2):0] num_left_in_fifo;
    
  `ifndef SYNTH
    always @(*) assert(!(full & ds_valid));
  `endif


  pipe_valid_stall #(.WIDTH(SIDE_W), .DEPTH(DEPTH)) pipe_inst(
    .clk, .rst,
    .us_valid,
    .us_data(us_side_data),
    .us_stall,
    .ds_valid,
    .ds_data(sb_to_fifo),
    .ds_stall,
    .num_left_in_fifo );

  fifo #(.DEPTH(DEPTH), .WIDTH(SIDE_W+UNSTALL_W)) fifo_inst(
    .data_in({sb_to_fifo,us_unstall_data}),
    .data_out(ds_data),
    .full,
    .empty,
    .re(rdreq),
    .we(ds_valid),
    .num_left_in_fifo,
    .clk, .rst);

endmodule
*/
`ifndef FUCKING_STRUCTS
  `include "COMMON/structs.sv"
  `define FUCKING_STRUCTS
`endif

module arbitor #(parameter NUM_IN=4, WIDTH = 10) (

  input clk, rst,
  input logic [NUM_IN-1:0] valid_us,
  output logic [NUM_IN-1:0] stall_us,
  input logic [NUM_IN-1:0][WIDTH-1:0] data_us,


  output logic valid_ds,
  input logic stall_ds,
  output [WIDTH-1:0] data_ds

  );

  logic stall_s1; // This is asserted independent of valid
  logic valid_s1, valid_s1_n;
  logic [WIDTH-1:0] data_s1, data_s1_n;

  logic [NUM_IN-1:0][$clog2(NUM_IN)-1:0] rrptr_arr, rrptr_arr_n;
  
  genvar j;
  generate
    for(j=0; j<NUM_IN; j++) begin : hurrdurr_rptr
      assign rrptr_arr_n[j] = ~stall_s1 & (|valid_us) ? (rrptr_arr[j] == (NUM_IN-1) ? 'h0 : rrptr_arr[j] + 1'b1) : rrptr_arr[j] ;
      ff_ar #($clog2(NUM_IN),j) rrptr_arr_buf(.d(rrptr_arr_n[j]), .q(rrptr_arr[j]), .clk, .rst);
    end :hurrdurr_rptr
  endgenerate

  logic [NUM_IN-1:0] choice;
  logic chosen;
  logic [WIDTH-1:0] chosen_data;
  always_comb begin
    choice = 'h0;
    chosen_data = `DC;
    choice[rrptr_arr[0]] = ~stall_s1 & valid_us[rrptr_arr[0]];
    chosen = ~stall_s1 & valid_us[rrptr_arr[0]];
    if(chosen) chosen_data = data_us[rrptr_arr[0]];
    for(int i=1; i<NUM_IN; i++) begin
      choice[rrptr_arr[i]] = chosen ? 1'b0 : ~stall_s1 & valid_us[rrptr_arr[i]] ;
      if(~chosen & ~stall_s1 & valid_us[rrptr_arr[i]]) chosen_data = data_us[rrptr_arr[i]];
      chosen = chosen | (~stall_s1 & valid_us[rrptr_arr[i]]) ;

    end
  end

  logic VS_buf_stall;
  assign data_s1_n = valid_s1 & VS_buf_stall ? data_s1 : (~stall_s1 & (|valid_us) ? chosen_data : `DC);
  assign valid_s1_n = valid_s1 & VS_buf_stall ? 1'b1 : (~stall_s1 &(|valid_us) ? 1'b1 : 1'b0) ;
  assign stall_s1 = valid_s1 & VS_buf_stall ;

  ff_ar #(1,'h0) valid_s1_buf(.d(valid_s1_n), .q(valid_s1), .clk, .rst);
  ff_ar #(WIDTH,'h0) data_s1_buf(.d(data_s1_n), .q(data_s1), .clk, .rst);


  VS_buf #(WIDTH) buffer_that_stall(
    .clk,
    .rst,
    .valid_us(valid_s1),
    .data_us(data_s1),
    .stall_us(VS_buf_stall),
    .valid_ds,
    .data_ds,
    .stall_ds );


endmodule
