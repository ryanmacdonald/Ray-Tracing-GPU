//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	DE2_115_PS2 Mouse Controller 
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author                    :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny FAN,HdHuang        :| 05/16/10  :| Initial Revision
// --------------------------------------------------------------------
module ps2(
           iSTART,   //press the button for transmitting instrucions to device;
           iRST_n,   //FSM reset signal;
           iCLK_50,  //clock source;
           ps2_clk,  //ps2_clock signal inout;
           ps2_data,  //ps2_data  signal inout;
           ps2_clk_out,
			  ps2_dat_out,
			  ce, de,
			  shift_reg, pkt_rec, cnt11
           ); 
           //interface;
//=======================================================
//  PORT declarations
//=======================================================

input iSTART;
input iRST_n;
input iCLK_50;

input ps2_clk;
input ps2_data;
output ps2_clk_out;
output ps2_dat_out;
output reg ce, de;
output reg [32:0] shift_reg;
output reg pkt_rec;
output reg [3:0] cnt11;

parameter enable_byte =9'b111111111;


//=======================================================
//  REG/WIRE declarations
//=======================================================
reg [1:0] cur_state,nex_state;
reg [3:0] byte_cnt,delay;
reg [5:0] ct;
reg [7:0] x_latch,y_latch,cnt;
reg [8:0] clk_div;
reg [9:0] dout_reg;
reg       leflatch,riglatch,midlatch;
reg       ps2_clk_in,ps2_clk_syn1,ps2_dat_in,ps2_dat_syn1;
wire      clk,ps2_dat_syn0,ps2_clk_syn0,flag;



//=======================================================
//  PARAMETER declarations
//=======================================================
//state define
parameter listen =2'b00,
          pullclk=2'b01,
          pulldat=2'b10,
          trans  =2'b11;
          
//=======================================================
//  Structural coding
//=======================================================          
//clk division, derive a 97.65625KHz clock from the 50MHz source;

always@(posedge iCLK_50)
	begin
		clk_div <= clk_div+1;
	end
	
assign clk = clk_div[8];
wire clk_div5;
reg ps2_clk_scew;
assign clk_div5 = clk_div[4];
//tristate output control for PS2_DAT and PS2_CLK;
assign ps2_clk_out = 1'b0;
assign ps2_dat_out = dout_reg[0];
assign ps2_clk_syn0 = ps2_clk;
assign ps2_dat_syn0 = ps2_data;
//
always @(posedge clk_div5) begin
  ps2_clk_scew <= ps2_clk_syn0;
end

//multi-clock region simple synchronization
always@(posedge clk)
	begin
		ps2_clk_syn1 <= ps2_clk_syn0;
		ps2_clk_in   <= ps2_clk_syn1;
		ps2_dat_syn1 <= ps2_dat_syn0;
		ps2_dat_in   <= ps2_dat_syn1;
	end
//FSM shift
always@(*)
begin
   case(cur_state)
     listen  :begin
              if ((iSTART) && (cnt == 8'b11111111))
                  nex_state = pullclk;
              else
                  nex_state = listen;
                         ce = 1'b0;
                         de = 1'b0;
              end
     pullclk :begin
              if (delay == 4'b1100)
                  nex_state = pulldat;
              else
                  nex_state = pullclk;
                         ce = 1'b1;
                         de = 1'b0;
              end
     pulldat :begin
                  nex_state = trans;
                         ce = 1'b1;
                         de = 1'b1;
              end
     trans   :begin
              if  (byte_cnt == 4'b1010)
                  nex_state = listen;
              else    
                  nex_state = trans;
                         ce = 1'b0;
                         de = 1'b1;
              end
     default :    nex_state = listen;
   endcase
end
//idle counter
always@(posedge clk)
begin
  if ({ps2_clk_in,ps2_dat_in} == 2'b11)
	begin
		cnt <= cnt+1;
    end
  else begin
		cnt <= 8'd0;
       end
end
//periodically reset ct; ct counts the received data length;
assign flag = (cnt == 8'hff)?1:0;
always@(posedge ps2_clk_in,posedge flag)
begin
  if (flag)
     ct <= 6'b000000;
  else
     ct <= ct+1;
end


//pull ps2_clk low for 100us before transmit starts;
always@(posedge clk)
begin
  if (cur_state == pullclk)
     delay <= delay+1;
  else
     delay <= 4'b0000;
end
//transmit data to ps2 device;eg. 0xF4
always@(negedge ps2_clk_in)
begin
  if (cur_state == trans)
     dout_reg <= {1'b0,dout_reg[9:1]};
  else
     dout_reg <= {enable_byte,1'b0};
end
//transmit byte length counter
always@(negedge ps2_clk_in)
begin
  if (cur_state == trans)
     byte_cnt <= byte_cnt+1;
  else
     byte_cnt <= 4'b0000;
end
//receive data from ps2 device;
always@(negedge ps2_clk_in)
begin
  if (cur_state == listen)
     shift_reg <= {ps2_dat_in,shift_reg[32:1]};
end

//reg [3:0] cnt11;
reg clr_cnt11;

always@(posedge ps2_clk_scew, negedge iRST_n)
begin
	if(~iRST_n) cnt11 <= 4'h0;
	else if(clr_cnt11 | (cur_state!=listen)) cnt11 <= 4'h0;
	else cnt11 <= cnt11 + 4'h1 ;
end

reg [2:0] cs, ns;
always @(*) begin
  pkt_rec = 1'b0;
  clr_cnt11 = 1'b0;
  ns = 2'b00;
  case(cs)
    3'b000: begin
      ns = (cnt==1) ? 3'b001 : 3'b000 ;
    end
    3'b001: begin
      ns = (cnt11==4'ha) ? 3'b010 : 3'b001 ;
    end
    3'b010: begin
      ns = (ps2_clk_scew) ? 3'b010 : 3'b011;
    end
    3'b011: begin
      ns = (ps2_clk_scew) ? 3'b100 : 3'b011;
		clr_cnt11 = 1'b1;
    end
	 3'b100 : begin
	   pkt_rec = 1'b1;
	 end
    default : ;
  endcase
end

always@(posedge iCLK_50, negedge iRST_n) begin
  if(~iRST_n) cs = 3'b000;
  else cs = ns;
end

//FSM movement
always@(posedge clk,negedge iRST_n)
begin
  if (!iRST_n)
     cur_state <= listen;
  else
     cur_state <= nex_state;
end
endmodule


     


     


