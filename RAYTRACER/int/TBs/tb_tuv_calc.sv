
/*
  This will provide a ray and see if it intersects

*/

module tb_tuv_calc();


  logic clk, rst;
  logic v0, v1, v2;

  float_t dirp;
  float_t originp;

  float_t t_intersect;

  logic bari_hit;
  bari_uv_t uv;


  shortreal originp_f;
  shortreal dirp_f;
  shortreal t_intersect_f;
  shortreal u_f, v_f;

  always_comb begin
    originp_f = $bitstoshortreal(originp);
    dirp_f = $bitstoshortreal(dirp);
    t_intersect_f = $bitstoshortreal(t_intersect);
    u_f = $bitstoshortreal(uv.u);
    v_f = $bitstoshortreal(uv.v);
  end

  logic [1:0] cnt, cnt_n;
  
  assign cnt_n = (cnt == 2'b10) ? 2'b0 : cnt + 1'b1 ;
  ff_ar #(2,0) cnt3(.q(cnt), .d(cnt_n), .clk, .rst);
  
  assign v0 = (cnt == 2'b00);
  assign v1 = (cnt == 2'b01);
  assign v2 = (cnt == 2'b10);


  tuv_calc inst(.*);
  
  
  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end


  initial begin
    dirp = 'h0;
    originp = 'h0;
    @(posedge clk);

    send_prime_ray(0.2,0.2,3, 0,0,-1);
    send_prime_ray(0,0,3, 0.6,0.3,-3);
    send_prime_ray(0,0,3, 1.2,0.6,-6);
    send_prime_ray(0,0,3, 0.6,0.3,-1);
    send_prime_ray(0,0,10, 0.025,0.01,-1);
    send_prime_ray(0,0,10, 0.25,0.01,-1);
    @(posedge clk);
    dirp <= 'h0;
    originp <= 'h0;
    repeat(40) @(posedge clk);
    $finish;
  end


  task send_prime_ray(shortreal ox, shortreal oy, shortreal oz, shortreal dx, shortreal dy, shortreal dz);
    @(posedge v0);
    dirp <= $shortrealtobits( dz);
    originp <= $shortrealtobits( oz);
    @(posedge clk);
    dirp <= $shortrealtobits( dy);
    originp <= $shortrealtobits( oy);
    @(posedge clk);
    dirp <= $shortrealtobits( dx);
    originp <= $shortrealtobits( ox);

  endtask


endmodule
