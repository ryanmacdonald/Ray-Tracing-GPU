`default_nettype none

module scene_loader(
    output logic [24:0] sl_addr, // SDRAM width
    output logic [31:0] sl_io, // SDRAM width
    output logic sl_we,
    input logic [7:0] xmodem_data_byte,
    input logic [7:0] sl_block_num,
    input logic xmodem_saw_valid_msg_byte,
    input logic xmodem_saw_valid_block,
    input logic clk, rst
);

    logic block_done;
    logic inc_meta_cnt;
    logic clr_byte_cnt;
    logic [6:0] byte_cnt;
    logic [7:0] data_reg0, data_reg1, data_reg2;

    logic [11:0] meta_block_num; // 8 + 5 = 13. 25 - 13 = 12.

    logic en_dr0, en_dr1, en_dr2, send;
    assign en_dr0 = (byte_cnt[1:0] == 2'b00);
    assign en_dr1 = (byte_cnt[1:0] == 2'b01);
    assign en_dr2 = (byte_cnt[1:0] == 2'b10);
    assign send   = (byte_cnt[1:0] == 2'b11);

    ff_ar_en #(8,8'd0) data_register0 (.q(data_reg0), .d(xmodem_data_byte), .en(en_dr0), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register1 (.q(data_reg1), .d(xmodem_data_byte), .en(en_dr1), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register2 (.q(data_reg2), .d(xmodem_data_byte), .en(en_dr2), .clk, .rst);

    assign sl_addr = {meta_block_num, sl_block_num, byte_cnt[6:2]};
    assign sl_io = {xmodem_data_byte, data_reg2, data_reg1, data_reg0};
    assign sl_we = send & xmodem_saw_valid_msg_byte;

    assign block_done = (byte_cnt == 7'd127);
    assign inc_meta_cnt = (sl_block_num == 8'd255 & xmodem_saw_valid_block);
    assign clr_byte_cnt = block_done && xmodem_saw_valid_msg_byte;

    counter #(7, 7'd0) byte_counter(.cnt(byte_cnt), .inc(xmodem_saw_valid_msg_byte), .clr(clr_byte_cnt), .clk, .rst);
    counter #(12, 12'd0) meta_counter (.cnt(meta_block_num), .inc(inc_meta_cnt), .clr(1'b0), .clk, .rst);

endmodule: scene_loader
