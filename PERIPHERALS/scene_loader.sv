`default_nettype none

typedef enum logic [1:0] {KDTREE, LISTS, UTTM, COLORS_NORMS} SegType;

typedef struct packed {
	logic getting_size;
	SegType current_seg;
	logic [24:0] seg_size;
	logic [24:0] seg_offset_cnt;
} sl_state;

module scene_loader(
    output logic [24:0] sl_addr, // SDRAM width
    output logic [31:0] sl_io, // SDRAM width
    output logic sl_we,
    output logic sl_done,
    input logic [7:0] xmodem_data_byte,
    input logic [7:0] sl_block_num,
    input logic xmodem_saw_valid_msg_byte,
    input logic xmodem_saw_valid_block,
    input logic xmodem_saw_invalid_block,
    input logic xmodem_receiving_repeat_block,
    input logic xmodem_done,
    input logic clk, rst
);

	// independent of checkpoint logic

    logic byte0_ready, byte1_ready, byte2_ready, byte3_ready;
    logic received_four_bytes;

    logic block_done;
    logic inc_meta_cnt;
    logic clr_byte_cnt;
    logic [6:0] byte_cnt;
	logic [24:0] base_addr; // TODO: this can surely be made smaller

    logic [11:0] meta_block_num; // 8 + 5 = 13. 25 - 13 = 12.
    logic [24:0] addr_offset;

	logic [31:0] four_xmodem_bytes;
    logic [7:0] data_reg0, data_reg1, data_reg2;

    sl_state is, cs, good_ns, ns;
    sl_state checkpoint, next_checkpoint;

    logic segment_done;
    assign segment_done = (cs.seg_offset_cnt == cs.seg_size);

//    assign addr_offset = {meta_block_num, sl_block_num, byte_cnt[6:2]}; // not used anymore, I think
    assign sl_addr = base_addr + cs.seg_offset_cnt; // TODO: consider using concatenation

    assign received_four_bytes = byte3_ready & xmodem_saw_valid_msg_byte;

    assign sl_done = xmodem_done;
    assign sl_io = four_xmodem_bytes;
    assign sl_we = received_four_bytes & ~cs.getting_size;

    assign block_done = (byte_cnt == 7'd127);
    assign inc_meta_cnt = (sl_block_num == 8'd255 & xmodem_saw_valid_block);
    assign clr_byte_cnt = block_done && xmodem_saw_valid_msg_byte;

    counter #(7, 7'd0) byte_counter(.cnt(byte_cnt), .inc(xmodem_saw_valid_msg_byte), .clr(clr_byte_cnt), .clk, .rst);
    counter #(12, 12'd0) meta_counter (.cnt(meta_block_num), .inc(inc_meta_cnt), .clr(1'b0), .clk, .rst);

    assign four_xmodem_bytes = {data_reg0, data_reg1, data_reg2, xmodem_data_byte};

    assign byte0_ready = (byte_cnt[1:0] == 2'b00);
    assign byte1_ready = (byte_cnt[1:0] == 2'b01);
    assign byte2_ready = (byte_cnt[1:0] == 2'b10);
    assign byte3_ready = (byte_cnt[1:0] == 2'b11);

    ff_ar_en #(8,8'd0) data_register0 (.q(data_reg0), .d(xmodem_data_byte), .en(byte0_ready), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register1 (.q(data_reg1), .d(xmodem_data_byte), .en(byte1_ready), .clk, .rst);
    ff_ar_en #(8,8'd0) data_register2 (.q(data_reg2), .d(xmodem_data_byte), .en(byte2_ready), .clk, .rst);

	// what follows is based on checkpoints

	// initial state assignments

	assign is.getting_size = 1'b1;
	assign is.current_seg = KDTREE;
	assign is.seg_size = 'b0;
	assign is.seg_offset_cnt = 'b0;

	logic need_to_init;
	ff_ar #(1,1'b1) init_flag_ff(.q(need_to_init), .d(1'b0), .clk, .rst);

	// next state logic for the good case

	always_comb begin
		good_ns.getting_size = cs.getting_size;
		if(cs.getting_size && received_four_bytes)
			good_ns.getting_size = 1'b0;
		else if(~cs.getting_size && segment_done)
			good_ns.getting_size = 1'b1;
	end

	always_comb begin
		if(~cs.getting_size) begin
			case(cs.current_seg)
				KDTREE: good_ns.current_seg = (segment_done) ? LISTS : KDTREE;
				LISTS: good_ns.current_seg = (segment_done) ? UTTM : LISTS;
//				UTTM: good_ns.current_seg = (segment_done) ? COLORS_NORMS : UTTM; // uncomment this when ready for shader cache
				UTTM: good_ns.current_seg = (segment_done) ? KDTREE : UTTM; // comment when ready for shader cache
				COLORS_NORMS: good_ns.current_seg = (segment_done) ? KDTREE : COLORS_NORMS;
				default: good_ns.current_seg = KDTREE;
			endcase
		end
		else
			good_ns.current_seg = cs.current_seg;
	end

	assign good_ns.seg_size = (cs.getting_size && ~good_ns.getting_size) ? four_xmodem_bytes[24:0] : cs.seg_size;

	always_comb begin
		good_ns.seg_offset_cnt = cs.seg_offset_cnt;
		if(segment_done)
			good_ns.seg_offset_cnt = 'b0;
		else if(received_four_bytes & ~cs.getting_size)
			good_ns.seg_offset_cnt = cs.seg_offset_cnt + 1'b1;
	end

	// end of good case next state logic

	// what to do when a valid or invalid block is received

	logic repeated_block_flag;
	logic repeated_block_flag_next;
	assign repeated_block_flag_next = (xmodem_saw_valid_block) ? 1'b0 : (xmodem_receiving_repeat_block) ? 1'b1 : repeated_block_flag;
	ff_ar #(1,1'b0) rbf(.q(repeated_block_flag), .d(repeated_block_flag_next), .clk, .rst);

	logic restore, save;
	assign restore = xmodem_saw_invalid_block | (repeated_block_flag & xmodem_saw_valid_block);
	assign save = xmodem_saw_valid_block & ~repeated_block_flag;

	assign ns =              (need_to_init) ? is : (restore) ? checkpoint : good_ns;
	assign next_checkpoint = (need_to_init) ? is : (save)    ? cs         : checkpoint;

	ff_ar #(.W($bits(sl_state))) current_state_reg(.q(cs), .d(ns), .clk, .rst);
	ff_ar #(.W($bits(sl_state))) checkpoint_reg(.q(checkpoint), .d(next_checkpoint), .clk, .rst);

	always_comb begin
		case(cs.current_seg)
			KDTREE: base_addr = `T_BASE_ADDR;
			LISTS: base_addr = `L_BASE_ADDR;
			UTTM: base_addr = `I_BASE_ADDR;
			COLORS_NORMS: base_addr = `S_BASE_ADDR;
			default: base_addr = 'b0;
		endcase
	end

endmodule: scene_loader
