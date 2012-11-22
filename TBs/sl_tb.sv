`default_nettype none
`define CLOCK_PERIOD 20

module sl_tb;

	logic [24:0] sl_addr;
    logic [31:0] sl_io;
    logic sl_we;
    logic sl_done;
    logic [7:0] xmodem_data_byte;
    logic [7:0] sl_block_num;
    logic xmodem_saw_valid_msg_byte;
    logic xmodem_saw_valid_block;
    logic xmodem_saw_invalid_block;
    logic xmodem_done;
    logic clk, rst;

    logic tx;
    logic rts;
    logic start_btn;
    logic rx_pin;

	scene_loader sl(.*);
	xmodem xm(.*);

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		forever #(`CLOCK_PERIOD) clk = ~clk;
	end

	int j;
    logic [7:0] message [128];

	initial begin
		rx_pin <= 1'b1;

    // Hit start button
        @(posedge clk);
        start_btn <= 1'b0;
        repeat(100) @(posedge clk);
        start_btn <= 1'b1;

        for(j=0; j<128; j++)
            message[j] = $random % 8'hFF;
        message[0] = 'd0;
        message[1] = 'd0;
        message[2] = 'd0;
        message[3] = 'd10; // 40 bytes to the first segment

        message[44] = 'd0;
        message[45] = 'd0;
        message[46] = 'd0;
        message[47] = 'd40; // 160 bytes to the following segments

		@(posedge clk);

		send_block(message, 1, 0);
		send_block(message, 2, 1);
		send_block(message, 2, 0);
		send_block(message, 3, 0);
		send_block(message, 4, 0);
		send_EOT();

		repeat(100) @(posedge clk);
		$finish;
	end

    task send_EOT();
        send_byte(8'h04);
    endtask

    task send_block(input [7:0] message [128], input [7:0] block_num, input have_error);

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

    task send_byte(input [7:0] data);

        repeat(`XM_CYC_PER_BIT) @(posedge clk);

        rx_pin <= 1'b0; // indicates start

        for(j=0; j<8; j++) begin
            repeat(`XM_CYC_PER_BIT) @(posedge clk);
            rx_pin <= data[j]; // first data bit
        end

        repeat(`XM_CYC_PER_BIT) @(posedge clk);
        rx_pin <= 1'b1; // end of byte

    endtask: send_byte



endmodule
