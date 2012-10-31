
module tb_t_comp();
   logic clk, rst;
   logic v0, v1, v2;
   logic EM_miss_true;

   float_t t_int0; // valid v0
   float_t t_int1; // valid v0

   int_pipe1_t int_pipe1_in; // valid v1

   logic EM_miss;
   ray_t EM_ray;

   int_pipe2_t int_pipe2_out; 
   vector_t p_int;
 
  shortreal t_int0_f;
  shortreal t_int1_f;
  shortreal t_max_f;
  shortreal t_min_f;

  assign EM_miss_true = v2 & EM_miss;

  always_comb begin
    t_int0 = $shortrealtobits(t_int0_f);
    t_int1 = $shortrealtobits(t_int1_f);
    int_pipe1_in.t_max = $shortrealtobits(t_max_f);
    int_pipe1_in.t_min = $shortrealtobits(t_min_f);
  end

  logic [1:0] cnt, cnt_n;
  
  assign cnt_n = (cnt == 2'b10) ? 2'b0 : cnt + 1'b1 ;
  ff_ar #(2,0) cnt3(.q(cnt), .d(cnt_n), .clk, .rst);
  
  assign v0 = (cnt == 2'b00);
  assign v1 = (cnt == 2'b01);
  assign v2 = (cnt == 2'b10);



  t_comp inst(.*);
  
  
  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end


  initial begin
    @(posedge clk);
    
    // t0, t1, tmin, tmax
    set_t(10, 15, 0, 30);
    set_t(10, 3, 0, 30);
    set_t(10, 3, 0, 2);
    set_t(10, 3, 4, 30);
    repeat(30) @(posedge clk);
    $finish;
  end

  shortreal t_into;
  logic t_hito;
  logic t_selo;
  shortreal t_maxo;
  shortreal t_mino;
  ray_t rayo;

  always_comb begin
    t_into = $bitstoshortreal(int_pipe2_out.t_int);
    t_mino = $bitstoshortreal(int_pipe2_out.t_min);
    t_maxo = $bitstoshortreal(int_pipe2_out.t_max);
    t_hito = int_pipe2_out.t_hit;
    t_selo = int_pipe2_out.t_sel;

  end

  task set_t(shortreal t0, shortreal t1, shortreal tmin, shortreal tmax);
     @(posedge v0);
    t_int0_f <= t0;
    t_int1_f <= t1;
    t_max_f <= 0;
    t_min_f <= 0;
    int_pipe1_in.tri1_valid <= 0;
    int_pipe1_in.ray <= 0;

    @(posedge clk);
    t_int0_f <= 0;
    t_int1_f <= 0;
    t_max_f <= tmax;
    t_min_f <= tmin;
    int_pipe1_in.tri1_valid <= 1;
    int_pipe1_in.ray <= {$random} %($bits(ray_t)) ;
     @(posedge clk);
    t_int0_f <= 0;
    t_int1_f <= 0;
    t_max_f <= 0;
    t_min_f <= 0;
    int_pipe1_in.tri1_valid <= 0;
    int_pipe1_in.ray <= 0;


  endtask



endmodule
