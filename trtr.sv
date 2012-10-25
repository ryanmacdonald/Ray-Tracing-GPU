`default_nettype none

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

    input logic clk);

    logic sram_we, sram_re;
    logic sram_ub, sram_lb;

	assign sram_we_b = ~sram_we;
	assign sram_oe_b = ~sram_re;
    assign sram_ce_b = 1'b0;
    assign sram_lb_b = ~sram_ub;
    assign sram_ub_b = ~sram_ub;
    assign LEDR = 18'b0;
    assign LEDG[7:0] = 8'b0;

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

	logic stripes_sel;
	assign stripes_sel = switches[0];

	// FBH to pixel buffer
	logic pb_re;
	logic pb_empty;
  pixel_buffer_entry_t pb_data;

  logic pb_we; // from int_wrap
  logic pb_full;

	vector_t E, U, V, W;

	logic start, rayReady, done;
	float_t pw;
	ray_t prg_data;
	
	assign	E.x = $shortrealtobits(2.0), E.y = $shortrealtobits(0), E.z = $shortrealtobits(0),
			U.x = `FP_1, U.y = `FP_0, U.z = `FP_0,
			V.x = `FP_0, V.y = `FP_1, V.z = `FP_0,
			W.x = `FP_0, W.y = `FP_0, W.z = `FP_1;

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
	   .start,
	   .E, .U, .V, .W,
	   .pw,
	   .rayReady, .done,
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


	fifo #(.K(7), .WIDTH($bits(pixel_buffer_entry_t)))
		pb_fifo(.clk, .rst, .data_in(pb_data_in), .we(pb_we), .re(pb_re), .full(pb_full), .empty(pb_empty), .data_out(pb_data));

/*    xmodem               xm(.*);
    scene_loader         sl(.*); */
    frame_buffer_handler fbh(.*);

endmodule
