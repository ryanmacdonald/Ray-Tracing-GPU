`default_nettype none

module scene_loader(
    output logic [24:0] sl_addr, // SDRAM width
    output logic [31:0] sl_io, // SDRAM width
    output logic sl_we,
    output logic sl_done,
    input logic [7:0] xmodem_data_byte,
    input logic [7:0] sl_block_num,
    input logic xmodem_saw_valid_msg_byte,
    input logic xmodem_saw_valid_block,
    input logic xmodem_done,
    input logic clk, rst
);

    logic block_done;
    logic inc_meta_cnt;
    logic clr_byte_cnt;
    logic [6:0] byte_cnt;
    logic [7:0] data_reg0, data_reg1, data_reg2;

    logic [11:0] meta_block_num; // 8 + 5 = 13. 25 - 13 = 12.

    assign sl_done = xmodem_done;

    logic byte0_ready, byte1_ready, byte2_ready, byte3_ready;
    assign byte0_ready = (byte_cnt[1:0] == 2'b00);
    assign byte1_ready = (byte_cnt[1:0] == 2'b01);
    assign byte2_ready = (byte_cnt[1:0] == 2'b10);
    assign byte3_ready = (byte_cnt[1:0] == 2'b11);

    ff_ar_en #(8,8'd0) data_register0 (.q(data_reg0), .d(xmodem_data_byte), .en(byte0_ready), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register1 (.q(data_reg1), .d(xmodem_data_byte), .en(byte1_ready), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register2 (.q(data_reg2), .d(xmodem_data_byte), .en(byte2_ready), .clk, .rst);

	logic en_segment_size;
	logic [31:0] segment_size;
	logic [31:0] four_xmodem_bytes;
    ff_ar_en #(32) segment_size_reg (.q(segment_size), .d(four_xmodem_bytes), .en(en_segment_size), .clk. .rst);

	logic inc_seg_cnt, clr_seg_cnt;
	logic [31:0] segment_cnt;
	logic segment_done;

    counter #(32) segment_counter(.cnt(segment_cnt), .clr(clr_seg_cnt), .inc(inc_seg_cnt), .clk, rst);

    assign inc_seg_cnt = (byte3_ready & xmodem_saw_valid_msg_byte) & ~segment_done;
    assign clr_seg_cnt = segment_done;

    enum logic [1:0] {KDTREE=2'b00, LISTS=2'b01, UTTM=2'b10} current_seg;
	logic inc_cur_seg_reg, clr_cur_seg_reg;
    counter #(2) current_seg_reg(.cnt(current_seg), .clr(clr_cur_seg_reg), .inc(inc_cur_seg_reg), .clk, .rst);

    assign segment_done = (segment_cnt == segment_size);

    assign four_xmodem_bytes = {data_reg0, data_reg1, data_reg2, xmodem_data_byte};

//    assign sl_addr = {meta_block_num, sl_block_num, byte_cnt[6:2]};
//    assign sl_io = {xmodem_data_byte, data_reg2, data_reg1, data_reg0};
    assign sl_io = {data_reg0, data_reg1, data_reg2, xmodem_data_byte}; // NOTE: this is new
    assign sl_we = byte3_ready & xmodem_saw_valid_msg_byte;

    assign block_done = (byte_cnt == 7'd127);
    assign inc_meta_cnt = (sl_block_num == 8'd255 & xmodem_saw_valid_block);
    assign clr_byte_cnt = block_done && xmodem_saw_valid_msg_byte;

    counter #(7, 7'd0) byte_counter(.cnt(byte_cnt), .inc(xmodem_saw_valid_msg_byte), .clr(clr_byte_cnt), .clk, .rst);
    counter #(12, 12'd0) meta_counter (.cnt(meta_block_num), .inc(inc_meta_cnt), .clr(1'b0), .clk, .rst);

endmodule: scene_loader
