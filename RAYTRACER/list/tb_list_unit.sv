module tb_list_unit;

  logic clk, rst;
  
  logic trav0_to_list_valid;
  trav_to_list_t trav0_to_list_data;
  logic trav0_to_list_stall;

  logic trav1_to_list_valid;
  trav_to_list_t trav1_to_list_data;
  logic trav1_to_list_stall;

  logic int_to_list_valid;
  int_to_list_t int_to_list_data;
  logic int_to_list_stall;

  logic list_to_ss_valid;
  list_to_ss_t list_to_ss_data;
  logic list_to_ss_stall;

  logic list_to_rs_valid;
  list_to_rs_t list_to_rs_data;
  logic list_to_rs_stall;

  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end


  list_unit list_inst(.*);

  initial begin
    trav0_to_list_valid = 0;
    trav0_to_list_data = 'hX;
    // fill up t_max_leaf with all odd rayIDs 
    for(int i=0; i<60; i+=2) begin
      trav0_to_list_valid <= 1;
      trav0_to_list_data.rayID <= i;
      trav0_to_list_data.t_max_leaf <= to_bits(i);
      @(posedge clk);
      while(trav0_to_list_stall) @(posedge clk);
    end
    trav0_to_list_valid <= 0;
    trav0_to_list_data <= 'hX;
  end

  initial begin
    trav1_to_list_valid = 0;
    trav1_to_list_data = 'hX;
    // fill up t_max_leaf with all odd rayIDs 
    for(int i=1; i<60; i+=2) begin
      trav1_to_list_valid <= 1;
      trav1_to_list_data.rayID <= i;
      trav1_to_list_data.t_max_leaf <= to_bits(i);
      @(posedge clk);
      while(trav1_to_list_stall) @(posedge clk);
    end
    trav1_to_list_valid <= 0;
    trav1_to_list_data <= 'hX;
  end


  task send_int_to_list(int rayID, int triID, bit hit, bit is_last, shortreal t_int, shortreal u, shortreal v);
    int_to_list_valid <= 1'b1;
    int_to_list_data.ray_info.rayID <= rayID;
    int_to_list_data.ray_info.is_shadow <= 0;
    int_to_list_data.triID <= triID ;
    int_to_list_data.hit <= hit ;
    int_to_list_data.is_last <= is_last ;
    int_to_list_data.t_int <= to_bits(t_int) ;
    int_to_list_data.uv.u <= to_bits(u) ;
    int_to_list_data.uv.v <= to_bits(v) ;
    @(posedge clk);
    while(int_to_list_stall) @(posedge clk);
  endtask


  initial begin
    int_to_list_valid = 0;
    int_to_list_data = 'hX;
    repeat(30) @(posedge clk);
    send_int_to_list(9,3,1,0,5,0.2,0.3);
    send_int_to_list(10,0,0,1,-10,-1,-2);
    send_int_to_list(8,6,1,0,10,0.8,0.1);
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
    repeat(30) @(posedge clk);
    send_int_to_list(9,4,1,1,5.5,0.2,0.3);
    send_int_to_list(8,0,0,1,-2,-2,-2);
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
    repeat(20) @(posedge clk);
    trav0_to_list_valid <= 1;
    trav0_to_list_data.rayID <= 8;
    trav0_to_list_data.t_max_leaf <= to_bits(13);
    @(posedge clk);
    while(trav1_to_list_stall) @(posedge clk);
    trav0_to_list_valid <= 0;
    trav0_to_list_data.rayID <= 'hX;
    repeat(20) @(posedge clk);
    send_int_to_list(8,0,0,1,-2,-2,-2);
    int_to_list_valid <= 0;
    int_to_list_data <= 'hX;
    repeat(30) @(posedge clk);
    $finish;
  end


  int i;
  initial begin
    
    forever @(posedge clk) begin
      i = {$random}%2;
    end
  end

  always_comb begin
    if(i & list_to_ss_valid ) list_to_ss_stall = 1;
    else list_to_ss_stall = 0;
    if((!i) & list_to_rs_valid) list_to_rs_stall = 1;
    else list_to_rs_stall = 0;
  end
  


  function float_t to_bits(shortreal a);
    return $shortrealtobits(a);
  endfunction


endmodule
