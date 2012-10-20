/* This has the 3 types of buffers  
  t3: data 3/3 of clocks
  t2: data 2/3 of clocks
  t1: data 1/3 of clocks
*/

`ifndef BUF_T_SV
`define BUF_T_SV

module buf_t1 #(LAT = 10, WIDTH = 10) (
  input logic clk,
  input logic rst,
  input logic v0,

  input logic[WIDTH-1:0] data_in,
  output logic[WIDTH-1:0] data_out
  );

  localparam NUMREGS = (LAT+2)/3; // CEILING of LAT/3

  logic[NUMREGS-1:0][WIDTH-1:0] data_buf, data_buf_n;

  assign data_out = data_buf[NUMREGS-1];

  

  always_ff @(posedge clk, posedge rst) begin
    if(rst) data_buf <= 'h0;
    else if(v0) data_buf <= {data_buf[NUMREGS-2:0], data_in} ;
  end

endmodule


module buf_t3 #(LAT = 10, WIDTH = 10) (
  input logic clk,
  input logic rst,

  input logic[WIDTH-1:0] data_in,
  output logic[WIDTH-1:0] data_out
  );

  logic[LAT-1:0][WIDTH-1:0] data_buf;
  assign data_out = data_buf[LAT-1];

  always_ff @(posedge clk, posedge rst) begin
    if(rst) data_buf <= 'h0;
    else data_buf <= {data_buf[LAT-2:0],data_in};
  end

endmodule

`endif
