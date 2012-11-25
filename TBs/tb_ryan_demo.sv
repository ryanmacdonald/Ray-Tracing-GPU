


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
	logic rst;

	assign rst = ~btns[3];
	
	ryan_demo is_kewl(.*);
	sram sr(.*);


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

		repeat(100000) @(posedge clk);

		$finish;

	end

	// used by screen dump
 	int row, col;
	integer file;
	logic [7:0] upper_byte, lower_byte;
	int color_word_cnt;

	final begin

		color_word_cnt = 0;
		file = $fopen("screen.txt","w");
		$fwrite(file, "%d %d 3\n",`VGA_NUM_ROWS, `VGA_NUM_COLS);
		for(row=0; row < `VGA_NUM_ROWS; row++) begin
			for(col=0; col < `VGA_NUM_COLS*3/2; col++) begin // NOTE: 3/2 ratio will change if we ever go to 16 bit color
				upper_byte = sr.memory[color_word_cnt][15:8];
				lower_byte = sr.memory[color_word_cnt][7:0];
				color_word_cnt++;
				if(upper_byte === 8'bx)
					upper_byte = 'b0;
				if(lower_byte === 8'bx)
					lower_byte = 'b0;

				$fwrite(file, "%d %d ", upper_byte, lower_byte);
			end
		end

		$fclose(file);

	end

	always #5 clk = ~clk;


endmodule: tb_ryan_demo
