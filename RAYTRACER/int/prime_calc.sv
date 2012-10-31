// This module calculates originp and dirp
// latency of 20
// uses 6 multipliers and 5 adders
/*
  Expects a new input on v0.

  Outputs Z then Y then X

*/
/*
`ifndef PRIME_CALC_SV
`define PRIME_CALC_SV
*/


module prime_calc(
  input clk,
  input rst,

  input ray_vec_t ray_vec,
  input float_t mK1, mK2, mK3, // K is 1 for X, 2 for Y and 3 for Z
  input float_t tK, // K is x for x, y for y, z for z
  output float_t originp,
  output float_t dirp
  
  );
  

/*
  Origin matrix multiply and translation
    
  m*origin + translate

  OpX     m11 m12 m13   Ox       Tx
  OpY  =  m21 m22 m23 * Oy   +   Ty
  OpZ     m31 m32 m33   Oz       Tz


*/


  // mult_o1
  float_t inA_mult_o1, inB_mult_o1, out_mult_o1;
  logic nan_mult_o1, overflow_mult_o1, underflow_mult_o1, zero_mult_o1;

  
  // mult_o2
  float_t inA_mult_o2, inB_mult_o2, out_mult_o2;
  logic nan_mult_o2, overflow_mult_o2, underflow_mult_o2, zero_mult_o2;
 
  
  // mult_o3
  float_t inA_mult_o3, inB_mult_o3, out_mult_o3;
  logic nan_mult_o3, overflow_mult_o3, underflow_mult_o3, zero_mult_o3;

  // Translation buffer
  float_t in_Tbuf, out_Tbuf;


  // add_o12
  float_t inA_add_o12, inB_add_o12, out_add_o12;
  logic nan_add_o12, overflow_add_o12, underflow_add_o12, zero_add_o12;


  //add_o3T
  float_t inA_add_o3T, inB_add_o3T, out_add_o3T;
  logic nan_add_o3T, overflow_add_o3T, underflow_add_o3T, zero_add_o3T;

  
  //add_oSum
  float_t inA_add_oSum, inB_add_oSum, out_add_oSum;
  logic nan_add_oSum, overflow_add_oSum, underflow_add_oSum, zero_add_oSum;

  // First Level of tree
  assign inA_mult_o1 = ray_vec.origin.x;
  assign inA_mult_o2 = ray_vec.origin.y;
  assign inA_mult_o3 = ray_vec.origin.z;

  assign inB_mult_o1 = mK1;
  assign inB_mult_o2 = mK2;
  assign inB_mult_o3 = mK3;

  assign in_Tbuf = tK;

  // Second Level of tree
  assign inA_add_o12 = out_mult_o1;
  assign inB_add_o12 = out_mult_o2;

  assign inA_add_o3T = out_mult_o3;
  assign inB_add_o3T = out_Tbuf;

  // Third level of tree
  assign inA_add_oSum = out_add_o12;
  assign inB_add_oSum = out_add_o3T;

  // Output
  assign originp = out_add_oSum;

  
  // Origin Multiplier Instantiations
  
  
  altfp_mult mult_o1 (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_o1),
  .datab(inB_mult_o1),
  .nan(nan_mult_o1 ),
  .overflow(overflow_mult_o1 ),
  .result(out_mult_o1 ),
  .underflow(underflow_mult_o1 ),
	.zero(zero_mult_o1));

   altfp_mult mult_o2 (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_o2),
  .datab(inB_mult_o2),
  .nan(nan_mult_o2 ),
  .overflow(overflow_mult_o2 ),
  .result(out_mult_o2 ),
  .underflow(underflow_mult_o2 ),
	.zero(zero_mult_o2));
 
  altfp_mult mult_o3 (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_o3),
  .datab(inB_mult_o3),
  .nan(nan_mult_o3 ),
  .overflow(overflow_mult_o3 ),
  .result(out_mult_o3 ),
  .underflow(underflow_mult_o3 ),
	.zero(zero_mult_o3));

  
  buf_t3 #(.LAT(5), .WIDTH($bits(float_t))) Tbuf5(
    .clk, .rst,
    .data_in(in_Tbuf),
    .data_out(out_Tbuf) );

  // Origin Adder Instantiations

  altfp_add add_o12(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_o12 ),
  .datab(inB_add_o12 ),
  .nan(nan_add_o12 ),
  .overflow(overflow_add_o12 ),
  .result(out_add_o12 ),
  .underflow(underflow_add_o12 ),
	.zero(zero_add_o12) );


  altfp_add  add_o3T(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_o3T ),
  .datab(inB_add_o3T ),
  .nan(nan_add_o3T ),
  .overflow(overflow_add_o3T ),
  .result(out_add_o3T ),
  .underflow(underflow_add_o3T ),
	.zero(zero_add_o3T) );

  altfp_add add_oSum(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_oSum ),
  .datab(inB_add_oSum ),
  .nan(nan_add_oSum ),
  .overflow(overflow_add_oSum ),
  .result(out_add_oSum ),
  .underflow(underflow_add_oSum ),
	.zero(zero_add_oSum) );





