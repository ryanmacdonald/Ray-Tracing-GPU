// this file includes tasks which are used in many testbenches

// TODO: define requirements for using this file

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

// used by screen dump
integer screen_file_handle;
logic [7:0] upper_byte, lower_byte;
int color_word_cnt;

int row, col;

task screen_dump(input string screen_file);
    color_word_cnt = 0;
    screen_file_handle = $fopen(screen_file,"w");
    $fwrite(screen_file_handle, "%d %d 3\n",`NUM_ROWS, `NUM_COLS);
    for(row=0; row < `NUM_ROWS; row++) begin
        for(col=0; col < `NUM_COLS*3/2; col++) begin // NOTE: 3/2 ratio will change if we ever go to 16 bit color
            upper_byte = sr.memory[color_word_cnt][15:8];
            lower_byte = sr.memory[color_word_cnt][7:0];
            color_word_cnt++;
            if(upper_byte === 8'bx)
                upper_byte = 'b0;
            if(lower_byte === 8'bx)
                lower_byte = 'b0;
            $fwrite(screen_file_handle, "%d %d ", upper_byte, lower_byte);
        end
    end

    $fclose(screen_file_handle);
endtask

task screen_dump_16(input string screen_file);
    color_word_cnt = 0;
    screen_file_handle = $fopen(screen_file,"w");
    $fwrite(screen_file_handle, "%d %d 3\n",`NUM_ROWS, `NUM_COLS);
    for(row=0; row < `NUM_ROWS; row++) begin
        for(col=0; col < `NUM_COLS; col++) begin
            upper_byte = sr.memory[color_word_cnt][15:8];
            lower_byte = sr.memory[color_word_cnt][7:0];
            color_word_cnt++;
            if(upper_byte === 8'bx)
                upper_byte = 'b0;
            if(lower_byte === 8'bx)
                lower_byte = 'b0;
            $fwrite(screen_file_handle, "%d %d %d ", {upper_byte[7:3],3'b00}, {upper_byte[2:0],lower_byte[7:5],2'b0}, {lower_byte[4:0],3'b00});
        end
    end

    $fclose(screen_file_handle);
endtask

int capture_cnt;
int max_out_at;

task vga_capture(input string screen_file);

	logic [7:0] red, green, blue;

	max_out_at = 107200;

	capture_cnt = 0;

	$display("aligning to next screen...");

	while(vga_row != 0) begin // align to the next screen
		@(posedge clk);
	end

    screen_file_handle = $fopen(screen_file,"w");
    $fwrite(screen_file_handle, "%d %d 3\n",480, 640);

	while(capture_cnt < max_out_at) begin
		if(vga_row >= 0 && vga_row < 480 && vga_col >= 0 && vga_col < 640) begin
			red = VGA_RGB[23:16];
			green = VGA_RGB[15:8];
			blue = VGA_RGB[7:0];
            $fwrite(screen_file_handle, "%d %d %d ", red, green, blue);
			capture_cnt++;
			if(capture_cnt % 1000 == 0)
				$display("captured: %d",capture_cnt);
		end
		@(posedge clk);
		@(posedge clk);
	end

	for(int i=0; i< 307200 - max_out_at; i++) begin
        $fwrite(screen_file_handle, "%d %d %d ", 16'd0, 16'd0, 16'd0);
	end

    $fclose(screen_file_handle);

endtask
