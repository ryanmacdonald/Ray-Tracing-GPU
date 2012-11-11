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
            data_in, we, re, full, empty, data_out, num_in_fifo);
  parameter WIDTH = 32;
  parameter K = 2;
  input clk, rst;
  input [WIDTH-1:0] data_in;
  input we;
  input re;
  output full;
  output empty;
  output [WIDTH-1:0] data_out ;
  output [K:0] num_in_fifo;



  logic write_allowed, read_allowed;

  logic [K:0] rPtr, rPtr_n;
  logic [K:0] wPtr, wPtr_n;
  logic [K:0] cnt, cnt_n;

  assign num_in_fifo = cnt;

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
    case({write_allowed,read_allowed})
      2'b00 : cnt_n = cnt;
      2'b01 : cnt_n = cnt - 1'b1 ;
      2'b10 : cnt_n = cnt + 1'b1 ;
      2'b11 : cnt_n = cnt;
    endcase
  end

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
  ff_ar #(K+1,'h0) ff_cnt(.q(cnt), .d(cnt_n), .clk, .rst);

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

module pipe_valid_stall #(parameter WIDTH = 8, DEPTH = 20) (
  input logic clk, rst,
  input logic us_valid,
  input logic [WIDTH-1:0] us_data,
  output logic us_stall,

  output logic ds_valid,
  output logic [WIDTH-1:0] ds_data,
  input logic ds_stall,

  input logic [$clog2(DEPTH+2)-1:0] num_in_fifo

  );

  logic [DEPTH-1:0] valid_buf, valid_buf_n;
  assign valid_buf_n = {~us_stall & us_valid,valid_buf[DEPTH-1:1]};
  assign ds_valid = valid_buf[0];

  ff_ar #(DEPTH,0) valid_inst(.d(valid_buf_n),.q(valid_buf),.clk,.rst);

  buf_t3 #(.LAT(DEPTH), .WIDTH(WIDTH)) data_buf(.clk,.rst,.data_in(us_data),.data_out(ds_data));

  logic [$clog2(DEPTH+2)-1:0] zero_cnt, zero_cnt_n;
  always_comb begin
    case({valid_buf_n[DEPTH-1],valid_buf[0]})
      2'b00 : zero_cnt_n = zero_cnt;
      2'b10 : zero_cnt_n = zero_cnt - 1;
      2'b01 : zero_cnt_n = zero_cnt + 1;
      2'b11 : zero_cnt_n = zero_cnt ;
    endcase
  end

  ff_ar #($clog2(DEPTH+2),DEPTH) cnt_inst(.d(zero_cnt_n),.q(zero_cnt),.clk,.rst);

  assign us_stall = ds_stall & (zero_cnt <= num_in_fifo); // Used to & with us_valid

endmodule

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
  logic [$clog2(DEPTH+2)-1:0] num_in_fifo;
    
  `ifndef SYNTH
    always @(*) assert(!(full & ds_valid));
  `endif


  pipe_valid_stall #(.WIDTH(SIDE_W), .DEPTH(20)) pipe_inst(
    .clk, .rst,
    .us_valid,
    .us_data(us_side_data),
    .us_stall,
    .ds_valid,
    .ds_data(sb_to_fifo),
    .ds_stall,
    .num_in_fifo );

  fifo #(.K($clog2(DEPTH)-1), .WIDTH(SIDE_W+UNSTALL_W)) fifo_inst(
    .data_in({sb_to_fifo,us_unstall_data}),
    .data_out(ds_data),
    .full,
    .empty,
    .re(rdreq),
    .we(ds_valid),
    .num_in_fifo,
    .clk, .rst);

endmodule
