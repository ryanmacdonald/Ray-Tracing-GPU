

// Demos scene_int, camera, prg, vga, and ps2

module pipedemo(
    // LEDS/SWITCHES
    output logic [17:0] LEDR,
    output logic [8:0] LEDG,
    input logic [17:0] switches,
    input logic [3:0] btns,

    // VGA
    output logic HS, VS,
    output logic [23:0] VGA_RGB,
    output logic VGA_clk,
    output logic VGA_blank,

    // SRAM
    output logic sram_oe_b,
    output logic sram_we_b,
    output logic sram_ce_b,
    output logic [19:0] sram_addr,
    inout wire [15:0] sram_io,
    output logic sram_ub_b, sram_lb_b,

    // PS2
    inout PS2_CLK,
    inout PS2_DAT,

     
    input logic clk);

	
  
  logic rst;
	assign rst = ~btns[3];
	logic v0, v1, v2;

  logic [711:0] shift_in;

  logic [139:0] shift_out;

  shifter #(712, 'h0) inputs(.d(switches[0]),.q(shift_in),.en(switches[1]),.clr(1'b0), .clk, .rst);
  
  shifter2 #(140, 'h0) outputs(.d(shift_out),.q(LEDR[0]),.shift(switches[2]),.ld(switches[3]), .clk, .rst);
  
  logic render_frame; 
  AABB_t sceneAABB;   
  vector_t E, U, V, W; 
  logic[`numcaches-1:0] readValid_out; 
  logic[`numcaches-1:0][31:0] readData; 
  logic[`numcaches-1:0] doneRead;
  logic pb_full;

  assign render_frame = shift_in[0];
  assign sceneAABB = shift_in[192:1];
  assign E = shift_in[288:193] ;
  assign U = shift_in[384:289] ;
  assign V = shift_in[480:385] ;
  assign W = shift_in[576:481] ;
  //assign = shift_in[608:577] ;
  assign readValid_out = shift_in[611:609] ;
  assign readData = shift_in[707:612] ;
  assign doneRead = shift_in[710:708] ;
  assign pb_full = shift_in[711] ;

  

  logic[`numcaches-1:0][24:0] addr_cache_to_sdram;
  logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize;
  logic[`numcaches-1:0] readReq;
  logic pb_we;
  pixel_buffer_entry_t pb_data_out;

  //initial $display($bits({addr_cache_to_sdram,transSize,readReq,pb_we,pb_data_out}));
  assign shift_out = {addr_cache_to_sdram,transSize,readReq,pb_we,pb_data_out};

  raypipe rp(.*); 
 
	logic[1:0] cnt, cnt_n;
	assign cnt_n = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(cnt_n),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

endmodule: pipedemo
