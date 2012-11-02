/* Computes if each of the 4 cases.
  t_mid = (split - origin)/dir
  
  case(trav_case)
    0 : Traverse only low ( Do not change t_max / t_min )
    1 : Traverse only high ( Do not change t_max / t_min )
    2 : Travese low (t_max <= t_mid, t_min <= t_min)
        Push high (t_max <= t_max, t_min <= t_mid)
    3 : Travese high (t_max <= t_mid, t_min <= t_min)
        Push low (t_max <= t_max, t_min <= t_mid)
    All other cases are combinations of these cases with nodes being empty
  endcase


*/


module trav_math(
  input logic clk, rst,

  
  input float_t origin_in,
  input float_t dir_in,
  input float_t split_in,
  input float_t t_max_in,
  input float_t t_min_in,
  
  output float_t t_max_out,
  output float_t t_min_out,
  output float_t t_mid_out,

  output logic only_low,
  output logic only_high,
  output logic trav_lo_then_hi,
  output logic trav_hi_then_lo
  );


  struct packed {
    float_t dir;
  } trav_pipe1_in, trav_pipe1_out;

  always_comb begin
    trav_pipe1_in.dir = dir_in;
  end

  buf_t3 #(.LAT(7), .WIDTH($bits(trav_pipe1_in))) 
    trav_pipe1_buf7(.data_in(trav_pipe1_in), .data_out(trav_pipe1_out), .clk, .rst);

//----------------------------------------------------------
  struct packed {
    float_t t_min;
    float_t t_max;
  } t_minmax_in, t_minmax_out, t_minmax_buf;
  
  always_comb begin
    t_minmax_in.t_min = t_min_in;
    t_minmax_in.t_max = t_max_in;
  end

  buf_t3 #(.LAT(13), .WIDTH($bits(t_minmax_in))) 
    t_minmax_buf13(.data_in(t_minmax_in), .data_out(t_minmax_out), .clk, .rst);


//----------------------------------------------------------

  // Add  signals
  float_t inA_add, inB_add, out_add;
  logic nan_add, overflow_add, underflow_add, zero_add;

  assign inA_add = split_in;
  assign inB_add = {1'b0,origin_in[30:0]};
  altfp_add add(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add ),
  .datab(inB_add ),
  .nan(nan_add ),
  .overflow(overflow_add ),
  .result(out_add ),
  .underflow(underflow_add ),
	.zero(zero_add) );

//----------------------------------------------------------
  struct packed {
    logic origin_g_split;
    logic dir_g_0;
  } trav_pipe2_in, trav_pipe2_out;
  
  always_comb begin
    trav_pipe2_in.origin_g_split = out_add.sign; // TODO should be correct
    trav_pipe2_in.dir_g_0 = ~trav_pipe1_out.dir.sign;
  end
  buf_t3 #(.LAT(7), .WIDTH($bits(trav_pipe2_in))) 
    trav_pipe2_buf7(.data_in(trav_pipe2_in), .data_out(trav_pipe2_out), .clk, .rst);

   
//----------------------------------------------------------
  // Divider signals
  float_t inA_div, inB_div, out_div;
  logic nan_div, overflow_div, underflow_div, zero_div, division_by_zero_div;

  assign inA_div = out_add;
  assign inB_div = trav_pipe1_out.dir;
  altfp_div div1 (
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_div ),
  .datab(inB_div ),
  .division_by_zero(division_by_zero_div ),
  .nan(nan_div ),
  .overflow(overflow_div ),
  .result(out_div ),
  .underflow(underflow_div ),
	.zero(zero_div));


//----------------------------------------------------------

  // t_minmax buf  
  ff_ar #($bits(t_minmax_out),'h0) t_minmax_reg(.d(t_minmax_out), .q(t_minmax_buf), .clk, .rst);
  assign t_min_out = t_minmax_buf.t_min;
  assign t_max_out = t_minmax_buf.t_max;

//----------------------------------------------------------
  // t_mid buf
  ff_ar #($bits(float_t),'h0) t_mid_reg(.d(out_div), .q(t_mid_out), .clk, .rst);

//----------------------------------------------------------
  logic dir_eq_0;

  ff_ar #(1,1'b0) dir_eq_0_reg(.d(division_by_zero_div), .q(dir_eq_0), .clk, .rst);
  
//----------------------------------------------------------
  // Is t_max > t_mid ?
  float_t inA_maxmid, inB_maxmid;
  logic max_g_mid;
  assign inA_maxmid = t_minmax_out.t_max; // t_max
  assign inB_maxmid = out_div ;
  altfp_compare comp_maxmid (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_maxmid ),
  .datab(inB_maxmid ),
  //.aeb(out_aeb_comp1),
	.agb(max_g_mid) );

  
//----------------------------------------------------------
  // Is t_mid > t_min ?
  float_t inA_midmin, inB_midmin;
  logic mid_g_min;
  assign inA_midmin = out_div; // t_mid
  assign inB_midmin = t_minmax_out.t_min ;
  altfp_compare comp_midmin (
  .aclr(rst),
  .clock(clk ),
  .dataa(inA_midmin ),
  .datab(inB_midmin ),
  //.aeb(out_aeb_comp1),
	.agb(mid_g_min) );


//----------------------------------------------------------

  // OUTPUTS

  assign only_low = (trav_pipe2_out.origin_g_split & ~trav_pipe2_out.dir_g_0 & ~mid_g_min) |
                    (~trav_pipe2_out.origin_g_split & ~trav_pipe2_out.dir_g_0) |
                    (~trav_pipe2_out.origin_g_split & dir_eq_0) |
                    (~trav_pipe2_out.origin_g_split & trav_pipe2_out.dir_g_0 & ~max_g_mid);
 
  assign only_high = (~trav_pipe2_out.origin_g_split & trav_pipe2_out.dir_g_0 & ~mid_g_min) |
                     (trav_pipe2_out.origin_g_split & trav_pipe2_out.dir_g_0) |
                     (trav_pipe2_out.origin_g_split & dir_eq_0) |
                     (trav_pipe2_out.origin_g_split & ~trav_pipe2_out.dir_g_0 & ~max_g_mid);

  assign trav_lo_then_hi = ~trav_pipe2_out.origin_g_split & trav_pipe2_out.dir_g_0 & max_g_mid & mid_g_min;
  assign trav_hi_then_lo = trav_pipe2_out.origin_g_split & ~trav_pipe2_out.dir_g_0 & max_g_mid & mid_g_min;



endmodule























