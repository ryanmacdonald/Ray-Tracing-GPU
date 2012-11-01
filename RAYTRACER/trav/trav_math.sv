/* Computes if each of the 4 cases.
  t_mid = (split - origin)/dir
  
  case(trav_case)
    0 : Traverse only low ( Do not change t_max / t_min )
    1 : Traverse only high ( Do not change t_max / t_min )
    2 : Travese low (t_max <= t_mid, t_min <= t_min)
        Push high (t_max <= t_max, t_min <= t_mid)
    3 : Travese high (t_max <= t_mid, t_min <= t_min)
        Push low (t_max <= t_max, t_min <= t_mid)
  endcase


*/


module trav_math(
  input logic clk, rst,

  
  input float_t origin,
  input float_t dir,
  input float_t split,
  input float_t t_max_in,
  input float_t t_min_in,
  
  output float_t t_max_out,
  output float_t t_min_out,

  output logic [3:0] trav_case,
  );

   


endmodule
