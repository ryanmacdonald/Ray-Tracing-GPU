

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

    // test input to start prg automatically (no ps2 input required)
    input logic start,
     
    input logic clk);

	logic rst;
	assign rst = ~btns[3];
	logic v0, v1, v2;
	/*logic start;
	assign start = ~btns[0];*/

	logic stripes_sel;

	pixel_buffer_entry_t pb_data_in, pb_data_out;
	logic pb_re;
	assign stripes_sel = switches[0];	

	frame_buffer_handler fbh(.pb_data(pb_data_out),.*);

	keys_t keys;
	logic rendering_done, render_frame;

	
	logic[18:0] rendcnt, rendcnt_n;
	assign rendcnt_n = pb_re ? ( rendering_done ? 19'b1 : rendcnt + 19'b1) : rendcnt;
	ff_ar #(19,0) pb_cnt(.q(rendcnt),.d(rendcnt_n),.clk,.rst);

	assign rendering_done = (rendcnt == `num_rays);


	vector_t E, U, V, W;
	camera_controller cc(.clk,.rst,.v0,.v1,.v2,
			     .keys(keys),.rendering_done,.render_frame,
			     .E,.U,.V,.W);


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

	logic[31:0] pw;
	`ifdef SYNTH
	assign pw = 32'h3C4CCCCD;
	`else
	assign pw = `FP_1;
	`endif

	logic prg_ready, us_stall;
	prg_ray_t prg_data;
	prg		  prg(.clk,.rst,.v0,.v1,.v2,.start(start),
			      .E,.U,.V,.W,.pw,.prg_to_shader_stall(us_stall),
			      .prg_to_shader_valid(prg_ready),.prg_to_shader_data(prg_data));	  

	shader_to_sint_t ray_in;
	assign ray_in.rayID = prg_data.pixelID;
	assign ray_in.is_shadow = 0;
	assign ray_in.ray_vec.origin = prg_data.origin;
	assign ray_in.ray_vec.dir = prg_data.dir;
	AABB_t sb;	

	assign sb.xmin = `FP_0;
	assign sb.xmax = `FP_1;
	assign sb.ymin = `FP_0;
	assign sb.ymax = `FP_1;
	assign sb.zmin = `FP_0;
	assign sb.zmax = `FP_1;

	logic pb_full;

	tarb_t tf_ray_out;
	sint_to_ss_t ssf_ray_out;
	sint_to_shader_t ssh_ray_out;
	logic tf_ds_stall, ssf_ds_stall, ssh_ds_stall;
	logic tf_ds_valid, ssf_ds_valid, ssh_ds_valid;
	scene_int	  si(.shader_to_sint_data(ray_in),.v0,.v1,.v2,
			     .sceneAABB(sb),
			     .sint_to_tarb_stall(tf_ds_stall),
			     .sint_to_ss_stall(ssf_ds_stall),
			     .sint_to_shader_stall(ssh_ds_stall),
			     .shader_to_sint_valid(prg_ready),.clk,.rst,
			     .sint_to_tarb_data(tf_ray_out),
			     .sint_to_ss_data(ssf_ray_out),
			     .sint_to_shader_data(ssh_ray_out),
			     .shader_to_sint_stall(us_stall),
			     .sint_to_tarb_valid(tf_ds_valid),
			     .sint_to_ss_valid(ssf_ds_valid),
			     .sint_to_shader_valid(ssh_ds_valid));



	temp_sint_fifo_arb tsfa(.clk,.rst,.tf_ds_valid,.ssf_ds_valid,.ssh_ds_valid,
				.ssf_ray_out,.ssh_ray_out,.tf_ray_out,
				.tf_ds_stall,.ssf_ds_stall,.ssh_ds_stall,
				.pb_data(pb_data_in),
				.pb_full,
				.pb_we);


	logic pb_we, pb_empty;
	fifo #(.WIDTH($bits(pixel_buffer_entry_t)),.DEPTH(200)) 
			  pb(.clk,.rst,.data_in(pb_data_in),
			     .we(pb_we),.re(pb_re),.full(pb_full),
			     .empty(pb_empty),.data_out(pb_data_out),
			     .num_left_in_fifo(),.exists_in_fifo());


	logic[1:0] cnt, cnt_n;
	assign cnt_n = (cnt == 2'b10) ? 2'b00 : cnt + 2'b1;
	ff_ar #(2,0) v(.q(cnt),.d(cnt_n),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

endmodule: ryan_demo
