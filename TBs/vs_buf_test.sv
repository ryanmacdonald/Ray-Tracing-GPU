module test();
    
  parameter WIDTH = 8;

  logic clk, rst;
  logic valid_us;
  logic [WIDTH-1:0] data_us;
  logic stall_us;

  logic valid_ds;
  logic [WIDTH-1:0] data_ds;
  logic stall_ds;
  
  initial begin
    clk = 0;
    rst=0;
    #1 rst=1;
    #1 rst=0;
    #3;
    forever #5 clk = ~clk;
  end

  
  initial begin
  stall_ds = 0;
  valid_us = 0;
  data_us = 'hX;
    @(posedge clk);
    fork
      begin
        @(posedge clk) stall_ds <= 0;
        @(posedge clk) stall_ds <= 1;
        @(posedge clk) stall_ds <= 0;
        @(posedge clk) stall_ds <= 0;
        @(posedge clk) stall_ds <= 0;
        @(posedge clk) stall_ds <= 1;
        @(posedge clk) stall_ds <= 1;
        @(posedge clk) stall_ds <= 0;
        @(posedge clk) stall_ds <= 0;
        @(posedge clk) stall_ds <= 1;
        @(posedge clk) stall_ds <= 1;
        @(posedge clk) stall_ds <= 0;
      end
      begin
        @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hA;
        end
        @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hB;
        end
       @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hC;
        end
       @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hC;
        end
       @(posedge clk) begin
          valid_us <= 0;
          data_us <= 'hx;
        end
       @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hD;
        end
       @(posedge clk) begin
          valid_us <= 0;
          data_us <= 'hX;
        end
       @(posedge clk) begin
          valid_us <= 0;
          data_us <= 'hX;
        end
       @(posedge clk) begin
          valid_us <= 0;
          data_us <= 'hX;
        end
       @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hE;
        end
       @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hF;
        end
        @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hF;
        end 
        @(posedge clk) begin
          valid_us <= 1;
          data_us <= 'hF;
        end 
        @(posedge clk) begin
          valid_us <= 0;
          data_us <= 'hX;
        end
     end
    join
    repeat(10) @(posedge clk);
    $finish;
  end




  VS_buf #(8) inst(.*);
  





endmodule

module VS_buf #(parameter WIDTH = 8) (
  input logic clk, rst,
  input logic valid_us,
  input logic [WIDTH-1:0] data_us,
  output logic stall_us,

  output logic valid_ds,
  output logic [WIDTH-1:0] data_ds,
  input logic stall_ds );

  logic stall;
  logic tmp_valid, tmp_valid_n;
  logic [7:0] tmp_data, tmp_data_n;

  


//  `ifdef SYNTH
  assign data_ds = tmp_valid ? tmp_data : (valid_us ? data_us : 'hX) ;
  assign valid_ds = tmp_valid | valid_us ;
  assign stall_us = stall & valid_us;
//  `else
  always_comb begin // stall_ds assumes that valid_ds is asserted
    case({stall_ds, stall})
      2'b00 : tmp_data_n = 'hX;
      2'b10 : tmp_data_n = valid_ds ? data_us : 'hX ;
      2'b01 : tmp_data_n = 'hX ;
      2'b11 : tmp_data_n = tmp_valid ? tmp_data : 'hX ;
    endcase
    case({stall_ds, stall})
      2'b00 : tmp_valid_n = 0;
      2'b10 : tmp_valid_n = valid_us ? 1 : 0 ;
      2'b01 : tmp_valid_n =  0 ;
      2'b11 : tmp_valid_n = tmp_valid ? 1 : 0 ;
    endcase
  end
//  `endif

  always_ff @(posedge clk, posedge rst) begin
    if(rst) begin
      stall <= 0;
      tmp_valid <= 'h0;
      tmp_data <= 0;
    end
    else begin
      stall <= stall_ds;
      tmp_valid <= tmp_valid_n;
      tmp_data <= tmp_data_n;
    end
  end

endmodule
