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

	assign sram_we_b = ~sram_we;
	assign sram_oe_b = ~sram_re;
    assign sram_ce_b = 1'b0;
    assign sram_lb_b = 1'b0; // TODO: fbh should muck with these
    assign sram_ub_b = 1'b0;
    assign LEDR = 18'b0;
    assign LEDG[7:0] = 7'b0;

    logic start_btn, rst;
    logic done;

    assign rst = ~btns[3];
    assign start_btn = btns[0];
    assign LEDG[8] = done;

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
	logic [$bits(pixel_buffer_entry_t)] pb_data;

	prg(clk, rst,
	   v0, v1, v2,
	   start,
	   vector_t E, U, V, W,
	   pw,
	   rayReady, done,
	   ray_t prg_data);

	int_wrap(
  clk,
  rst,
  valid_in,
  ray_in,
  v0, v1, v2,
  we,
  full,
  rayID,
  color_out
  );


	fifo #(.K(7), .WIDTH($bits(pixel_buffer_entry_t))
		pb_fifo(.clk, .rst, .data_in(), .we(), .re(pb_re), .full(), .empty(pb_empty), .data_out(pb_data));

    xmodem               xm(.*);
    scene_loader         sl(.*);
    frame_buffer_handler fbh(.*);

endmodule
