`default_nettype none

`define SYNTH

module trtr(
	// general IO
    output logic [17:0] LEDR,
    output logic [8:0] LEDG,
    input logic [17:0] switches,
    input logic [3:0] btns,

	// RS-232/UART
    output logic tx, rts,
    input logic rx_pin,

	// VGA
	output logic HS, VS,
	output logic [23:0] VGA_RGB,
	output logic VGA_clk,
	output logic VGA_blank,

	// SRAM
    output logic [19:0] sram_addr,
    inout wire [15:0] sram_io,
    output logic sram_we_b,
    output logic sram_oe_b,
    output logic sram_ce_b,
    output logic sram_ub_b,
    output logic sram_lb_b,

	 // PS2
	 inout PS2_CLK,
	 inout PS2_DAT,
	 
    input logic clk);

    logic sram_we, sram_re;
    logic sram_ub, sram_lb;

	assign sram_we_b = ~sram_we;
	assign sram_oe_b = ~sram_re;
    assign sram_ce_b = 1'b0;
    assign sram_lb_b = ~sram_ub;
    assign sram_ub_b = ~sram_ub;
    //assign LEDR = 18'b0;
    assign LEDG[7:1] = 7'b0;

    logic start_btn, rst;
//    logic done;

    assign rst = ~btns[3];
    assign start_btn = btns[0];
//    assign LEDG[8] = done;

	// xmodem to scene_loader
    logic saw_valid_block;
    logic saw_valid_msg_byte;
    logic [7:0] data_byte;
    logic [7:0] sl_block_num;

    // scene_loader to SDRAM
    logic [19:0] sl_addr;
    logic [15:0] sl_io;
    logic sl_we;

	// FBH
	logic fbh_re;
	logic fbh_we;
	logic [19:0] fbh_addr;
	wire [15:0] fbh_io;
	logic stripes_sel;

	assign stripes_sel = switches[0];

	// FBH to pixel buffer
	logic pb_re;
	logic pb_empty;
  pixel_buffer_entry_t pb_data;

  logic pb_we; // from int_wrap
  logic pb_full;
  
  // CAMERA CONTROLLER INTERFACE
  logic rendering_done, render_frame;

  
  
	logic [32:0] shift_data;
	logic ps2_clk, ps2_data;
   logic ps2_data_out, ps2_clk_out;
   logic clk_en, data_en, pkt_rec;
	logic[7:0] data_pkt_HD;
	
 //assign data_pkt_HD = 8'hFF ;
	
  assign ps2_clk = clk_en ? 1'b1 : PS2_CLK ;
  assign ps2_data = data_en ? 1'b1 : PS2_DAT ;
  assign PS2_CLK = clk_en ? ps2_clk_out : 1'bZ ;
  assign PS2_DAT = data_en ? ps2_data_out : 1'bZ ;
	
	keys_t keys; // Keys packet from PS/2 
  
  logic [19:0] render_cnt, render_cnt_n;
  
	assign rendering_done = (render_cnt == 20'd307200);
  assign render_cnt_n = (render_cnt == 20'd307200) ? 20'h0 : (pb_we ? render_cnt + 1'b1 : render_cnt);
  
  ff_ar #(20,0) rc(.q(render_cnt),.d(render_cnt_n),.clk,.rst);
  
    always_ff @(posedge pkt_rec) begin
		LEDR[10:0] <= shift_data[32:22];
	 end
  
	  ps2_parse ps2_parse1(.clk(clk), .rst_b(~rst),
								  .ps2_pkt_DH(shift_data[30:23]),
								  .rec_ps2_pkt(pkt_rec), .keys);
  
    ps2 ps21(.iSTART(start), .iRST_n(~rst),
			  .iCLK_50(clk), .ps2_clk(ps2_clk),
			  .ps2_data(ps2_data), .ps2_clk_out(ps2_clk_out),
			  .ps2_dat_out(ps2_data_out), .ce(clk_en), .de(data_en),
			  .shift_reg(shift_data), .pkt_rec(pkt_rec), .cnt11());
  
	vector_t E, U, V, W;

	logic start, rayReady, done;
	float_t pw;
	ray_t prg_data;
	//x = fp 3, y = 3, z = -3
	`ifndef SYNTH
	assign E.x = 32'h40400000, E.y = 32'h40400000, E.z = 32'hC1700000,
			U.x = `FP_1, U.y = `FP_0, U.z = `FP_0,
			V.x = `FP_0, V.y = `FP_1, V.z = `FP_0,
			W.x = `FP_0, W.y = `FP_0, W.z = `FP_1;
	`endif
	assign pw = 32'h3C4CCCCD;

  
  logic [1:0] cnt, cnt_n;
	logic v0, v1, v2;
  
  assign cnt_n = (cnt == 2'b10) ? 2'b0 : cnt + 1'b1 ;
  ff_ar #(2,0) cnt3(.q(cnt), .d(cnt_n), .clk, .rst);
  
  assign v0 = (cnt == 2'b00);
  assign v1 = (cnt == 2'b01);
  assign v2 = (cnt == 2'b10);

  negedge_detector start_ned(.ed(start), .in(start_btn), .clk, .rst);

  pixel_buffer_entry_t pb_data_in;
	
	prg prg_inst(.clk, .rst,
	   .v0, .v1, .v2,
	   .start(render_frame),
	   .E, .U, .V, .W,
	   .pw,
	   .rayReady(rayReady), .done,
	   .prg_data);

	int_wrap int_wrap_inst(
  .clk,
  .rst,
  .valid_in(rayReady),
  .ray_in(prg_data),
  .v0(v1), .v1(v2), .v2(v0),
  .we(pb_we),
  .full(pb_full),
  .pixel_entry_out(pb_data_in)
  );
 
  camera_controller cc(.*);
  
	assign LEDG[0] = render_frame;


	fifo #(.DEPTH(1024), .WIDTH($bits(pixel_buffer_entry_t)))
		pb_fifo(.clk, .rst, .data_in(pb_data_in), .we(pb_we), .re(pb_re), .full(pb_full), .empty(pb_empty), .data_out(pb_data));

/*    xmodem               xm(.*);
    scene_loader         sl(.*); */
    frame_buffer_handler fbh(.*);

endmodule
