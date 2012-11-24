`default_nettype none

module t_minus_15_days(
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

    // SDRAM
    output logic [12:0] zs_addr,
    inout wire [31:0] zs_dq,
    output logic [1:0] zs_ba, // bank address
    output logic [3:0] zs_dqm, // data mask
    output logic zs_ras_n,
    output logic zs_cas_n,
    output logic zs_cke,
    output logic sdram_clk,
    output logic zs_we_n,
    output logic zs_cs_n, 

    // PS2
    inout PS2_CLK,
    inout PS2_DAT,
     
    input logic clk);

    logic pll_clk;

    `ifdef SYNTH // in synthesis, use the PLL clk
    	assign sdram_clk = pll_clk;
    `else // in simulation, use the board clk
    	assign sdram_clk = clk;
    `endif

	logic        rst;
	logic        start_btn;
	logic        stripes_sel;
	logic [31:0] writeData;
	logic        writeReq;

    // Camera controller outputs
	logic render_frame;
	vector_t  E, U, V, W;

	// NOTE: should come from camera controller
	assign E.x = `INIT_CAM_X;
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
	assign W.z = `FP_1;

	// Ray pipe outputs
	pixel_buffer_entry_t pb_data_us;
	logic[`numcaches-1:0][24:0] addr_cache_to_sdram;
	logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize;
	logic[`numcaches-1:0] readReq;
	logic pb_we;

	// xmodem outputs
    logic xmodem_done;
    logic xmodem_saw_valid_block;
    logic xmodem_saw_invalid_block;
    logic xmodem_saw_valid_msg_byte;
    logic [7:0] xmodem_data_byte;
    logic [7:0] sl_block_num;

	// scene loader outputs
    logic [24:0] sl_addr;
    logic [31:0] sl_io;
    logic sl_we;
    logic sl_done;

	// pixel buffer outputs
	logic pb_full;
	logic pb_empty;
	pixel_buffer_entry_t pb_data_ds;
//	logic [NUM_W-1:0] pb_num_left_in_fifo;

	// frame buffer handler output
	logic pb_re;

	// memory request arbiter outputs
	logic[`numcaches-1:0] readValid_out;
	logic[`numcaches-1:0][31:0] readData;
	logic[`numcaches-1:0] doneRead;
	logic doneWrite;
	wire write_error;

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
		logic  rendering_done;
		AABB_t sceneAABB;
		
	logic[1:0] cnt, cnt_n;
	assign cnt_n = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(cnt_n),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

	logic[18:0] rendcnt, rendcnt_n;
	assign rendcnt_n = pb_re ? ( rendering_done ? 19'b1 : rendcnt + 19'b1) : rendcnt;
	ff_ar #(19,0) pb_cnt(.q(rendcnt),.d(rendcnt_n),.clk,.rst);

	assign rendering_done = (rendcnt == 19'd307200);

	assign sceneAABB.xmin = 'h0;
	assign sceneAABB.ymin = 'h0;
	assign sceneAABB.zmin = 'h0;
	assign sceneAABB.xmax = $shortrealtobits(2);
	assign sceneAABB.ymax = $shortrealtobits(2);
	assign sceneAABB.zmax = $shortrealtobits(2);


	// Module instantiations

	// TODO: instantiate PS/2 controller

//	camera_controller ccu(.*);

    xmodem xm(.*);

    scene_loader sl(.*);

    memory_request_arbiter mra(.*,.sdram_clk(pll_clk));

	raypipe rp(.*);

	// TODO: replace with bram
	fifo #(.WIDTH($bits(pixel_buffer_entry_t)), .DEPTH(64)) pb(.*, .we(pb_we), .re(pb_re), .data_in(pb_data_us),
		.data_out(pb_data_ds), .num_left_in_fifo(),
		.empty(pb_empty), .full(pb_full), .exists_in_fifo());

	frame_buffer_handler fbh(.*, .pb_data(pb_data_ds));

endmodule: t_minus_15_days
