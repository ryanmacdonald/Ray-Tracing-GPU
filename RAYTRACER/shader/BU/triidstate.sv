
module begin
  input clk, rst,

  input logic triidstate_valid_us;
  input data shadow_or_miss_t triidstate_data_us;
  output logic triidstate_stall_us

  input logic triID_we;
  input logic triID_t triid_wrdata;

  output logic triidstate_to_scache_valid;
  output triidstate_to_scache_t triidstate_to_scache_data;
  input logic triidstate_to_scache_stall;

  output logic early_miss_valid;
  output early_miss_data;
  input logic early_miss_stall;



end
