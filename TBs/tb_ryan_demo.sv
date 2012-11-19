


module tb_ryan_demo;


	logic[17:0] LEDR;
	logic[8:0] LEDG;
	logic[17:0] switches;
	logic[3:0] btns;
	
	logic HS, VS;
	logic[23:0] VGA_RGB;
	logic VGA_clk, VGA_blank;

	logic sram_oe_b, sram_we_b, sram_ce_b;
	logic[19:0] sram_addr;
	wire[15:0] sram_io;
	logic sram_ub_b, sram_lb_b;

	wire PS2_CLK;
	wire PS2_DAT;

	logic start;
	logic clk;
	
	ryan_demo is_kewl(.*);


	initial begin

		clk <= 1; start <= 0;
		btns[3] <= 1;
		@(posedge clk);
		btns[3] <= 0;
		@(posedge clk);
		btns[3] <= 1;
		repeat(10) @(posedge clk);
		
		start <= 1;

		@(posedge clk);

		start <= 0;

		repeat(10000) @(posedge clk);

		$finish;

	end

	always #5 clk = ~clk;


endmodule: tb_ryan_demo
