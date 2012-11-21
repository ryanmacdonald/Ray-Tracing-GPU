
module tb_shade();
  
  bit clk, rst;


  bit prg_to_shader_valid;
  prg_ray_t prg_to_shader_data;
  bit prg_to_shader_stall;

  
  bit pcalc_to_shader_valid;
  rs_to_pcalc_t pcalc_to_shader_data;
  bit pcalc_to_shader_stall;

  bit int_to_shader_valid;
  int_to_shader_t int_to_shader_data;
  bit int_to_shader_stall;

  bit sint_to_shader_valid;
  sint_to_shader_t sint_to_shader_data;
  bit sint_to_shader_stall;

  bit ss_to_shader_valid;
  ss_to_shader_t ss_to_shader_data;
  bit ss_to_shader_stall;

  
  bit pb_we;
  bit pb_full;
  pixel_buffer_entry_t pb_data_out;
 

  bit shader_to_sint_valid;
  shader_to_sint_t shader_to_sint_data;
  bit shader_to_sint_stall;

	bit raystore_we;
	rayID_t raystore_write_addr;
	ray_vec_t raystore_write_data;

  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end

  simple_shader_unit inst(.*);

  initial begin
    repeat(20) @(posedge clk);
    prg_to_shader_valid <= 1'b1;
    prg_to_shader_data.pixelID <= 'h9;
    prg_to_shader_data.origin <= create_vec(3,2,1);
    prg_to_shader_data.dir <= create_vec(-5,7,9);
    @(posedge clk);
    prg_to_shader_valid <= 0;
    prg_to_shader_data <= 'hx;
    repeat(50) @(posedge clk);
    pcalc_to_shader_valid <= 1;
    pcalc_to_shader_data.triID <= 4;
    pcalc_to_shader_data.rayID <= 'h0;
    @(posedge clk); 
    pcalc_to_shader_valid <= 0;
    pcalc_to_shader_data.triID <= 'hx;
  
    repeat(20) @(posedge clk); 
    $finish;
  end

  function vector_t create_vec(shortreal x, shortreal y, shortreal z);
    vector_t vec;
    vec.x = $shortrealtobits(x);
    vec.y = $shortrealtobits(y);
    vec.z = $shortrealtobits(z);
    return vec;
  endfunction

endmodule

