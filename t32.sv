`default_nettype none

module t_minus_32_days(
    // general IO
    output logic [17:0] LEDR,
    output logic [8:0] LEDG,
    input logic [17:0] switches,
    input logic [3:0] btns,

    // RS-232/UART
    output logic tx, rts,
    input logic rx_pin,

    // VGA
    output logic HS, VS,
    output logic [23:0] VGA_RGB,
    output logic VGA_clk,
    output logic VGA_blank,

    // SRAM
    output logic [19:0] sram_addr,
    inout wire [15:0] sram_io,
    output logic sram_we_b,
    output logic sram_oe_b,
    output logic sram_ce_b,
    output logic sram_ub_b,
    output logic sram_lb_b,

    // SDRAM
    output logic [12:0] dram_addr,
    inout wire [31:0] dram_dq,
    output logic [1:0] dram_ba, // bank address
    output logic [3:0] dram_dqm, // data mask
    output logic dram_ras_n,
    output logic dram_cas_n,
    output logic dram_cke,
    output logic dram_clk,
    output logic dram_we_n,
    output logic dram_cs_n,

    // PS2
    inout PS2_CLK,
    inout PS2_DAT,
     
    input logic clk);

    // Signal declarations

    logic rst;
    logic start_btn;

    logic xmodem_done;
    logic xmodem_saw_valid_block;
    logic xmodem_saw_valid_msg_byte;
    logic [7:0] xmodem_data_byte;
    logic [7:0] sl_block_num;

    logic [24:0] sl_addr; // SDRAM width
    logic [31:0] sl_io; // SDRAM width
    logic sl_we;

    // Continuous assigns
    assign rst = ~btns[3];
	assign start_btn = btns[0];

    // Module instantiations

    xmodem xm(.*);

    scene_loader sl(.*);

//    memory_request_arbiter mra(.*);

	/*
    temporary_scene_retriever tsr();

    pixel_buffer pb();
    */

   /*
    logic pb_re;
    logic pb_empty;
    pixel_buffer_entry_t pb_data;
    logic stripes_sel;
    assign stripes_sel = switches[0];

    frame_buffer_handler fbh(.*);
    */

endmodule: t_minus_32_days
