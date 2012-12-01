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
      keys_i.pressed = ~F0_seen;
      keys_i.released = F0_seen;
      case({E0_seen,ps2_pkt_DH})

	// Translation keys
        9'h015 : keys_i.q = {F0_seen,~F0_seen};
        9'h01D : keys_i.w = {F0_seen,~F0_seen};
        9'h024 : keys_i.e = {F0_seen,~F0_seen};
        9'h01C : keys_i.a = {F0_seen,~F0_seen};
        9'h01B : keys_i.s = {F0_seen,~F0_seen};
        9'h023 : keys_i.d = {F0_seen,~F0_seen};

	// Rotation keys
	9'h03C : keys_i.u = {F0_seen,~F0_seen};
	9'h03B : keys_i.j = {F0_seen,~F0_seen};
	9'h043 : keys_i.i = {F0_seen,~F0_seen};
	9'h042 : keys_i.k = {F0_seen,~F0_seen};
	9'h044 : keys_i.o = {F0_seen,~F0_seen};
	9'h04B : keys_i.l = {F0_seen,~F0_seen};

	// Resolution keys
	9'h016 : keys_i.n1 = {F0_seen,~F0_seen};
	9'h01E : keys_i.n2 = {F0_seen,~F0_seen};
	9'h026 : keys_i.n3 = {F0_seen,~F0_seen};
	9'h025 : keys_i.n4 = {F0_seen,~F0_seen};
	9'h02E : keys_i.n5 = {F0_seen,~F0_seen};
	9'h036 : keys_i.n6 = {F0_seen,~F0_seen};

	// Camera speed keys
	9'h03D : keys_i.n7 = {F0_seen,~F0_seen};
	9'h03E : keys_i.n8 = {F0_seen,~F0_seen};
	9'h046 : keys_i.n9 = {F0_seen,~F0_seen};
	9'h045 : keys_i.n0 = {F0_seen,~F0_seen};

        default : ;
      endcase
    end
  end

  always_ff @(posedge clk, negedge rst_b) begin
    if(~rst_b) keys <= 'h0;
    else keys <= keys_i;
  end

endmodule
