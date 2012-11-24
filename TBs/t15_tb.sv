`default_nettype none

`define CLOCK_PERIOD 20

`define MAX_PIXEL_IDS        1000
`define MAX_SCENE_FILE_BYTES 20000

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

    //////////// pixel ID checker code ////////////
	pixelID_t pixelIDs_us [`MAX_PIXEL_IDS];
	pixelID_t pixelIDs_ds [`MAX_PIXEL_IDS];

	logic pixel_valid_us, pixel_valid_ds;

	assign pixel_valid_us = t15.rp.prg_to_shader_valid & ~t15.rp.prg_to_shader_stall;
	assign pixel_valid_ds = t15.pb_we;

	int num_pixels_us = 0;
	int num_pixels_ds = 0;

	initial begin
		forever begin
			@(posedge clk);
			if(pixel_valid_us)
				pixelIDs_us[num_pixels_us++] = t15.rp.prg_to_shader_data.pixelID;
			if(num_pixels_us >= `MAX_PIXEL_IDS)
				$display("warning: num_pixels_us >= `MAX_PIXEL_IDS");
		end
	end

	initial begin
		forever begin
			@(posedge clk);
			if(pixel_valid_ds)
				pixelIDs_ds[num_pixels_ds++] = t15.pb_data_us.pixelID;
			if(num_pixels_us >= `MAX_PIXEL_IDS)
				$display("warning: num_pixels_us != `MAX_PIXEL_IDS");
		end
	end

	final begin
		if(num_pixels_ds != num_pixels_us) begin
			$display("WARNING: num_pixel_ds != num_pixels_us");
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

        kdfp = $fopen("SCENES/kdtree.bin", "rb");
        r = $fread(file_contents,kdfp);
		$fclose(kdfp);

		// TODO: right now the sample scene is just one block. make this based on r later.
        for(j=0; j<128; j++)
            message[j] = file_contents[j];
		send_block(message, 1, 0);

        for(j=0; j<128; j++)
            message[j] = file_contents[j+128];
		send_block(message, 2, 0);
/*
        for(j=0; j<128; j++)
            message[j] = file_contents[j+128];
  		send_block(message, 2, 0);
*/

		send_EOT();

		@(posedge clk);
		t15.render_frame <= 1'b1;
		@(posedge clk);
		t15.render_frame <= 1'b0;

		repeat(1000) @(posedge clk);
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
