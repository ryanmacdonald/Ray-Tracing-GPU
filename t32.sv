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

    logic read_error; // being used for DRAM testing

    logic xmodem_done, sl_done;
    logic xmodem_saw_valid_block;
    logic xmodem_saw_valid_msg_byte;
    logic [7:0] xmodem_data_byte;
    logic [7:0] sl_block_num;

    logic [24:0] sl_addr; // SDRAM width
    logic [31:0] sl_io; // SDRAM width
    logic sl_we;

    // MRA signal declarations
    // Read Inteface 
    logic[`numcaches-1:0][24:0] addr_cache_to_sdram;
    logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize;
    logic[`numcaches-1:0] readReq;
    logic[`numcaches-1:0] readValid_out;
    logic[`numcaches-1:0][31:0] readData;
    logic[`numcaches-1:0] doneRead;

    // Write Interface
    logic[31:0] writeData;
    logic  writeReq;
    logic doneWrite_out;


    // FBH signal declarations
    logic pb_re, pb_we;
    logic pb_empty, pb_full;
    pixel_buffer_entry_t pb_data_in, pb_data_out;
    logic stripes_sel;

    // Continuous assigns
    assign stripes_sel = switches[0];
    assign rst = ~btns[3];
    assign start_btn = btns[0];

    assign LEDR[0] = read_error;

    assign writeReq = sl_we;
    assign writeData = sl_io;

    // Module instantiations

    xmodem xm(.*);


    scene_loader sl(.*);


    memory_request_arbiter mra(.*,.clk(clk),.rst(rst),.zs_addr(dram_addr),
                   .zs_ba(dram_ba),.zs_cas_n(dram_cas_n),
                   .zs_cke(dram_cke),.zs_cs_n(dram_cs_n),.zs_dq(dram_dq),.zs_dqm(dram_dqm),
                   .zs_ras_n(dram_ras_n),.zs_we_n(dram_we_n),.sdram_clk(dram_clk));
    

    temporary_scene_retriever tsr(.*,.sl_done(sl_done),.readReq(readReq[0]),
                  .readAddr(addr_cache_to_sdram[0]),
                  .readData(readData[0]),.readSize(transSize[0]),
                  .readDone(doneRead[0]),.readValid(readValid_out[0]),
                  .pbData(pb_data_in),.pb_we(pb_we),.pb_full(pb_full),
                  .read_error(read_error)); // read_error being used for DRAM testing

    fifo #(.WIDTH($bits(pixel_buffer_entry_t)),.K(5)) pb(.clk,.rst,
                                                         .data_in(pb_data_in),
                                                         .we(pb_we),
                                                         .re(pb_re),
                                                         .full(pb_full),
                                                         .empty(pb_empty),
                                                         .data_out(pb_data_out),
                                                         .num_in_fifo());

    

    frame_buffer_handler fbh(.*,.pb_data(pb_data_out));

endmodule: t_minus_32_days
