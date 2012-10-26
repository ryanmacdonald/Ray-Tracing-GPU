`define CLK_PRD 20

module fbh_tb;

	logic pb_we;
	logic pb_full;

	logic pb_re;
	logic pb_empty;
	pixel_buffer_entry_t pb_data;
	logic sram_re;
	logic sram_we;
	logic [19:0] sram_addr;
	wire [15:0] sram_io;
	logic sram_ub, sram_lb;
	logic HS, VS;
	logic VGA_clk;
	logic VGA_blank;
	logic [23:0] VGA_RGB;
	logic stripes_sel;
	logic clk, rst;

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
		pb_data_in.rayID <= 19'd1;
		pb_we <= 1'b1;

		@(posedge clk);
		pb_data_in.color.red <= 8'h78;
		pb_data_in.color.green <= 8'h9a;
		pb_data_in.color.blue <= 8'hbc;
		pb_data_in.rayID <= 19'd0;

		@(posedge clk);
		pb_we <= 1'b0;

		repeat(10) @(posedge clk);
		$finish;
	end


	fifo #(.K(7), .WIDTH($bits(pixel_buffer_entry_t)))
		pb_fifo(.clk, .rst, .data_in(pb_data_in), .we(pb_we), .re(pb_re), .full(pb_full), .empty(pb_empty), .data_out(pb_data));


	frame_buffer_handler fbh(.*);

    logic sram_ce_b;
    logic sram_we_b;
    logic sram_oe_b;
    logic sram_ub_b;
    logic sram_lb_b;

    assign sram_ce_b = 1'b0;
    assign sram_we_b = ~sram_we;
    assign sram_oe_b = ~sram_re;
    assign sram_ub_b = ~sram_ub;
    assign sram_lb_b = ~sram_lb;

	sram sr(.*);

endmodule
