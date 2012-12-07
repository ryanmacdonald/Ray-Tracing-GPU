`default_nettype none

`define CLOCK_PERIOD 20

`define MAX_PIXEL_IDS        `num_rays
`define MAX_SCENE_FILE_BYTES 37000

module t5_tb;

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

    // PS2
    wire PS2_CLK;
    wire PS2_DAT;
 
    logic clk;

    // Monitor Module I/O and instantiation
    logic valid_and_not_stall;
    logic or_valids;

    // Check the number of times we restart
    int hash[int];
    int cur_node;
    int restcnt;
    initial begin
      restcnt = 0;
      forever @(posedge clk) begin
        if(t5.rp.ss_to_tarb_valid1 & !t5.rp.ss_to_tarb_stall1) begin
          cur_node = t5.rp.ss_to_tarb_data1.nodeID;
          restcnt += 1;
          if(hash.exists(cur_node)) begin
            hash[cur_node] += 1;
          end
          else begin
            hash[cur_node] = 1;
          end
        end
      end
    end

    int tmp_node;
    final begin
      $display("Total number of restarts: %d",restcnt);
      if(hash.first(tmp_node))
      do
        $display("Restart node: %d  occured %d times",tmp_node,hash[tmp_node]);
      while(hash.next(tmp_node));
    end
    
  int list_to_ss_stall_cnt;
  int trav0_to_ss_stall_cnt;
  int sint_to_ss_stall_cnt;
  int int_to_larb_stall_cnt;
  int trav0_to_larb_stall_cnt;
  int icache_to_rs_stall_cnt;
  
  int rayID_cnt;
  int shader_arb_stall_cnt;
  
  initial begin
    list_to_ss_stall_cnt = 0;
    trav0_to_ss_stall_cnt = 0;
    sint_to_ss_stall_cnt = 0;
    int_to_larb_stall_cnt = 0;
    trav0_to_larb_stall_cnt = 0;
    icache_to_rs_stall_cnt = 0;
    rayID_cnt = 0;
    shader_arb_stall_cnt = 0;
    forever @(posedge clk) begin
      if(t5.rp.list_to_ss_stall) list_to_ss_stall_cnt +=1 ;
      if(t5.rp.trav0_to_ss_stall) trav0_to_ss_stall_cnt +=1 ;
      if(t5.rp.sint_to_ss_stall) sint_to_ss_stall_cnt +=1 ;
      if(t5.rp.int_to_larb_stall) int_to_larb_stall_cnt +=1 ;
      if(t5.rp.trav0_to_larb_stall) trav0_to_larb_stall_cnt +=1 ;
      if(t5.rp.icache_to_rs_stall) icache_to_rs_stall_cnt +=1 ;
      
      if(t5.rp.simple_shader_unit_inst.rayID_empty & 
         t5.rp.prg_to_shader_valid) rayID_cnt +=1 ;
      if(t5.rp.simple_shader_unit_inst.arb_stall_ds) shader_arb_stall_cnt +=1 ;
    end
  end

  final begin
    $display("Total number of Stalls for...");
    $display("\tlist_to_ss = %-d",list_to_ss_stall_cnt);
    $display("\ttrav0_to_ss = %-d",trav0_to_ss_stall_cnt);
    $display("\tsint_to_ss = %-d",sint_to_ss_stall_cnt);
    $display("\tint_to_larb = %-d",int_to_larb_stall_cnt);
    $display("\ttrav0_to_larb = %-d",trav0_to_larb_stall_cnt);
    $display("\ticache_to_rs = %-d",icache_to_rs_stall_cnt);
    $display("\trayID_cnt = %-d",rayID_cnt);
    $display("\tshader_arb_stall_cnt = %-d",shader_arb_stall_cnt);
  end

  
    longint rayID_time[512];
    realtime avg_time;
    longint tot_time;
    int cur_num_rays;
    longint cur_clk;
    initial begin
      cur_clk = 0;
      tot_time = 0;
      cur_num_rays = -512;
      forever @(posedge clk) begin
        if(t5.rp.simple_shader_unit_inst.rayID_rdreq) rayID_time[t5.rp.simple_shader_unit_inst.rayID_fifo_out] = cur_clk;
        if(t5.rp.simple_shader_unit_inst.rayID_wrreq) begin
          tot_time += (cur_clk - rayID_time[t5.rp.simple_shader_unit_inst.rayID_fifo_in]);
          cur_num_rays += 1;
          if(cur_num_rays%100 == 0)
            $display("curent average num clocks = %d for %d rays", tot_time/cur_num_rays, cur_num_rays);
        end
        cur_clk++;
      end
    end
    final begin
      $display("Final avg num clocks = %d for %d rays", tot_time/cur_num_rays, cur_num_rays);
    end

//    monitor_module mm(.*);

    //////////// pixel ID checker code ////////////
    bit [`MAX_PIXEL_IDS][$bits(pixelID_t)-1:0] pixelIDs_us ;
    bit [`MAX_PIXEL_IDS][$bits(pixelID_t)-1:0] pixelIDs_ds ;

    logic pixel_valid_us, pixel_valid_ds;

    assign pixel_valid_us = t5.rp.prg_to_shader_valid & ~t5.rp.prg_to_shader_stall;
    assign pixel_valid_ds = t5.pb_we;

    int num_pixels_us;
    int num_pixels_ds;

    initial begin
        num_pixels_us = 0;
        forever begin
            @(posedge clk);
            if(pixel_valid_us) begin
                pixelIDs_us[t5.rp.prg_to_shader_data.pixelID] += 1;
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
                pixelIDs_ds[t5.pb_data_us.pixelID] += 1 ;
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
            if(t5.xm.saw_valid_block) begin
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

    int manual_addr;

	logic [9:0] vga_row, vga_col;

    int k;
    int byte_cnt;

    initial begin
        switches <= 'b0;
        btns[2:0] <= 3'b111;
        rx_pin <= 1'b1;

        byte_cnt = 0;
        force t5.xmodem_saw_invalid_block = 1'b0;
        force t5.xmodem_receiving_repeat_block = 1'b0;
        force t5.xmodem_done = 1'b0;
        force t5.xmodem_saw_valid_msg_byte = 1'b0;

        @(posedge clk);
        force t5.render_frame = 1'b0;

        // Hit start button
/*        @(posedge clk);
        btns[0] <= 1'b0;
        repeat(100) @(posedge clk);
        btns[0] <= 1'b1; */
        //$value$plusargs("SCENE=%s",sf);
        //kdfp = $fopen(sf, "rb");
        kdfp = $fopen("SCENES/bunny.scene","rb");
        r = $fread(file_contents,kdfp);
        $fclose(kdfp);

/*        for(int k=1; k<(r/128)+2; k++) begin
            for(j=0; j<128; j++)
                message[j] = file_contents[j+(k-1)*128];
            send_block(message, k, 0);
        end
        send_EOT(); */

        //$monitor("sl_block_num: %d data: %h valid_msg: %b",t5.sl_block_num,t5.xmodem_data_byte, t5.xmodem_saw_valid_msg_byte);
//        $monitor("rendering_done: %d render_frame: %b",t5.rendering_done, t5.render_frame);

        @(posedge clk);
        #1;
        $display("number of bytes in file: %d",r);
        for(k=0; k<r; k++) begin
            if(k%128 == 0)
                $display("sending Block %d",k/128);
            force t5.xmodem_data_byte = file_contents[k];
            force t5.xmodem_saw_valid_msg_byte = 1'b1;
            force t5.sl_block_num = byte_cnt / 128;
            force t5.xmodem_saw_valid_block = (byte_cnt % 128 == 0);
            byte_cnt++;
            @(posedge clk); #1 ;force t5.xmodem_saw_valid_msg_byte = 1'b0;
            repeat(15) @(posedge clk);
            #1;
        end
        force t5.xmodem_done = 1'b1;
        force t5.xmodem_saw_valid_msg_byte = 1'b0;
        @(posedge clk);
        #1;
        force t5.xmodem_done = 1'b0;

/*        @(posedge clk);
        force t5.keys.a[0] = 1'b1;
        force t5.keys.pressed = 1'b1;
        t = $time;
        @(posedge clk);
        force t5.keys.a[0] = 1'b0;
        force t5.keys.pressed = 1'b0; */

        @(posedge clk);
        force t5.render_frame = 1'b1;
        t = $time;
        @(posedge clk);
        force t5.render_frame = 1'b0;


        while(~t5.rendering_done)
            @(posedge clk);
        $display("FUCK YEAH RENDER DONE");
        good = $time - t;
        $display("length of render = %t, num cycles = %d",good,good/`CLOCK_PERIOD);

		assign vga_row = t5.fbh.reader.vga_row;
		assign vga_col = t5.fbh.reader.vga_col;
		vga_capture("screen.txt"); // NEW

		$finish; // REMOVE

        @(posedge clk);
		force t5.rp.prg_inst.scale = 3'd1;
        force t5.render_frame = 1'b1;
        @(posedge clk);
        force t5.render_frame = 1'b0;

        while(~t5.rendering_done)
            @(posedge clk);


		vga_capture("screen2.txt"); // NEW

		/*
        repeat(10000) @(posedge clk);

        @(posedge clk);
        force t5.keys.a[1] = 1'b1;
        force t5.keys.released = 1'b1;
        t = $time;
        @(posedge clk);
        force t5.keys.a[1] = 1'b0;
        force t5.keys.released = 1'b0;
*/

        $finish;
    end // end of initial block

    // time-out initial block
    initial begin
      while(~t5.render_frame)
          @(posedge clk);
      #(1s);
      bad = $time - t;
      $display("TIMED OUT");
      $display("length of render = %t, num cycles = %d",bad,bad/`CLOCK_PERIOD);
      $finish;
    end

    final begin
        screen_dump_16("screen3.txt"); // perform screen dump
    end

    logic rst;
    assign rst = ~btns[3]; // for SRAM model

    //////////// MODULE INSTANTIATIONS ////////////

    t_minus_5_days                                 t5(.*);
    sram                                           sr(.*);

    //////////// TASKS ////////////

    `include "COMMON/include/tasks.sv"

endmodule
