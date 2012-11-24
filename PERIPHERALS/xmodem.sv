`default_nettype none

// NOTE: defines have been moved to structs
// (so that they can be accessed by testbenches without duplication)

module xmodem(
    output logic xmodem_done,
    output logic xmodem_saw_valid_block,      // to scene loader
    output logic xmodem_saw_invalid_block,      // to scene loader
    output logic xmodem_receiving_repeat_block,      // to scene loader
    output logic xmodem_saw_valid_msg_byte,       // to scene loader
    output logic [7:0] xmodem_data_byte,  // to scene loader
    output logic [7:0] sl_block_num, // TODO: delete
    output logic tx,
    output logic rts,
    input logic start_btn,
    input logic rx_pin,
    input logic clk, rst
);

	logic saw_valid_msg_byte;
	logic saw_valid_block, saw_invalid_block;
	logic repeat_block;
	logic [7:0] data_byte;

	assign xmodem_saw_valid_msg_byte = saw_valid_msg_byte;
	assign xmodem_saw_valid_block = saw_valid_block;
	assign xmodem_saw_invalid_block = saw_invalid_block;
	assign xmodem_data_byte = data_byte;
	assign xmodem_receiving_repeat_block = repeat_block;

    logic start;
    logic rx_ff, rx;
    // handle metastability
    ff_ar #(1,1'b1) rx_ff1(.q(rx_ff), .d(rx_pin), .clk, .rst);
    ff_ar #(1,1'b1) rx_ff2(.q(rx), .d(rx_ff), .clk, .rst);

    negedge_detector start_ned(.ed(start), .in(start_btn), .clk, .rst);

    assign rts = 1'b1;

    logic send_ACK;
    logic send_NAK;
    logic saw_EOT_block;
    logic saw_valid_byte;
    logic saw_msg_byte;
    logic saw_block;
    logic valid_block;

    assign saw_valid_msg_byte = saw_valid_byte & saw_msg_byte;
    assign saw_valid_block = saw_block && valid_block;
    assign saw_invalid_block = saw_block && ~valid_block;

    xmodem_bitlevel_fsmd xbitfsmd(.*);
    xmodem_blocklevel_fsmd xblkfsmd(.*);
    xmodem_protocol_fsmd xprofsmd(.*);
    xmodem_transmitter_fsmd xtranfsmd(.*);

endmodule: xmodem

module xmodem_bitlevel_fsmd(
    output logic saw_valid_byte,
    output logic [7:0] data_byte,
    input logic rx,
    input logic clk, rst
);

    logic saw_byte, valid_byte;
    logic max_samples, max_cycles;
    logic init_cycle_cnt, clr_cycle_cnt;
    logic clr_sample_cnt;
    logic take_sample;
    logic negedge_rx;

    assign saw_valid_byte = saw_byte & valid_byte;

    xmodem_bitlevel_fsm bitf(.*);
    xmodem_bitlevel_datapath bitd(.*);

endmodule: xmodem_bitlevel_fsmd

module xmodem_bitlevel_fsm(
    output logic saw_byte,
    output logic init_cycle_cnt, clr_cycle_cnt,
    output logic clr_sample_cnt,
    output logic take_sample,
    input logic max_samples, max_cycles,
    input logic negedge_rx,
    input logic clk, rst
);


    enum logic {A, B, X=1'bx} curr_state, next_state;

    // next state logic

    always_comb begin
        next_state = X;
        case(curr_state)
            A: next_state = negedge_rx ? B : A;
            B: next_state = max_samples ? A : B;
            default: next_state = X;
        endcase
    end

    always_ff @(posedge clk, posedge rst) begin
        if(rst)
            curr_state <= A;
        else
            curr_state <= next_state;
    end

    // output logic

    always_comb begin
        // default outputs
        clr_sample_cnt = 1'b0;
        clr_cycle_cnt = 1'b0;
        init_cycle_cnt = 1'b0;
        saw_byte = 1'b0;
        take_sample = 1'b0;

        case(curr_state)
            A: begin
                clr_sample_cnt = negedge_rx;
                init_cycle_cnt = negedge_rx;
            end
            B:  begin
                clr_cycle_cnt = max_cycles;
                take_sample = max_cycles;
                saw_byte = max_samples;
            end
        endcase
    end

endmodule: xmodem_bitlevel_fsm

module xmodem_bitlevel_datapath(
    output logic max_cycles,
    output logic max_samples,
    output logic valid_byte,
    output logic negedge_rx,
    output logic [7:0] data_byte,
    input logic rx,
    input logic take_sample,
    input logic init_cycle_cnt, clr_cycle_cnt,
    input logic clr_sample_cnt,
    input logic clk, rst
);

    logic [3:0] sample_cnt;
    logic [$clog2(`XM_CYC_PER_BIT)-1:0] cycle_cnt;
    logic [8:0] data;

    assign max_samples = (sample_cnt == `XM_NUM_SAMPLES) ? 1'b1 : 1'b0;
    assign max_cycles = (cycle_cnt == `XM_CYC_PER_BIT) ? 1'b1 : 1'b0;

    assign data_byte = data[7:0];
    assign valid_byte = data[8];

    negedge_detector rx_ned(.ed(negedge_rx), .in(rx), .clk, .rst);
    shifter #(9) data_sr(.q(data), .d(rx), .en(take_sample), .clr(1'b0), .clk, .rst);
    counter #(4,4'b0) sample_counter(.cnt(sample_cnt), .inc(take_sample), .clr(clr_sample_cnt), .clk, .rst);

    logic [$clog2(`XM_CYC_PER_BIT)-1:0] next_cycle_cnt;

    always_comb begin
        if(clr_cycle_cnt)
            next_cycle_cnt = 'b0;
        else if(init_cycle_cnt)
            next_cycle_cnt = `XM_CYC_PER_BIT >> 1'b1;
        else
            next_cycle_cnt = cycle_cnt + 1'b1;
    end

    ff_ar #($clog2(`XM_CYC_PER_BIT), 'b0) cycle_counter(.q(cycle_cnt), .d(next_cycle_cnt), .clk, .rst);

endmodule: xmodem_bitlevel_datapath

module xmodem_blocklevel_fsmd(
    output logic saw_block,
    output logic valid_block,
    output logic saw_EOT_block,
    output logic saw_msg_byte,
    output logic repeat_block,
    output logic [7:0] sl_block_num, // TODO: delete. no longer needed
    input logic [7:0] data_byte,
    input logic saw_valid_byte,
    input logic clk, rst
);

    logic clr_byte_cnt_and_chksum,
          ld_block_num,
          en_block_num_err_ff,
          inc_byte_cnt_and_chksum,
          saw_SOH_byte, saw_EOT_byte,
          saw_128_bytes;

    xmodem_blocklevel_fsm blkf(.*);
    xmodem_blocklevel_datapath blkd(.*);

endmodule: xmodem_blocklevel_fsmd

module xmodem_blocklevel_fsm(
    output logic saw_block,
    output logic saw_EOT_block,
    output logic clr_byte_cnt_and_chksum,
    output logic ld_block_num,
    output logic en_block_num_err_ff,
    output logic inc_byte_cnt_and_chksum,
    output logic saw_msg_byte,
    input logic saw_valid_byte,
    input logic saw_128_bytes,
    input logic saw_SOH_byte,
    input logic saw_EOT_byte,
    input logic clk, rst
);

    // may want to just make this the input

    enum logic[2:0] {A, B, C, D, E, X=3'bx} curr_state, next_state;

    // next state logic
    always_comb begin
        case(curr_state)
            A: next_state = saw_valid_byte && saw_SOH_byte ? B : A;
            B: next_state = saw_valid_byte ? C : B;
            C: next_state = saw_valid_byte ? D: C;
            D: next_state = saw_128_bytes && saw_valid_byte ? E : D;
            E: next_state = saw_valid_byte ? A : E;
        endcase
    end

    always_ff @(posedge clk, posedge rst) begin
        if(rst)
            curr_state <= A;
        else
            curr_state <= next_state;
    end

    // output logic
    always_comb begin
        // default outputs
        clr_byte_cnt_and_chksum = 1'b0;
        ld_block_num = 1'b0;
        en_block_num_err_ff = 1'b0;
        inc_byte_cnt_and_chksum = 1'b0;
        saw_block = 1'b0;
        saw_EOT_block = 1'b0;
        saw_msg_byte = 1'b0;

        case(curr_state)
            A: begin
                clr_byte_cnt_and_chksum = 1'b1;
                saw_EOT_block = saw_valid_byte & saw_EOT_byte;
            end
            B: ld_block_num = saw_valid_byte;
            C: en_block_num_err_ff = saw_valid_byte;
            D: begin
                saw_msg_byte = saw_valid_byte;
                inc_byte_cnt_and_chksum = saw_valid_byte;
            end
            E: saw_block = saw_valid_byte;
        endcase
    end

endmodule: xmodem_blocklevel_fsm

module xmodem_blocklevel_datapath(
    output logic saw_SOH_byte, saw_EOT_byte,
                 saw_128_bytes,
                 valid_block,
	output logic repeat_block,
    output logic [7:0] sl_block_num, // TODO: delete. no longer needed
    input logic saw_block,
    input logic clr_byte_cnt_and_chksum,
                ld_block_num,
                en_block_num_err_ff,
                inc_byte_cnt_and_chksum,
    input logic [7:0] data_byte,
    input logic clk, rst
);

    logic block_num_err;
    logic chksum_err;

    logic [6:0] byte_cnt;
    logic [7:0] block_num;
    logic [7:0] prev_block_num;
    logic [7:0] chksum;
    logic [7:0] next_chksum;

    assign sl_block_num = prev_block_num; // TODO: delete

    logic valid_block_num_bits, valid_block_num, block_num_err_comb;

    assign saw_SOH_byte = (data_byte == `SOH) ? 1'b1 : 1'b0;
    assign saw_EOT_byte = (data_byte == `EOT) ? 1'b1 : 1'b0;
    assign saw_128_bytes = (byte_cnt == 7'd127) ? 1'b1 : 1'b0;

    assign repeat_block = (block_num == prev_block_num) & en_block_num_err_ff;

    assign valid_block_num_bits = (block_num == ~data_byte) ? 1'b1 : 1'b0;
    assign valid_block_num = ((block_num == prev_block_num) || (block_num == prev_block_num+1'b1)) ? 1'b1 : 1'b0;
    assign block_num_err_comb = ~valid_block_num_bits | ~valid_block_num;

    assign chksum_err = (chksum != data_byte) ? 1'b1 : 1'b0;

    assign valid_block = ~block_num_err & ~chksum_err;

    always_comb begin
        if(clr_byte_cnt_and_chksum)
            next_chksum = 8'h00;
        else if(inc_byte_cnt_and_chksum)
            next_chksum = chksum + data_byte;
        else
            next_chksum = chksum;
    end
    ff_ar #(8,8'b0) chksum_reg(.q(chksum), .d(next_chksum), .clk, .rst);

    ff_ar_en #(8,8'h01) block_num_reg(.q(block_num), .d(data_byte), .en(ld_block_num), .clk, .rst);
    ff_ar_en #(8,8'h00) prev_block_num_reg(.q(prev_block_num), .d(block_num), .en(saw_block & valid_block), .clk, .rst);

    ff_ar_en #(1,1'b0) block_num_err_ff(.q(block_num_err), .d(block_num_err_comb), .en(en_block_num_err_ff), .clk, .rst);
    counter #(7) byte_counter(.cnt(byte_cnt), .clr(clr_byte_cnt_and_chksum), .inc(inc_byte_cnt_and_chksum), .clk, .rst);

endmodule: xmodem_blocklevel_datapath

module xmodem_protocol_fsmd(
    output logic send_ACK, send_NAK,
    output logic xmodem_done,
    input logic start,
    input logic saw_block, valid_block, saw_EOT_block,
    input logic clk, rst
);

    logic timeout,
          time_for_NAK,
          inc_timeout_NAK_cnt,
          inc_NAK_timer,
          inc_invalid_NAK_cnt,
          clr_timeout_NAK_cnt,
          clr_invalid_NAK_cnt,
          clr_NAK_timer;

    xmodem_protocol_fsm xprofsm(.*);
    xmodem_protocol_datapath xprodp(.*);

endmodule: xmodem_protocol_fsmd

module xmodem_protocol_fsm(
    output logic send_ACK,
    output logic send_NAK,
    output logic xmodem_done,
    output logic inc_timeout_NAK_cnt,
    output logic inc_NAK_timer,
    output logic inc_invalid_NAK_cnt,
    output logic clr_timeout_NAK_cnt,
    output logic clr_invalid_NAK_cnt,
    output logic clr_NAK_timer,
    input logic start,
    input logic saw_block, valid_block, saw_EOT_block, timeout,
    input logic time_for_NAK,
    input logic clk, rst
);

    enum logic {A, B, X=1'bx} curr_state, next_state;

    // next state logic
    always_comb begin
        next_state = X;
        case(curr_state)
            A: next_state = start ? B : A;
            B: next_state = (timeout | saw_EOT_block) ? A : B;
            default: next_state = X;
        endcase
    end

    always_ff @(posedge clk, posedge rst) begin
        if(rst)
            curr_state <= A;
        else
            curr_state <= next_state;
    end

    // output logic
    always_comb begin
        // default outputs
        send_ACK = 1'b0;
        send_NAK = 1'b0;
        inc_timeout_NAK_cnt = 1'b0;
        inc_NAK_timer = 1'b0;
        inc_invalid_NAK_cnt = 1'b0;
        clr_timeout_NAK_cnt = 1'b0;
        clr_invalid_NAK_cnt = 1'b0;
        clr_NAK_timer = 1'b0;

        xmodem_done = saw_EOT_block;

        case(curr_state)
            A: begin
                send_ACK = saw_EOT_block;
                send_NAK = start;
            end

            B: begin
                if(time_for_NAK) begin
                    send_NAK = 1'b1;
                    inc_timeout_NAK_cnt = 1'b1;
                    clr_NAK_timer = 1'b1;
                end
                else if(~(saw_block & valid_block)) begin
                    inc_NAK_timer = 1'b1;
                end

                if(saw_block & valid_block) begin
                    send_ACK = 1'b1;
                    clr_timeout_NAK_cnt = 1'b1;
                    clr_invalid_NAK_cnt = 1'b1;
                end
                if(saw_block & ~valid_block) begin
                    send_NAK = 1'b1;
                    inc_invalid_NAK_cnt = 1'b1;
                end
            end
        endcase
    end

endmodule: xmodem_protocol_fsm

module xmodem_protocol_datapath(
    output logic timeout,
                 time_for_NAK,
    input logic inc_timeout_NAK_cnt,
                inc_NAK_timer,
                inc_invalid_NAK_cnt,
                clr_timeout_NAK_cnt,
                clr_invalid_NAK_cnt,
                clr_NAK_timer,
    input logic clk, rst
);

    logic [$clog2(`XM_NUM_CYC_TIMEOUT)-1:0] NAK_timer;
    logic [$clog2(`XM_MAX_RETRY)-1:0] timeout_NAK_cnt;
    logic [$clog2(`XM_MAX_RETRY)-1:0] invalid_NAK_cnt;

    assign time_for_NAK = (NAK_timer == `XM_NUM_CYC_TIMEOUT) ? 1'b1 : 1'b0;
    assign timeout = (timeout_NAK_cnt == `XM_MAX_RETRY) || (invalid_NAK_cnt == `XM_MAX_RETRY) ? 1'b1 : 1'b0;

    counter #($clog2(`XM_MAX_RETRY)) timeout_counter(.cnt(timeout_NAK_cnt), .clr(clr_timeout_NAK_cnt), .inc(inc_timeout_NAK_cnt), .clk, .rst);
    counter #($clog2(`XM_MAX_RETRY)) invalid_counter(.cnt(invalid_NAK_cnt), .clr(clr_invalid_NAK_cnt), .inc(inc_invalid_NAK_cnt), .clk, .rst);
    counter #($clog2(`XM_NUM_CYC_TIMEOUT)) NAK_timer_counter(.cnt(NAK_timer), .clr(clr_NAK_timer), .inc(inc_NAK_timer), .clk, .rst);

endmodule: xmodem_protocol_datapath

module xmodem_transmitter_fsmd(
    output logic tx,
    input logic send_ACK, send_NAK,
    input logic clk, rst
);

    logic inc_cyc_cnt,
          clr_cyc_cnt,
          clr_bit_cnt,
          rot_and_inc_bit_cnt,
          byte_sent, bit_sent,
          ld_ACK_or_NAK_ff;

    xmodem_transmitter_fsm xtranfsm(.*);
    xmodem_transmitter_datapath xtrandp(.*);

endmodule: xmodem_transmitter_fsmd

module xmodem_transmitter_fsm(
    output logic inc_cyc_cnt,
    output logic clr_cyc_cnt,
    output logic clr_bit_cnt,
    output logic rot_and_inc_bit_cnt,
    output logic ld_ACK_or_NAK_ff,
    input logic send_ACK, send_NAK,
    input logic byte_sent, bit_sent,
    input logic clk, rst
);

    enum logic {A, B, X=1'bx} curr_state, next_state;

    // nextstate logic
    always_comb begin
        next_state = X;
        case(curr_state)
            A: next_state = (send_ACK || send_NAK) ? B : A;
            B: next_state = (byte_sent) ? A : B;
        endcase
    end

    always_ff @(posedge clk, posedge rst) begin
        if(rst)
            curr_state <= A;
        else
            curr_state <= next_state;
    end

    // output logic
    always_comb begin
        // default outputs
        inc_cyc_cnt = 1'b0;
        clr_cyc_cnt = 1'b0;
        clr_bit_cnt = 1'b0;
        rot_and_inc_bit_cnt = 1'b0;
        ld_ACK_or_NAK_ff = 1'b0;
        case(curr_state)
            A: begin
                clr_cyc_cnt = 1'b1;
                clr_bit_cnt = 1'b1;
                ld_ACK_or_NAK_ff = 1'b1;
            end
            B: begin
                inc_cyc_cnt = ~bit_sent;
                clr_cyc_cnt = bit_sent;
                rot_and_inc_bit_cnt = bit_sent;
            end
        endcase
    end

endmodule: xmodem_transmitter_fsm

module xmodem_transmitter_datapath(
    output logic tx,
    output logic bit_sent, byte_sent,
    input logic send_ACK,
    input logic ld_ACK_or_NAK_ff,
    input logic inc_cyc_cnt,
    input logic clr_cyc_cnt,
    input logic clr_bit_cnt,
    input logic rot_and_inc_bit_cnt,
    input logic clk, rst
);

    logic [$clog2(`XM_CYC_PER_BIT)-1:0] cyc_cnt;
    logic [3:0] bit_cnt;
    logic [9:0] ACK_bits;
    logic [9:0] NAK_bits;
    logic ACK_or_NAK;

    assign tx = (ACK_or_NAK == 1'b1) ? ACK_bits[0] : NAK_bits[0];

    assign bit_sent = (cyc_cnt == `XM_CYC_PER_BIT) ? 1'b1 : 1'b0;
    assign byte_sent = (bit_cnt == 4'd10) ? 1'b1 : 1'b0;

    ff_ar_en #(1,1'b0) ACK_or_NAK_ff(.q(ACK_or_NAK), .d(send_ACK), .en(ld_ACK_or_NAK_ff), .clk, .rst);
    shifter #(10,{`ACK,1'b0,1'b1}) ACK_sr(.q(ACK_bits), .d(ACK_bits[0]), .en(rot_and_inc_bit_cnt), .clr(1'b0), .clk, .rst);
    shifter #(10,{`NAK,1'b0,1'b1}) NAK_sr(.q(NAK_bits), .d(NAK_bits[0]), .en(rot_and_inc_bit_cnt), .clr(1'b0), .clk, .rst);
    counter #($clog2(`XM_CYC_PER_BIT)) cyc_counter(.cnt(cyc_cnt), .clr(clr_cyc_cnt), .inc(inc_cyc_cnt), .clk, .rst);
    counter #(4) bit_counter(.cnt(bit_cnt), .clr(clr_bit_cnt), .inc(rot_and_inc_bit_cnt), .clk, .rst);

endmodule: xmodem_transmitter_datapath
