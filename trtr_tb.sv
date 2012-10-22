`default_nettype none

`define CLK_PERIOD 20

module trtr_tb;

    // general IO
    logic [17:0] LEDR;
    logic [8:0] LEDG;
    logic [17:0] switches;
    logic [3:0] btns;

	// VGA
    logic HS, VS;
    logic [23:0] VGA_RGB;
    logic VGA_clk;
    logic VGA_blank;

	// RS-232/UART
    logic tx, rts;
    logic rx_pin;

	// SRAM
    logic [19:0] sram_addr;
    wire [15:0] sram_io;
    logic sram_we_b;
    logic sram_oe_b;
    logic sram_ce_b;
    logic sram_ub_b;
    logic sram_lb_b;

    logic clk;
    logic rst;
    assign rst = ~btns[3];

    trtr tr(.*);
    sram sr(.*);

    initial begin
        clk <= 1'b0;
        btns[3] <= 1'b1;
        #1;
        btns[3] <= 1'b0;
        #1;
        btns[3] <= 1'b1;
        forever #(`CLK_PERIOD/2) clk = ~clk;
    end

    integer j;
    logic [7:0] message [128];

    initial begin

        switches <= 18'b0;
        btns <= 4'b1111;
        rx_pin <= 1'b1;

        @(posedge clk);
        btns[0] <= 1'b0;
        repeat(100) @(posedge clk);
        btns[0] <= 1'b1;

        repeat(10) @(posedge clk);

        for(j=0; j<128; j++)
            message[j] = $random % 8'hFF;

		// white pixel
        message[0] = 8'hff;
        message[1] = 8'hff;
        message[2] = 8'hff;

        send_block(message,8'd1,1'b0);

        for(j=0; j<128; j++)
            message[j] = $random % 8'hFF;
        send_block(message,8'd2,1'b1);

        repeat (10000) @(posedge clk);
        send_block(message,8'd2,1'b0);

        send_EOT();

//        repeat(2500000) @(posedge clk);

        repeat(1000000) @(posedge clk);

		// use the "write pixel" feature
        @(posedge clk);
        btns[1] <= 1'b0;
        repeat(100) @(posedge clk);
        btns[1] <= 1'b1;

        repeat(1000000) @(posedge clk);

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

    endtask

    task send_byte(input [7:0] data);

        repeat(434) @(posedge clk);

        rx_pin <= 1'b0; // indicates start

        for(j=0; j<8; j++) begin
            repeat(434) @(posedge clk);
            rx_pin <= data[j]; // first data bit
        end

        repeat(434) @(posedge clk);
        rx_pin <= 1'b1; // end of byte

    endtask


endmodule: trtr_tb
