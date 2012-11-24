`default_nettype none

module sram(
    input logic clk,
    input logic rst,
    input logic [19:0] sram_addr,
    inout wire [15:0] sram_io,
    input logic sram_ce_b,
    input logic sram_we_b,
    input logic sram_oe_b,
    input logic sram_ub_b,
    input logic sram_lb_b);

    logic [15:0] memory ['h100000]; // 1024K x 16 bit
    logic [15:0] data_from_mem;

    assign sram_io = (~sram_oe_b) ? data_from_mem : 16'bz;

    assign data_from_mem[7:0] = (~sram_lb_b) ? memory[sram_addr][7:0] : 'bz;
    assign data_from_mem[15:8] = (~sram_ub_b) ? memory[sram_addr][15:8] : 'bz;

    always_ff @(posedge clk, posedge rst) begin
        if(rst) begin
            integer i;
            for(i=0; i < 'h100000; i++)
                memory[i] <= 16'hFFFF;
        //        memory[i] <= $random() & (16'hFFFF);
        end
        else begin
            if(~sram_we_b) begin
                if(~sram_lb_b)
                    memory[sram_addr][7:0] <= sram_io[7:0];
                if(~sram_ub_b)
                    memory[sram_addr][15:8] <= sram_io[15:8];
            end
        end
    end

endmodule
