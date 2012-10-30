

module tb_pipe_vs();
  logic clk, rst;

  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk ;
  end
  
  

  logic valid_out;
  logic stall_in;


   logic us_valid;
   logic [7:0] us_data;
   logic us_stall;

   logic ds_valid;
   logic [7:0] ds_data;
   logic ds_stall;

   logic [4:0] num_in_fifo;
 
 	logic	  clock;
	logic	[7:0]  data;
	logic	  rdreq;
	logic	  wrreq;
	logic	  empty;
	logic	  full;
	logic	[7:0]  q;
	logic	[4:0]  usedw;


   assign num_in_fifo = usedw;
 
  assign valid_out = ~empty;
  assign rdreq = valid_out & ~stall_in ;
  assign wrreq = ~full & ds_valid;
  assign ds_stall = stall_in;
  assign data = ds_data ;
 


  assign clock = clk;
    int a=0;
  pipe_valid_stall #(8,16) pipe(.*);
  fifo16 fifo(.*);
  
  
  task rand_valid_us(int num); // use us_valid and us_stall
    logic n;
    @(posedge clk);
    for(int i=0; i<num; i++) begin
      n = {$random}%2;
      us_valid <= n;
      us_data <= n ? i : 'hX;
      @(posedge clk);
      while(us_valid & us_stall) @(posedge clk) ;
    end
  endtask

  task rand_stall_ds(); // use stall_in and valid_out
    
    int a=0;
    logic n;
    @(posedge clk);
    while(1)begin
      n = {$random}%5 ;
      if(valid_out && n) begin
        stall_in <= 1;
        repeat(1+{$random}%6) @(posedge clk);
        stall_in <= 0;
      end
      @(posedge clk);
    end

  endtask

      
      
  initial begin
    us_valid = 0;
    us_data = 'hX;
    stall_in = 0;
    @(posedge clk);
    fork
      rand_valid_us(100);
      rand_stall_ds();
    join_any
    @(posedge clk);
    us_valid <= 0;
    us_data <= 0;
    repeat(50) @(posedge clk) ;
    $finish;
  end

  int num_in;
  int num_out;

  initial begin
    num_in = 0;
    num_out = 0;
  end

  always @(posedge clk) begin
    if(us_valid & ~us_stall) num_in ++;
    if(valid_out & ~stall_in) num_out++;
  end

  final begin
    $display("num_in=%d, num_out=%d",num_in, num_out);
  end

endmodule
      
