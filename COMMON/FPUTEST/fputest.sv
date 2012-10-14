
//`include "../fpumult.v"

/*
 altfp_add (
  aclr,
	clock,
	dataa,
	datab,
	nan,
	overflow,
	result,
	underflow,
	zero);


module altfp_comp (
  aclr,
	clock,
	dataa,
	datab,
	aeb,
	agb);


module altfp_dia (
  aclr,
	clock,
	dataa,
	datab,
	division_by_zero,

	nan,
	overflow,
	result,
	underflow,
	zero);


module altfp_ (
  aclr,
	clock,
	dataa,
	datab,
	nan,
	overflow,
	result,
	underflow,
	zero);
*/


module fputest();
  logic clock;
  logic clk;
  logic aclr;
  
  assign clock = clk;
  
  shortreal dataa_f, datab_f;
  logic [31:0] dataa, datab;
  
  
  logic [31:0] result_add, result_div, result_mult;
  shortreal result_add_f, result_div_f, result_mult_f;


  initial begin
   dataa_f = 0.0;
   datab_f = 0.0;
   clk = 0;
    aclr=0;
    #1 aclr = 1;
    #1 aclr = 0;
    #3;
    #10;
    forever #5 clk = ~clk;
  end

  initial begin
    @(posedge clk);
    dataa_f <= 10.0;
    datab_f <= 0.5;
    for(int i=0; i<8; i++) begin
      @(posedge clk);
      dataa_f <= dataa_f + 1;
      datab_f <= datab_f + 0.5;
    end
    repeat(10) @(posedge clk);
    $finish;
  end


  assign dataa = $shortrealtobits(dataa_f);
  assign datab = $shortrealtobits(datab_f);

  assign result_add_f = $bitstoshortreal(result_add);
  assign result_div_f = $bitstoshortreal(result_div);
  assign result_mult_f = $bitstoshortreal(result_mult);

  // adder flags
  logic nan_add, overflow_add, underflow_add, zero_add;

  // div flags
  logic division_by_zero_div, nan_div, overflow_div, underflow_div, zero_div;

  // mult flags
  logic nan_mult, overflow_mult, underflow_mult, zero_mult;

  altfp_add_sua add1(
  .aclr(aclr ),
  .clock(clock ),
  .dataa(dataa ),
  .datab(datab ),
  .nan(nan_add ),
  .overflow(overflow_add ),
  .result(result_add ),
  .underflow(underflow_add ),
	.zero(zero_add) );

/*
  altfp_comp (
  .clock(clock ),
  .dataa(dataa ),
  .datab(datab ),
  .aeb(aeb ),
	agb);
*/

  altfp_dia div1 (
  .aclr(aclr ),
  .clock(clock ),
  .dataa(dataa ),
  .datab(datab ),
  .division_by_zero(division_by_zero_div ),
  .nan(nan_div ),
  .overflow(overflow_div ),
  .result(result_div ),
  .underflow(underflow_div ),
	.zero(zero_div));


  altfp_mula (
  .aclr(aclr ),
  .clock(clock ),
  .dataa(dataa ),
  .datab(datab ),
  .nan(nan_mult ),
  .overflow(overflow_mult ),
  .result(result_mult ),
  .underflow(underflow_mult ),
	.zero(zero_mult));

endmodule
