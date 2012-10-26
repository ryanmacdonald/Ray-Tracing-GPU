`default_nettype none

module frame_buffer_handler(
	// interface with pixel buffer
	output logic pb_re,
	input logic pb_empty,
	input pixel_buffer_entry_t pb_data,
	// sram interface
	output logic sram_re,
	output logic sram_we,
	output logic [19:0] sram_addr,
	inout wire [15:0] sram_io,
	output logic sram_ub, sram_lb,
	// vga interface
	output logic HS, VS,
	output logic VGA_clk,
	output logic VGA_blank,
	output logic [23:0] VGA_RGB,
	//
	input logic stripes_sel,
	input logic clk, rst
);

	logic [19:0] writer_addr, reader_addr;
	logic [15:0] writer_data, reader_data;
	logic writer_ub, writer_lb;
	logic reader_ub, reader_lb;

	assign reader_data = sram_io;

	assign reader_ub = 1'b1;
	assign reader_lb = 1'b1;

	assign sram_io = (sram_we) ? writer_data : 16'bz;
	assign sram_addr = (sram_re) ? reader_addr : writer_addr;
	assign sram_lb = (sram_re) ? reader_lb : writer_lb;
	assign sram_ub = (sram_re) ? reader_ub : writer_ub;

	fbh_writer writer(.*);
	fbh_reader reader(.*);

endmodule: frame_buffer_handler

module fbh_writer(
	// pixel buffer
	output logic pb_re,
	input logic pb_empty,
	input pixel_buffer_entry_t pb_data,
	// SRAM
	output logic sram_we,
	output logic [19:0] writer_addr,
	output logic [15:0] writer_data,
	output logic writer_ub, writer_lb,
	//
	input logic sram_re, // from reader
	input logic clk, rst
);

	logic first_write, second_write;
	assign second_write = ~first_write;

	assign sram_we = ~sram_re & ~pb_empty;
	assign pb_re = second_write & sram_we;

  color_t pb_pixel;
  rayID_t pb_PID;
	logic [18:0] PID_addr0, PID_addr1;
	assign pb_pixel = pb_data.color;
	assign pb_PID = pb_data.rayID;

    assign PID_addr0 = pb_PID + (pb_PID >> 1'b1);
    assign PID_addr1 = PID_addr0+1'b1;

    // TODO: make sure these are not swapped incorrectly
    assign writer_ub = ~pb_PID[0] | second_write;
    assign writer_lb = pb_PID[0] | first_write;

	always_comb begin
		case({first_write,pb_PID[0]})
			2'b00: writer_data = {pb_pixel[7:0],8'b0};
			2'b01: writer_data = pb_pixel[15:0];
			2'b10: writer_data = pb_pixel[23:8];
			2'b11: writer_data = {8'b0,pb_pixel[23:16]};
		endcase
	end

//	assign writer_data = (first_write) ? (() ? pb_pixel[23:8] : )  : pb_pixel[15:0];
	assign writer_addr = (first_write) ? {1'b0, PID_addr0} : {1'b0, PID_addr1}; // TODO: MSB should be 

	ff_ar_en #(1,1'b1) first_write_ff(.q(first_write), .d(~first_write), .en(sram_we), .clk, .rst);

endmodule: fbh_writer

module fbh_reader(
	// to VGA
	output logic HS, VS,
	output logic VGA_clk,
	output logic VGA_blank,
	output logic [23:0] VGA_RGB,
	// to/from SRAM
	output logic sram_re,
	output logic [19:0] reader_addr,
	input logic [15:0] reader_data,
	//
	input logic stripes_sel,
	input logic clk, rst
);

	// vga controller
    logic display_done;
    logic [9:0] vga_row;
    logic [9:0] vga_col;
    logic clk_25M;
    logic clk_50M;
	assign clk_50M = clk;
	vga vc(.*);	

	// fbh_active
  logic row_on_screen;
	logic fbh_active, flip_active_on, flip_active_off;
	assign flip_active_on = (vga_col == 10'h3fe & row_on_screen);
	assign flip_active_off = (vga_col == 10'h27e);
	ff_ar_en #(1,1'b0) fbh_active_ff(.q(fbh_active), .d(flip_active_on), .en(flip_active_on | flip_active_off), .clk, .rst);

  range_check #(.W(10)) row_rc(
    .is_between(row_on_screen),
    .val(vga_row), .low(10'd0), .high(10'd479));

	logic [3:0] abc_sr_q;
	logic [15:0] a_q, b_q, c_q;
	logic a_en, b_en, c_en;
	logic [2:0] stripes_color;

	// address counter
	logic addr_cnt_inc, addr_cnt_clr;
	assign addr_cnt_inc = fbh_active & (a_en | b_en | c_en);
	assign addr_cnt_clr = (vga_row == 10'd0 && vga_col == 10'h3fd);
	counter #(20,20'd0) addr_counter(.cnt(reader_addr), .inc(addr_cnt_inc), .clr(addr_cnt_clr), .clk, .rst);

	shifter #(4,4'b100) abc_sr(.q(abc_sr_q), .d(abc_sr_q[0]), .en(fbh_active), .clr(addr_cnt_clr), .clk, .rst);

	// a, b, and c registers
	assign a_en = abc_sr_q[2];
	assign b_en = abc_sr_q[1];
	assign c_en = abc_sr_q[0];
	assign sram_re = (a_en | b_en | c_en) & fbh_active;

	ff_ar_en #(16,16'd0) a_reg(.q(a_q), .d(reader_data), .en(a_en), .clk, .rst); // first two bytes of first pixel
	ff_ar_en #(16,16'd0) b_reg(.q(b_q), .d(reader_data), .en(b_en), .clk, .rst); // third byte of first and first byte of second
	ff_ar_en #(16,16'd0) c_reg(.q(c_q), .d(reader_data), .en(c_en), .clk, .rst); // last two bytes of second pixel

	// pixel mux
	logic pixel_mux_sel;
	logic flip_pixel_mux_sel;
	assign flip_pixel_mux_sel = (a_en | c_en) & fbh_active;

	ff_ar_en #(1,1'b0) pixel_mux_sel_ff(.q(pixel_mux_sel), .d(~pixel_mux_sel), .en(flip_pixel_mux_sel), .clk, .rst);

	// pixel reg
	logic [23:0] pixel_reg_q, pixel_reg_d;
	assign pixel_reg_d = (pixel_mux_sel) ? {b_q[7:0],a_q} : {c_q,b_q[15:8]} ;
	ff_ar_en #(24,24'd0) pixel_reg(.q(pixel_reg_q), .d(pixel_reg_d), .en(flip_pixel_mux_sel), .clk, .rst);

	stripes stripes_inst(.vga_color(stripes_color), .vga_row, .vga_col);

	// VGA output
	assign VGA_RGB = (stripes_sel) ? { stripes_color[2],7'b0, stripes_color[1],7'b0, stripes_color[0],7'b0} : pixel_reg_q;

endmodule: fbh_reader
