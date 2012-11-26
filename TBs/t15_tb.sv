`default_nettype none

`define CLOCK_PERIOD 20

`define MAX_PIXEL_IDS        `num_rays
`define MAX_SCENE_FILE_BYTES 37000

module t15_tb;

    // general IO
    logic [17:0] LEDR;
    logic [8:0] LEDG;
    logic [17:0] switches;
    logic [3:0] btns;

    // RS-232/UART
    logic tx, rts;
    logic rx_pin;

    // VGA
    logic HS, VS;
    logic [23:0] VGA_RGB;
    logic VGA_clk;
    logic VGA_blank;

    // SRAM
    logic [19:0] sram_addr;
    wire [15:0] sram_io;
    logic sram_we_b;
    logic sram_oe_b;
    logic sram_ce_b;
    logic sram_ub_b;
    logic sram_lb_b;

    // SDRAM
    logic [12:0] zs_addr;
    wire [31:0] zs_dq;
    logic [1:0] zs_ba; // bank address
    logic [3:0] zs_dqm; // data mask
    logic zs_ras_n;
    logic zs_cas_n;
    logic zs_cke;
    logic sdram_clk;
    logic zs_we_n;
    logic zs_cs_n; 

    // PS2
    wire PS2_CLK;
    wire PS2_DAT;
 
    logic clk;

    //////////// BIG ASS ASSERTION ////////////

	logic valid_and_not_stall;
	logic or_valids;
assign valid_and_not_stall = (t15.rp.prg_to_shader_valid & ~t15.rp.prg_to_shader_stall) |
                             (t15.rp.shader_to_sint_valid & ~t15.rp.shader_to_sint_stall) |
                             (t15.rp.sint_to_shader_valid & ~t15.rp.sint_to_shader_stall) |
                             (t15.rp.sint_to_ss_valid & ~t15.rp.sint_to_ss_stall) |
                             (t15.rp.sint_to_tarb_valid & ~t15.rp.sint_to_tarb_stall) |
                             (t15.rp.tarb_to_tcache0_valid & ~t15.rp.tarb_to_tcache0_stall) |
                             (t15.rp.tcache_to_trav0_valid & ~t15.rp.tcache_to_trav0_stall) |
                             (t15.rp.trav0_to_rs_valid & ~t15.rp.trav0_to_rs_stall) |
                             (t15.rp.rs_to_trav0_valid & ~t15.rp.rs_to_trav0_stall) |
                             (t15.rp.trav0_to_tarb_valid & ~t15.rp.trav0_to_tarb_stall) |
                             (t15.rp.trav0_to_ss_valid & ~t15.rp.trav0_to_ss_stall) |
                             (t15.rp.trav0_to_list_valid & ~t15.rp.trav0_to_list_stall) |
                             (t15.rp.trav0_to_larb_valid & ~t15.rp.trav0_to_larb_stall) |
                             (t15.rp.larb_to_lcache_valid & ~t15.rp.larb_to_lcache_stall) |
                             (t15.rp.lcache_to_icache_valid & ~t15.rp.lcache_to_icache_stall) |
                             (t15.rp.icache_to_rs_valid & ~t15.rp.icache_to_rs_stall) |
                             (t15.rp.rs_to_int_valid & ~t15.rp.rs_to_int_stall) |
                             (t15.rp.int_to_larb_valid & ~t15.rp.int_to_larb_stall) |
                             (t15.rp.int_to_list_valid & ~t15.rp.int_to_list_stall) |
                             (t15.rp.list_to_rs_valid & ~t15.rp.list_to_rs_stall) |
                             (t15.rp.list_to_ss_valid & ~t15.rp.list_to_ss_stall) |
                             (t15.rp.ss_to_tarb_valid0 & ~t15.rp.ss_to_tarb_stall0) |
                             (t15.rp.ss_to_tarb_valid1 & ~t15.rp.ss_to_tarb_stall1) |
                             (t15.rp.ss_to_shader_valid & ~t15.rp.ss_to_shader_stall) |
                             (t15.rp.rs_to_pcalc_valid & ~t15.rp.rs_to_pcalc_stall) |
                             (t15.rp.pcalc_to_shader_valid & ~t15.rp.pcalc_to_shader_stall);
  
assign or_valids = t15.rp.prg_to_shader_valid |
                   t15.rp.shader_to_sint_valid |
                   t15.rp.sint_to_shader_valid |
                   t15.rp.sint_to_ss_valid |
                   t15.rp.sint_to_tarb_valid |
                   t15.rp.tarb_to_tcache0_valid |
                   t15.rp.tcache_to_trav0_valid |
                   t15.rp.trav0_to_rs_valid |
                   t15.rp.rs_to_trav0_valid |
                   t15.rp.trav0_to_tarb_valid |
                   t15.rp.trav0_to_ss_valid |
                   t15.rp.trav0_to_list_valid |
                   t15.rp.trav0_to_larb_valid |
                   t15.rp.larb_to_lcache_valid |
                   t15.rp.lcache_to_icache_valid |
                   t15.rp.icache_to_rs_valid |
                   t15.rp.rs_to_int_valid |
                   t15.rp.int_to_larb_valid |
                   t15.rp.int_to_list_valid |
                   t15.rp.list_to_rs_valid |
                   t15.rp.list_to_ss_valid |
                   t15.rp.ss_to_tarb_valid0 |
                   t15.rp.ss_to_tarb_valid1 |
                   t15.rp.ss_to_shader_valid |
                   t15.rp.rs_to_pcalc_valid |
                   t15.rp.pcalc_to_shader_valid;

    //////////// END OF BIG ASS ASSERTION ////////////

    //////////// pixel ID checker code ////////////
	bit [`MAX_PIXEL_IDS][$bits(pixelID_t)-1:0] pixelIDs_us ;
	bit [`MAX_PIXEL_IDS][$bits(pixelID_t)-1:0] pixelIDs_ds ;

	logic pixel_valid_us, pixel_valid_ds;

	assign pixel_valid_us = t15.rp.prg_to_shader_valid & ~t15.rp.prg_to_shader_stall;
	assign pixel_valid_ds = t15.pb_we;

	int num_pixels_us;
	int num_pixels_ds;

	initial begin
		num_pixels_us = 0;
		forever begin
			@(posedge clk);
			if(pixel_valid_us) begin
				pixelIDs_us[t15.rp.prg_to_shader_data.pixelID] += 1;
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
				pixelIDs_ds[t15.pb_data_us.pixelID] += 1 ;
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

	//////////// end of pixel ID checker code ////////////

	initial begin
		clk <= 1'b0;
		btns[3] <= 1'b1;
		#1;
		btns[3] <= 1'b0;
		#1;
		btns[3] <= 1'b1;
		#1;
		forever #(`CLOCK_PERIOD) clk = ~clk;
	end

    logic [7:0] message [128];
    int j, r;
    int kdfp;

    logic [7:0] file_contents [`MAX_SCENE_FILE_BYTES];

  // valid block checker code
  int num_valid_blocks;
  initial begin
    num_valid_blocks = 0;
    forever begin
      @(posedge clk);
      if(t15.xm.saw_valid_block) begin
        num_valid_blocks++;
        $display("seen %d valid blocks",num_valid_blocks);
      end
    end
  end

	// used by screen dump
    int row, col;
	integer file;
	logic [7:0] upper_byte, lower_byte;
	int color_word_cnt;

  time t, good, bad;

  string sf;
	initial begin
		switches <= 'b0;
		btns[2:0] <= 3'b111;
		rx_pin <= 1'b1;

		@(posedge clk);
		t15.render_frame <= 1'b0;

	    // Hit start button
        @(posedge clk);
        btns[0] <= 1'b0;
        repeat(100) @(posedge clk);
        btns[0] <= 1'b1;
        //$value$plusargs("SCENE=%s",sf);
        //kdfp = $fopen(sf, "rb");
        kdfp = $fopen("SCENES/t4s3.scene","rb");
        r = $fread(file_contents,kdfp);
		$fclose(kdfp);

		// TODO: right now the sample scene is just one block. make this based on r later.
    for(int k=1; k<(r/128)+2; k++) begin    
       for(j=0; j<128; j++)
            message[j] = file_contents[j+(k-1)*128];
		  send_block(message, k, 0);
    end
		send_EOT();

		@(posedge clk);
		t15.render_frame <= 1'b1;
		t = $time;
    @(posedge clk);
		t15.render_frame <= 1'b0;

		while(~t15.rendering_done)
			@(posedge clk);
    $display("FUCK YEAH RENDER DONE");
    good = $time - t;
    $display("length of render = %t, num cycles = %d",good,good/20);
    $finish;
    end


    initial begin
		  #(100 * 1ms);
      bad = $time - t;
      $display("AWWWWWW YOU SUCK IT TIMED OUT");
      $display("length of render = %t, num cycles = %d",bad,bad/20);
      $finish;
    end



  final begin
		// perform screen dump

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

		$finish;
	end



    logic rst;
    assign rst = ~btns[3]; // for SRAM model

	t_minus_15_days                                t15(.*);
    sram                                           sr(.*);
    qsys_sdram_mem_model_sdram_partner_module_0    dram(.*, .clk(sdram_clk));

    //////////// TASKS ////////////

    task send_EOT();
        send_byte(8'h04);
    endtask

    task send_block(input bit [7:0] message [128], input [7:0] block_num, input have_error);

        integer i;
        logic [7:0] x;
        logic [7:0] sum;
        
        sum = 0;

        send_byte(8'h01); // SOH
        send_byte(block_num); // byte 1
        send_byte(~block_num); // ~(byte 1)
        for(i=0; i<128; i++) begin
            x = message[i];
            sum += x;
            send_byte(x);
            $display("i: %d x: %b %h sum: %b %h",i,x,x,sum,sum);
        end
        if(have_error)
            send_byte(sum-1);
        else
            send_byte(sum);

    endtask: send_block

    task send_byte(input bit [7:0] data);

		// SKETCHY
        repeat(`XM_CYC_PER_BIT+2) @(posedge clk);

        rx_pin <= 1'b0; // indicates start

        for(j=0; j<8; j++) begin
            repeat(`XM_CYC_PER_BIT+2) @(posedge clk);
            rx_pin <= data[j]; // first data bit
        end

        repeat(`XM_CYC_PER_BIT+2) @(posedge clk);
        rx_pin <= 1'b1; // end of byte

    endtask: send_byte

endmodule
