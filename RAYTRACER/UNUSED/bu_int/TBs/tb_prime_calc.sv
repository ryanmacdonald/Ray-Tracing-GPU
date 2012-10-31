
module tb_prime_calc();
  logic clk;
  logic rst;

  logic v0, v1, v2;

  int_cacheline_t tri_info_in;
  
  vector_t origin_in;
  vector_t dir_in;

  float_t originp;
  float_t dirp;


  

 

  int_cacheline_t tri_info_in1;
  
  vector_t origin_in1;
  vector_t dir_in1;

  shortreal originp_f;
  shortreal dirp_f;

  always_comb begin
    originp_f = $bitstoshortreal(originp);
    dirp_f = $bitstoshortreal(dirp);
 end

  logic [1:0] cnt, cnt_n;
  
  assign cnt_n = (cnt == 2'b10) ? 2'b0 : cnt + 1'b1 ;
  ff_ar #(2,0) cnt3(.q(cnt), .d(cnt_n), .clk, .rst);
  
  assign v0 = (cnt == 2'b00);
  assign v1 = (cnt == 2'b01);
  assign v2 = (cnt == 2'b10);


  prime_calc inst(.*);
  
  
  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end


  initial begin
    tri_info_in1 = create_int_cacheline('h0,'h0,'h0);
    origin_in1 = create_vec(13.5794,23.3653,-0.9313);
    dir_in1 = create_vec(-3.33333,2.1355,45.8933);
    
    @(posedge clk);
    for(int i=0; i<3; i++) begin
      @(posedge clk)
      if(v2) begin
        tri_info_in <= tri_info_in1;
        origin_in <= origin_in1;
        dir_in <= dir_in1;
      end
      else begin
        tri_info_in <= 'h0;
        origin_in <= 'h0;
        dir_in <= 'h0;
      end
    end
    @(posedge clk);
      tri_info_in <= 'h0;
        origin_in <= 'h0;
        dir_in <= 'h0;
 
    repeat(30) @(posedge clk);
    $finish;
  end


  function vector_t create_vec(shortreal x, shortreal y, shortreal z);
    vector_t vec;
    vec.x = $shortrealtobits(x);
    vec.y = $shortrealtobits(y);
    vec.z = $shortrealtobits(z);
    return vec;
  endfunction


  function int_cacheline_t create_int_cacheline(input vector_t A, input vector_t B, input vector_t C);
    int_cacheline_t c;
    c.matrix.m11 = $shortrealtobits(11);
    c.matrix.m12 = $shortrealtobits(12);
    c.matrix.m13 = $shortrealtobits(13);
    c.matrix.m21 = $shortrealtobits(21);
    c.matrix.m22 = $shortrealtobits(22);
    c.matrix.m23 = $shortrealtobits(23);
    c.matrix.m31 = $shortrealtobits(31);
    c.matrix.m32 = $shortrealtobits(32);
    c.matrix.m33 = $shortrealtobits(33);
    c.translate = create_vec(100,100,100);
    return c;
  endfunction



endmodule
