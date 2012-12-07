`default_nettype none

module t_minus_5_days(
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

	logic        rst;
	logic        start_btn;
	logic        stripes_sel;
	logic [31:0] writeData;
	logic        writeReq;

    // Camera controller outputs
	logic render_frame;
	vector_t  E, U, V, W;

	// NOTE: should come from camera controller
	/*assign E.x = `INIT_CAM_X;
	assign E.y = `INIT_CAM_Y;
	assign E.z = `INIT_CAM_Z;
	assign U.x = `FP_1;
	assign U.y = `FP_0;
	assign U.z = `FP_0;
	assign V.x = `FP_0;
	assign V.y = `FP_1;
	assign V.z = `FP_0;
	assign W.x = `FP_0;
	assign W.y = `FP_0;
	assign W.z = `FP_1; */

	// Ray pipe outputs
	pixel_buffer_entry_t pb_data_us;
	logic pb_we;
	logic [2:0] scale;

	// xmodem outputs
    logic xmodem_done;
    logic xmodem_saw_valid_block;
    logic xmodem_saw_invalid_block;
    logic xmodem_saw_valid_msg_byte;
    logic xmodem_receiving_repeat_block;
    logic [7:0] xmodem_data_byte;
    logic [7:0] sl_block_num;

	// scene loader outputs
    logic [24:0] sl_addr;
    logic [31:0] sl_io;
    logic sl_we;
    logic sl_done;
    logic segment_done; // hacky...

	// pixel buffer outputs
	logic pb_full;
	logic pb_empty;
	pixel_buffer_entry_t pb_data_ds;
//	logic [NUM_W-1:0] pb_num_left_in_fifo;

	// frame buffer handler output
	logic pb_re;
	logic rendering_done;

	// PS/2 outputs
	keys_t    keys;             // Keys packet from PS/2 

	// continuous assignments

	assign writeReq = sl_we;
	assign writeData = sl_io;

	assign stripes_sel = switches[0];
	assign rst = ~btns[3];
	assign start_btn = btns[0];

		// TODO: make AABB from scene file instead of constant
		logic  v0, v1, v2;
		AABB_t sceneAABB;
		
	logic[1:0] cnt, cnt_n;
	assign cnt_n = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(cnt_n),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);


	assign sceneAABB.xmin = 'h0;
	assign sceneAABB.ymin = 'h0;
	assign sceneAABB.zmin = 'h0;
	assign sceneAABB.xmax = 32'h4000_0000; // $shortrealtobits(2);
	assign sceneAABB.ymax = 32'h4000_0000; // $shortrealtobits(2);
	assign sceneAABB.zmax = 32'h4000_0000; // $shortrealtobits(2);


	// Module instantiations

	////////////////// PS/2 //////////////////
	logic start;
	negedge_detector start_ned(.ed(start), .in(start_btn), .clk, .rst);
	logic [32:0] shift_data;
	logic ps2_clk, ps2_data;
	logic ps2_data_out, ps2_clk_out;
	logic clk_en, data_en, pkt_rec;
	logic[7:0] data_pkt_HD;
	assign data_pkt_HD = 8'hFF;
	assign ps2_clk = clk_en ? 1'b1 : PS2_CLK;
	assign ps2_data = data_en ? 1'b1 : PS2_DAT;
	assign PS2_CLK = clk_en ? ps2_clk_out : 1'bz;
	assign PS2_DAT = data_en ? ps2_data_out : 1'bz;
	ps2		  mouse(.iSTART(start),.iRST_n(~rst),.iCLK_50(clk),
				.ps2_clk(ps2_clk),.ps2_data(ps2_data),
				.ps2_clk_out(ps2_clk_out),.ps2_dat_out(ps2_data_out),
				.ce(clk_en),.de(data_en),.shift_reg(shift_data),
				.pkt_rec(pkt_rec),.cnt11());

	ps2_parse	  parse(.clk,.rst_b(~rst),
				.ps2_pkt_DH(shift_data[30:23]),
				.rec_ps2_pkt(pkt_rec),.keys(keys));
	////////////////// End of PS/2 //////////////////

	camera_controller ccu(.*);

    xmodem xm(.*);

    scene_loader sl(.*);

	raypipe_simple_caches rp(.*);

	// TODO: replace with bram
	fifo #(.WIDTH($bits(pixel_buffer_entry_t)), .DEPTH(20)) pb(.*, .we(pb_we), .re(pb_re), .data_in(pb_data_us),
		.data_out(pb_data_ds), .num_left_in_fifo(),
		.empty(pb_empty), .full(pb_full), .exists_in_fifo());

	simple_frame_buffer_handler fbh(.*, .pb_data(pb_data_ds));
//	frame_buffer_handler fbh(.*, .pb_data(pb_data_ds));

endmodule: t_minus_5_days
