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

    // Monitor Module I/O and instantiation
    logic valid_and_not_stall;
    logic or_valids;

    monitor_module mm(.*);

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
                if(num_pixels_ds%100 == 0)
                    $display("num_pixels_ds = %-d/%-d",num_pixels_ds,`MAX_PIXEL_IDS);
                if(num_pixels_ds > `MAX_PIXEL_IDS)
                    $display("warning: num_pixels_ds(%d) != `MAX_PIXEL_IDS",num_pixels_ds);
            end // end of if
        end // end of forever
    end // end of initial block

    final begin
        if(num_pixels_ds != num_pixels_us)
            $display("WARNING: num_pixel_ds(%d) != num_pixels_us(%d)",num_pixels_ds,num_pixels_us);
        else
            $display ("Finished rendering and num_pixel_ds == num_pixels_us!");
    end
    //////////// end of pixel ID checker code ////////////

    // reset and start clock
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

    time t, good, bad;

    string sf;

    logic [7:0] file_contents [`MAX_SCENE_FILE_BYTES];
    logic [7:0] message [128];
    int j, r;
    int kdfp;

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
        kdfp = $fopen("SCENES/t2s1.scene","rb");
        r = $fread(file_contents,kdfp);
        $fclose(kdfp);

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
        $display("length of render = %t, num cycles = %d",good,good/`CLOCK_PERIOD);
        $finish;
    end // end of initial block

	// time-out initial block
    initial begin
      while(~t15.render_frame)
          @(posedge clk);
      #(1ms);
      bad = $time - t;
      $display("TIMED OUT");
      $display("length of render = %t, num cycles = %d",bad,bad/`CLOCK_PERIOD);
      $finish;
    end

    final begin
        screen_dump("screen.txt"); // perform screen dump
        $finish;
    end

    logic rst;
    assign rst = ~btns[3]; // for SRAM model

    //////////// MODULE INSTANTIATIONS ////////////

    t_minus_15_days                                t15(.*);
    sram                                           sr(.*);
    qsys_sdram_mem_model_sdram_partner_module_0    dram(.*, .clk(sdram_clk));

    //////////// TASKS ////////////

    `include "COMMON/include/tasks.sv"

endmodule
