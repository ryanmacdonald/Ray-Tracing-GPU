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
int row, col;
integer screen_file_handle;
logic [7:0] upper_byte, lower_byte;
int color_word_cnt;

task screen_dump(input string screen_file);
    color_word_cnt = 0;
    screen_file_handle = $fopen(screen_file,"w");
    $fwrite(screen_file_handle, "%d %d 3\n",`VGA_NUM_ROWS, `VGA_NUM_COLS);
    for(row=0; row < `VGA_NUM_ROWS; row++) begin
        for(col=0; col < `VGA_NUM_COLS*3/2; col++) begin // NOTE: 3/2 ratio will change if we ever go to 16 bit color
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
