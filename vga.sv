`default_nettype none

module vga(
    output logic display_done,
    output logic HS, VS,
	output logic VGA_clk,
	output logic VGA_blank,
    output logic [9:0] vga_row,
    output logic [9:0] vga_col,
    output logic clk_25M,
    input logic clk_50M, rst);

    logic clr_clk, clr_line, inc_line;
    logic HS_b, VS_b;
    logic [9:0] clk_cnt;
    logic [9:0] line_cnt;
    logic max_line;

    logic clr_line_50M;
    assign display_done = clr_line && ~clr_line_50M;

    always @(posedge clk_50M, posedge rst) begin
        if(rst)    clr_line_50M <= 1'b0;
        else        clr_line_50M <= clr_line;
    end

    assign HS = ~HS_b;
    assign VS = ~VS_b;

    assign clr_clk = inc_line;
    assign clr_line = clr_clk && max_line;

    always_ff @(posedge clk_50M, posedge rst) begin
        if(rst)    clk_25M <= 1'b0;
        else        clk_25M <= ~clk_25M;
    end
	 
	 logic HS_porch_b, VS_porch_b;
	 range_check #(10) VS_portch_rc(.is_between(VS_porch_b), .val(vga_row), .low(10'd0), .high(10'd479));
	 range_check #(10) HS_portch_rc(.is_between(HS_porch_b), .val(vga_col), .low(10'd0), .high(10'd639));

	 assign VGA_blank = ~(~HS_porch_b | ~VS_porch_b);
	 assign VGA_clk = ~clk_50M; // asserted low

    vga_counter #(10,10'd0) clk_counter(.cnt(clk_cnt), .clk(clk_25M), .rst, .up(1'b1), .en(1'b1), .clr(clr_clk));
    vga_counter #(10,10'd0) line_counter(.cnt(line_cnt), .clk(clk_25M), .rst, .up(1'b1), .en(inc_line), .clr(clr_line));

    compare #(10) cmp_clk(.eq(inc_line), .aGT(), .bGT(), .a(clk_cnt), .b(10'd799));
    compare #(10) cmp_line(.eq(max_line), .aGT(), .bGT(), .a(line_cnt), .b(10'd520));

    range_check #(10) HS_rc(.is_between(HS_b), .val(clk_cnt), .low(10'd0), .high(10'd95));
    addSub #(10) col_offset(.result(vga_col), .z(), .n(), .a(clk_cnt), .b(10'd144), .add(1'b0));

    range_check #(10) VS_rc(.is_between(VS_b), .val(line_cnt), .low(10'd0), .high(10'd1));
    addSub #(10) row_offset(.result(vga_row), .z(), .n(), .a(line_cnt), .b(10'd31), .add(1'b0));

endmodule

module stripes(
    output logic [2:0] vga_color,
    input logic [9:0] vga_row,
    input logic [9:0] vga_col);

    logic black, blue, green, cyan, red, purple, yellow, white;

    range_check #(10) black_rc(black,vga_col,10'd0,10'd79);
    range_check #(10) blue_rc(blue,vga_col,10'd80,10'd159);
    range_check #(10) green_rc(green,vga_col,10'd160,10'd239);
    range_check #(10) cyan_rc(cyan,vga_col,10'd240,10'd319);
    range_check #(10) red_rc(red,vga_col,10'd320,10'd479);
    range_check #(10) purple_rc(purple,vga_col,10'd400,10'd479);
    range_check #(10) yellow_rc(yellow,vga_col,10'd480,10'd559);
    range_check #(10) white_rc(white,vga_col,10'd560,10'd639);

    assign vga_color[2] = red | purple | yellow | white;
    assign vga_color[1] = green | cyan | yellow | white;
    assign vga_color[0] = blue | cyan | purple | white;

endmodule

// TODO: merge with counter in library.sv
module vga_counter #(parameter W=1, RV={W{1'b0}}) (
    output logic [W-1:0] cnt,
    input logic clk, rst,
    input logic up, en, clr);

    always_ff @(posedge clk, posedge rst) begin
        if(rst)
            cnt <= RV;
        else if(clr)
            cnt <= RV;
        else if(en)
            cnt <= (up) ? cnt + 1'b1 : cnt - 1'b1;
    end

endmodule
