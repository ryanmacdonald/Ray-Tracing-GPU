/* Calculates p = origin + t*dir
    Lat = 20 cycles


*/

module p_calc(
  input clk, rst,
  input v0, v1, v2,

  // inputs valid on v0
  input float_t t_int,
  input vector_t origin,
  input vector_t dir,
  
  output vector_t p_int
  );

  assign p_int = 'h0;
  
  // TODO actually calculate p_int you stupid shit

endmodule
  
