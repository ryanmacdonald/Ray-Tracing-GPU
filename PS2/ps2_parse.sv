`default_nettype none
// for each key, key[0] is the press pulse and key[1] is release pulse
/*
module tb;
  logic clk, rst_b;
  logic [7:0] ps2_pkt_DH;
  logic rec_ps2_pkt;
  keys_t keys;

  assign ps2_pkt_DH = 8'h5A;

  ps2_parse parse(.*);

endmodule
*/
/* make packets : "XX" or
                  "E0" "XX"
  break packets : "F0" "XX" or
                  "E0" "F0" "XX"

*/

module ps2_parse(clk, rst_b, ps2_pkt_DH, rec_ps2_pkt, keys);

  input clk, rst_b;
  input [7:0] ps2_pkt_DH;
  input rec_ps2_pkt;
  output keys_t keys;

  keys_t keys_i;
  logic is_E0, is_F0;
  logic E0_seen, F0_seen;
  logic E0_seen_next, F0_seen_next;
  logic set_E0_seen, set_F0_seen;
  logic parse_pkt;

  enum logic [1:0] {IDLE, E0, F0, PARSE} CS, NS;

  logic arc_IDLE_E0;
  logic arc_IDLE_F0;
  logic arc_IDLE_PARSE;
  logic arc_E0_F0;
  logic arc_E0_PARSE;
  logic arc_F0_PARSE;
  logic arc_PARSE_IDLE;

  assign is_E0 = (ps2_pkt_DH == 8'hE0);
  assign is_F0 = (ps2_pkt_DH == 8'hF0);

  assign arc_IDLE_E0 = rec_ps2_pkt & is_E0;
  assign arc_IDLE_F0 = rec_ps2_pkt & is_F0;
  assign arc_IDLE_PARSE = rec_ps2_pkt & ~is_E0 & ~is_F0;
  assign arc_E0_F0 = rec_ps2_pkt & is_F0;
  assign arc_E0_PARSE = rec_ps2_pkt & ~is_F0;
  assign arc_F0_PARSE = rec_ps2_pkt;

  assign set_E0_seen = arc_IDLE_E0 & (CS==IDLE);
  assign set_F0_seen = (arc_IDLE_F0 & (CS==IDLE)) | (arc_E0_F0 & (CS==E0));
  assign parse_pkt = rec_ps2_pkt & ~set_E0_seen & ~set_F0_seen ;

  always_comb begin
    case(CS)
      IDLE : begin
        NS = arc_IDLE_E0 ? E0 : (arc_IDLE_F0 ? F0 : (arc_IDLE_PARSE ? PARSE : IDLE));
      end
      E0 : begin
        NS = arc_E0_F0 ? F0 : (arc_E0_PARSE ? PARSE : E0);
      end
      F0 : begin
        NS = arc_F0_PARSE ? PARSE : F0 ;
      end
      PARSE : begin // TODO unneeded state
        NS = IDLE ;
      end
    endcase
  end

  always_ff @(posedge clk, negedge rst_b) begin
    if(~rst_b) CS <= IDLE;
    else CS <= NS;
  end

  assign E0_seen_next = parse_pkt ? 1'b0 : (set_E0_seen ? 1'b1 : E0_seen);
  assign F0_seen_next = parse_pkt ? 1'b0 : (set_F0_seen ? 1'b1 : F0_seen);

  always_ff @(posedge clk, negedge rst_b) begin
    if(~rst_b) E0_seen <= 1'b0;
    else E0_seen <= E0_seen_next;
  end
  always_ff @(posedge clk, negedge rst_b) begin
    if(~rst_b) F0_seen <= 1'b0;
    else F0_seen <= F0_seen_next;
  end

// Parses the pkt and sets the key
  always_comb begin
    keys_i = 'h0;
    if(parse_pkt) begin
      case({E0_seen,ps2_pkt_DH})
        9'h029 : keys_i.space = {F0_seen,~F0_seen};
        9'h175 : keys_i.up = {F0_seen,~F0_seen};
        9'h172 : keys_i.down = {F0_seen,~F0_seen};
        9'h16B : keys_i.left = {F0_seen,~F0_seen};
        9'h174 : keys_i.right = {F0_seen,~F0_seen};
        9'h012 : keys_i.lshift = {F0_seen,~F0_seen};
        9'h01A : keys_i.z = {F0_seen,~F0_seen};
        9'h05A : keys_i.enter = {F0_seen,~F0_seen};
        9'h021 : keys_i.c = {F0_seen,~F0_seen};
        9'h02D : keys_i.r = {F0_seen,~F0_seen};
        9'h04D : keys_i.p = {F0_seen,~F0_seen};
        9'h079 : keys_i.plus = {F0_seen,~F0_seen};
        9'h033 : keys_i.h = {F0_seen,~F0_seen};
        9'h01B : keys_i.s = {F0_seen,~F0_seen};
        9'h076 : keys_i.esc = {F0_seen,~F0_seen};
        9'h02B : keys_i.f = {F0_seen,~F0_seen};
        9'h023 : keys_i.d = {F0_seen,~F0_seen};
        default : ;
      endcase
    end
  end

  always_ff @(posedge clk, negedge rst_b) begin
    if(~rst_b) keys <= 'h0;
    else keys <= keys_i;
  end

endmodule
