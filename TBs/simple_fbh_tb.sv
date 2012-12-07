`define CLK_PRD 20

module simple_fbh_tb;

	logic pb_we;
	logic pb_full;

	logic pb_re;
	logic pb_empty;
	pixel_buffer_entry_t pb_data;
	logic sram_oe_b;
	logic sram_we_b;
    logic sram_ce_b;
	logic [19:0] sram_addr;
	wire [15:0] sram_io;
	logic sram_ub_b, sram_lb_b;
	logic HS, VS;
	logic VGA_clk;
	logic VGA_blank;
	logic [23:0] VGA_RGB;
	logic stripes_sel;
	logic clk, rst;

	assign stripes_sel = 1'b0;

	pixel_buffer_entry_t pb_data_in;

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		#1;
		forever #(`CLK_PRD/2) clk = ~clk;
	end

	initial begin
		pb_data_in <= {$bits(pixel_buffer_entry_t){1'b0}};
		pb_we <= 1'b0;

		repeat(10) @(posedge clk);
		pb_data_in.color.red <= 8'h12;
		pb_data_in.color.green <= 8'h34;
		pb_data_in.color.blue <= 8'h56;
		pb_data_in.pixelID.pixelID <= 19'd1;
		pb_we <= 1'b1;

		@(posedge clk);
		pb_data_in.color.red <= 8'h78;
		pb_data_in.color.green <= 8'h9a;
		pb_data_in.color.blue <= 8'hbc;
		pb_data_in.pixelID.pixelID <= 19'd2;

		@(posedge clk);
		pb_we <= 1'b0;

		repeat(100000) @(posedge clk);

		repeat(10) @(posedge clk);
		$finish;
	end


	fifo #(.DEPTH(128), .WIDTH($bits(pixel_buffer_entry_t)))
		pb_fifo(.clk, .rst, .data_in(pb_data_in), .we(pb_we), .re(pb_re), .full(pb_full), .empty(pb_empty), .data_out(pb_data), .exists_in_fifo(), .num_left_in_fifo());

	logic [2:0] scale;
	assign scale = 3'b000; // TODO: vary this

	simple_frame_buffer_handler fbh(.*);

	sram sr(.*);

endmodule