/*
  Dir matrix multiply (no translation)
    
  m*dir

  DpX     m11 m12 m13   Dx
  DpY  =  m21 m22 m23 * Dy
  DpZ     m31 m32 m33   Dz

*/


  // mult_d1
  float_t inA_mult_d1, inB_mult_d1, out_mult_d1;
  logic nan_mult_d1, overflow_mult_d1, underflow_mult_d1, zero_mult_d1;

  
  // mult_d2
  float_t inA_mult_d2, inB_mult_d2, out_mult_d2;
  logic nan_mult_d2, overflow_mult_d2, underflow_mult_d2, zero_mult_d2;
 
  
  // mult_d3
  float_t inA_mult_d3, inB_mult_d3, out_mult_d3;
  logic nan_mult_d3, overflow_mult_d3, underflow_mult_d3, zero_mult_d3;

  // Translation buffer
  float_t in_d3buf7, out_d3buf7;


  // add_d12
  float_t inA_add_d12, inB_add_d12, out_add_d12;
  logic nan_add_d12, overflow_add_d12, underflow_add_d12, zero_add_d12;

  
  //add_dSum
  float_t inA_add_dSum, inB_add_dSum, out_add_dSum;
  logic nan_add_dSum, overflow_add_dSum, underflow_add_dSum, zero_add_dSum;
  
  // First level of tree
  assign inA_mult_d1 = ray_vec.dir.x;
  assign inA_mult_d2 = ray_vec.dir.y;
  assign inA_mult_d3 = ray_vec.dir.z;

  assign inB_mult_d1 = mK1;
  assign inB_mult_d2 = mK2;
  assign inB_mult_d3 = mK3;


  // Second Level of tree
  assign inA_add_d12 = out_mult_d1;
  assign inB_add_d12 = out_mult_d2;
  assign in_d3buf7 = out_mult_d3;

  // Third level of tree
  assign inA_add_dSum = out_add_d12;
  assign inB_add_dSum = out_d3buf7;

  // Output
  assign dirp = out_add_dSum;

   
  // Origin Multiplier Instantiations
  altfp_mult mult_d1 (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_d1),
  .datab(inB_mult_d1),
  .nan(nan_mult_d1 ),
  .overflow(overflow_mult_d1 ),
  .result(out_mult_d1 ),
  .underflow(underflow_mult_d1 ),
	.zero(zero_mult_d1));

   altfp_mult mult_d2 (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_d2),
  .datab(inB_mult_d2),
  .nan(nan_mult_d2 ),
  .overflow(overflow_mult_d2 ),
  .result(out_mult_d2 ),
  .underflow(underflow_mult_d2 ),
	.zero(zero_mult_d2));
 
  altfp_mult mult_d3 (
  .aclr(rst ),
  .clock(clk),
  .dataa(inA_mult_d3),
  .datab(inB_mult_d3),
  .nan(nan_mult_d3 ),
  .overflow(overflow_mult_d3 ),
  .result(out_mult_d3 ),
  .underflow(underflow_mult_d3 ),
	.zero(zero_mult_d3));


  buf_t3 #(.LAT(7), .WIDTH($bits(float_t)) ) d3buf7(
    .clk, .rst,
    .data_in(in_d3buf7),
    .data_out(out_d3buf7) );

  // Origin Adder Instantiations

  altfp_add add_d12(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_d12 ),
  .datab(inB_add_d12 ),
  .nan(nan_add_d12 ),
  .overflow(overflow_add_d12 ),
  .result(out_add_d12 ),
  .underflow(underflow_add_d12 ),
	.zero(zero_add_d12) );


  altfp_add add_dSum(
  .aclr(rst ),
  .clock(clk ),
  .dataa(inA_add_dSum),
  .datab(inB_add_dSum),
  .nan(nan_add_dSum),
  .overflow(overflow_add_dSum),
  .result(out_add_dSum ),
  .underflow(underflow_add_dSum),
	.zero(zero_add_dSum) );



endmodule 


