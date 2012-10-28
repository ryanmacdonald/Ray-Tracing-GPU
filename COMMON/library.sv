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
module fifo(clk, rst,
            data_in, we, re, full, empty, data_out);
  parameter WIDTH = 32;
  parameter K = 2;
  input clk, rst;
  input [WIDTH-1:0] data_in;
  input we;
  input re;
  output full;
  output empty;
  output [WIDTH-1:0] data_out ;

  logic write_allowed, read_allowed;

  logic [K:0] rPtr, rPtr_n;
  logic [K:0] wPtr, wPtr_n;


  // actual queue
  logic [(1<<K) - 1:0][WIDTH-1:0] queue;
  logic [(1<<K) - 1:0][WIDTH-1:0] queue_n;

  //output assigns
  assign data_out = queue[rPtr[K-1:0]];
  assign empty = (rPtr == wPtr) ;
  assign full = (rPtr == {~wPtr[K],wPtr[K-1:0]} );

  assign write_allowed = we & ~full ;
  assign read_allowed = re & ~empty ;

  always_comb begin
    queue_n = queue ;
    if(write_allowed) queue_n[wPtr[K-1:0]] = data_in;
    if(read_allowed) queue_n[rPtr[K-1:0]] = 'h0;
  end
 
  assign rPtr_n = read_allowed ? rPtr + 1'b1 : rPtr ;
  assign wPtr_n = write_allowed ? wPtr + 1'b1 : wPtr ;

  ff_ar #(K+1,'h0) ff_r(.q(rPtr), .d(rPtr_n), .clk, .rst);
  ff_ar #(K+1,'h0) ff_w(.q(wPtr), .d(wPtr_n), .clk, .rst);
  ff_ar #((1<<K)*WIDTH,'h0) ff_q(.q(queue), .d(queue_n), .clk, .rst); 

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
