`default_nettype none

module simple_frame_buffer_handler(
    // interface with pixel buffer
    output logic pb_re,
    input logic [2:0] scale,
    input logic pb_empty,
    input pixel_buffer_entry_t pb_data,
    // sram interface
    output logic sram_oe_b,
    output logic sram_we_b,
    output logic sram_ce_b,
    output logic [19:0] sram_addr,
    inout wire [15:0] sram_io,
    output logic sram_ub_b, sram_lb_b,
    // vga interface
    output logic HS, VS,
    output logic VGA_clk,
    output logic VGA_blank,
    output logic [23:0] VGA_RGB,
    //
    input logic stripes_sel,
    input logic clk, rst
);

    logic sram_re_b;
    assign sram_oe_b = sram_re_b;

    assign sram_ce_b = 1'b0;

    logic [19:0] writer_addr, reader_addr;
    logic [15:0] writer_data, reader_data;
    logic writer_ub, writer_lb;
    logic reader_ub, reader_lb;

    assign reader_data = sram_io;

    assign reader_ub = 1'b1;
    assign reader_lb = 1'b1;

    assign sram_io = (~sram_we_b) ? writer_data : 16'bz;
    assign sram_addr = (~sram_re_b) ? reader_addr : writer_addr;
    assign sram_lb_b = (~sram_re_b) ? ~reader_lb : ~writer_lb;
    assign sram_ub_b = (~sram_re_b) ? ~reader_ub : ~writer_ub;

	fbh_writer writer(.*);
	fbh_reader reader(.*);

endmodule

module fbh_writer(
    // pixel buffer
    output logic pb_re,
    input logic pb_empty,
    input pixel_buffer_entry_t pb_data,
    // SRAM
    output logic sram_we_b,
    output logic [19:0] writer_addr,
    output logic [15:0] writer_data,
    output logic writer_ub, writer_lb,
    //
    input logic sram_re_b, // from reader
    input logic clk, rst
);

	assign writer_ub = 1'b1;
	assign writer_lb = 1'b1;

	pixelID_t pb_PID;

    assign sram_we_b = ~(sram_re_b & ~pb_empty);
    assign pb_re = ~sram_we_b;

    color16_t color_out;

    assign color_out.red = pb_data.color.red[7:3];
    assign color_out.green = pb_data.color.green[7:2];
    assign color_out.blue = pb_data.color.blue[7:3];

    assign pb_PID = pb_data.pixelID.pixelID;
    assign writer_addr = {1'b0, pb_PID}; // TODO: MSB should flip for double frame buffer
    assign writer_data = color_out;

endmodule


module fbh_reader(
    // to vga
    output logic HS, VS,
    output logic VGA_clk,
    output logic VGA_blank,
    output logic [23:0] VGA_RGB,
    // to/from sram
    output logic sram_re_b,
    output logic [19:0] reader_addr,
    input logic [15:0] reader_data,
    //
    input logic [2:0] scale,
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

    logic row_on_screen;
    logic fbh_active, flip_active_on, flip_active_off;
    assign flip_active_on = (vga_col == 10'h3ff & row_on_screen);
    assign flip_active_off = (vga_col == 10'h27e);
    ff_ar_en #(1,1'b0) fbh_active_ff(.q(fbh_active), .d(flip_active_on), .en(flip_active_on | flip_active_off), .clk, .rst);

	logic reg_sel;
    ff_ar_en #(1,1'b0) reg_sel_ff(.q(reg_sel), .d(~reg_sel), .en(fbh_active), .clk, .rst);

    range_check #(.W(10)) row_rc(
        .is_between(row_on_screen),
        .val(vga_row), .low(10'd0), .high(10'd479));

    logic [3:0] sr_val;
	shifter #(.W(4), .RV(4'b0001)) sr(.q(sr_val), .d(sr_val[0]), .en(fbh_active), .clr(1'b0), .clk, .rst);
 
 	logic en_a, en_b;
	assign en_a = sr_val[1];
	assign en_b = sr_val[3];

	assign sram_re_b = ~(en_a | en_b);

	color16_t a_reg, b_reg;
	ff_ar_en #(.W(16)) a_reg_inst(.q(a_reg), .d(reader_data), .en(en_a), .clk, .rst);
	ff_ar_en #(.W(16)) b_reg_inst(.q(b_reg), .d(reader_data), .en(en_b), .clk, .rst);

	color16_t color_out;
	assign color_out = (reg_sel)? a_reg : b_reg;

    logic [2:0] stripes_color;
    stripes stripes_inst(.vga_color(stripes_color), .vga_row, .vga_col);

	// TODO: 5-scale 
	assign reader_addr = (vga_row * 640) >> (scale << 1) + (vga_col >> scale); // TODO: use concatenation

    assign VGA_RGB = (stripes_sel) ? { stripes_color[2],7'b0, stripes_color[1],7'b0, stripes_color[0],7'b0} :
                                       {color_out.red, 3'b000, color_out.green, 2'b00, color_out.blue, 3'b000};

endmodule
