
`default_nettype none

`ifndef LIBARAY_SV
`define LIBRARY_SV
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
        NS = 2'b10;
      end
    endcase
  end

  ff_ar #(2,2'b00) ff(.q(CS), .d(NS), .clk, .rst);

endmodule
`endif
