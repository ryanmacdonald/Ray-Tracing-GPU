

// Demos scene_int, camera, prg, vga, and ps2

module ryan_demo(
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


	frame_buffer_handler fbh(.*);

	keys_t keys;
	camera_controller cc(.clk,.rst,.v0,.v1,.v2,.keys,.rendering_done,.render_frame,
			     .E,.U,.V,.W);

	vga               monitor(.display_done,.HS,.VS,.VGA_clk,.VGA_blank,.vga_row,.vga_col,.clk_25M,.clk_50M,.rst);

	prg_top		  prg(.clk,.rst,.v0,.v1,.v2,.start,.E,.U,.V,.W,.pw,.int_to_prg_stall,.ready,.done,.prg_data);	  

	scene_int	  si();

	ps2		  mouse(.iSTART(),.iRST_n,.iCLK_50,.ps2_clk,.ps2_data,.ps2_clk_out,ps2_dat_out,.ce,.de,.shift_reg,.pkt_ec,.cnt11);

	ps2_parse	  parse(.clk,.rst_b,.ps2_pkt_DH,rec_ps2_pkt,.keys);


	fifo #()	  pb();



endmodule: ryan_demo
