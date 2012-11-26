
`define MAX_PIXEL_IDS        `num_rays

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

	logic start_prg;
	logic clk;
	logic rst;

	keys_t keys;

	assign rst = ~btns[3];
	
	ryan_demo is_kewl(.*);
	sram sr(.*);

	int num_pixels_us;
	int num_pixels_ds;
	initial begin



		clk <= 1; keys <= 'h0;
		start_prg <= 0;
		btns[3] <= 1;
		@(posedge clk);
		btns[3] <= 0;
		@(posedge clk);
		btns[3] <= 1;
		repeat(10) @(posedge clk);
		
		//start_prg <= 1;
		keys.a[0] <= 1;
		keys.pressed <= 1;	

		@(posedge clk);

		//start_prg <= 0;
		keys.a[0] <= 0;
		keys.pressed <= 0;

		repeat(200) @(posedge clk);
	


		while(num_pixels_ds != `num_rays) begin
			@(posedge clk);
		end

		keys.a[1] <= 1;
		keys.released <= 1;

		@(posedge clk);

		keys.a[1] <= 0;
		keys.released <= 0;

		repeat(200) @(posedge clk);

		// Add this for full resoultion simulation
		//repeat(20000) @(posedge clk);

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

	//////////// pixel ID checker code ////////////
	bit [`MAX_PIXEL_IDS][$bits(pixelID_t)-1:0] pixelIDs_us ;
	bit [`MAX_PIXEL_IDS][$bits(pixelID_t)-1:0] pixelIDs_ds ;

	logic pixel_valid_us, pixel_valid_ds;

	assign pixel_valid_us = is_kewl.prg.prg_to_shader_valid & ~is_kewl.prg.prg_to_shader_stall;
	assign pixel_valid_ds = is_kewl.pb_we&&~is_kewl.pb_full;



	initial begin
		num_pixels_us = 0;
		forever begin
			@(posedge clk);
			if(pixel_valid_us) begin
				pixelIDs_us[is_kewl.prg.prg_to_shader_data.pixelID] += 1;
			  num_pixels_us++;
			
			if(num_pixels_us > `MAX_PIXEL_IDS)
				$display("warning: num_pixels_us(%d) >= `MAX_PIXEL_IDS",num_pixels_us);
			end
		end
	end

	initial begin
		num_pixels_ds = 0;
		forever begin
			@(posedge clk);
			if(pixel_valid_ds) begin
				pixelIDs_ds[is_kewl.pb_data_in.pixelID] += 1 ;
			  num_pixels_ds++;
        if(num_pixels_ds%100 == 0) begin
          $display("num_pixels_ds = %-d/%-d",num_pixels_ds,`MAX_PIXEL_IDS);
        end
      		if(num_pixels_ds > `MAX_PIXEL_IDS)
				$display("warning: num_pixels_ds(%d) != `MAX_PIXEL_IDS",num_pixels_ds);
			 
      end
		end
	end

	final begin
		if(num_pixels_ds != num_pixels_us) begin
			$display("WARNING: num_pixel_ds(%d) != num_pixels_us(%d)",num_pixels_ds,num_pixels_us);
		end
    else $display ("FUCK YEAH SEAKING!!!!!!!");
	end


	always #5 clk = ~clk;


endmodule: tb_ryan_demo
