


module ps2_demo(input logic clk,

		   input logic[3:0] btns,
		   input logic[17:0] switches,
		   
		   // VGA
		   output logic HS, VS,
		   output logic[23:0] VGA_RGB,
		   output logic VGA_clk,
		   output logic VGA_blank,

		   // PS2
		   inout PS2_CLK,
		   inout PS2_DAT);

	logic start,rst, stripes_sel, sq_sel;
	assign start = ~btns[0];
	assign rst   = btns[3];

	assign stripes_sel = switches[0];
	assign sq_sel = switches[1];

	keys_t keys;


        logic [32:0] shift_data;
        logic ps2_clk, ps2_data;
        logic ps2_data_out, ps2_clk_out;
        logic clk_en, data_en, pkt_rec;
        logic[7:0] data_pkt_HD;
        assign data_pkt_HD = 8'hFF;
        assign ps2_clk = clk_en ? 1'b1 : PS2_CLK;
        assign ps2_data = data_en ? 1'b1 : PS2_DAT;
        assign PS2_CLK = clk_en ? ps2_clk_out : 1'bz;
        assign PS2_DAT = data_en ? ps2_data_out : 1'bz;
        ps2               mouse(.iSTART(start),.iRST_n(~rst),.iCLK_50(clk),
                                .ps2_clk(ps2_clk),.ps2_data(ps2_data),
                                .ps2_clk_out(ps2_clk_out),.ps2_dat_out(ps2_data_out),
                                .ce(clk_en),.de(data_en),.shift_reg(shift_data),
                                .pkt_rec(pkt_rec),.cnt11());

        ps2_parse         parse(.clk,.rst_b(~rst),
                                .ps2_pkt_DH(shift_data[7:0]),
                                .rec_ps2_pkt(pkt_rec),.keys(keys));




	logic[9:0] sq_row, sq_col, sq_row_n, sq_col_n;
	frame_buffer_handler fbh(.pb_re(),.pb_empty(),.pb_data(),.sram_oe_b(),
				 .sram_we_b(),.sram_ce_b(),.sram_addr(),.sram_io(),
				 .sram_ub_b(),.sram_lb_b(),.HS,.VS,.VGA_clk,.VGA_blank,
				 .VGA_RGB,.stripes_sel,.sq_sel,.sq_row,.sq_col,.clk,.rst);

	ff_ar #(10,0) y(.q(sq_col),.d(sq_col_n),.clk,.rst);
	ff_ar #(10,0) x(.q(sq_row),.d(sq_row_n),.clk,.rst);


	always_comb begin
		case({keys.w[0],keys.a[0],keys.s[0],keys.d[0]})
			4'b1000: sq_row_n = sq_row - 9'd1;
			4'b0100: sq_col_n = sq_col + 9'd1;
			4'b0010: sq_row_n = sq_row + 9'd1;
			4'b0001: sq_col_n = sq_col - 9'd1;
			default:begin
				sq_col_n = sq_col; sq_row_n = sq_row;
			end	
		endcase
	end


endmodule: ps2_demo
