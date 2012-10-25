`default_nettype none

module scene_loader(
    output logic [19:0] sl_addr,
    output logic [15:0] sl_io,
    output logic sl_we,
    input logic [7:0] data_byte,
    input logic [7:0] sl_block_num,
    input logic saw_valid_msg_byte,
    input logic saw_valid_block,
    input logic clk, rst
);

    logic block_done;
    logic inc_meta_cnt;
    logic clr_byte_cnt;
    logic [6:0] byte_cnt;
    logic [7:0] data_reg;
    logic even_odd;

    logic [5:0] meta_block_num;

    assign sl_addr = {meta_block_num, sl_block_num, byte_cnt[6:1]};
    assign sl_io = {data_byte, data_reg};
    assign sl_we = even_odd & saw_valid_msg_byte;

    assign block_done = (byte_cnt == 7'd127);
    assign inc_meta_cnt = (sl_block_num == 8'd255 & saw_valid_block);
    assign clr_byte_cnt = block_done && saw_valid_msg_byte;

    counter #(7, 7'd0) byte_counter(.cnt(byte_cnt), .inc(saw_valid_msg_byte), .clr(clr_byte_cnt), .clk, .rst);
    counter #(6, 6'd0) meta_counter (.cnt(meta_block_num), .inc(inc_meta_cnt), .clr(1'b0), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register (.q(data_reg), .d(data_byte), .en(~even_odd), .clk, .rst);
    ff_ar_en #(1, 1'b0) even_off_ff (.q(even_odd), .d(~even_odd), .en(saw_valid_msg_byte), .clk, .rst);

endmodule: scene_loader
