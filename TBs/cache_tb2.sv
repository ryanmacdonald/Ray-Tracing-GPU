`default_nettype none

`define CLOCK_PERIOD 20

module cache_tb2;

	// defining for icache
	parameter SIDE_W=8,
              ADDR_W=16,
              RDATA_W=288,
              BLK_W=0,
              INDEX_W=11,
              TAG_W=5,
              NUM_LINES=(1<<INDEX_W),
              RIF_DEPTH=(`DEPTH+3),
              MRF_DEPTH=(`DEPTH+3);

    logic[`numcaches-1:0][24:0] addr_cache_to_sdram;
    logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize;
    logic[`numcaches-1:0] readReq;
    logic[`numcaches-1:0] readValid_out;
    logic[`numcaches-1:0][31:0] readData;
    logic[`numcaches-1:0] doneRead;

    // Write Interface
    logic[24:0] sl_addr;
    logic[31:0] writeData;
    logic  writeReq;
    logic doneWrite;

	 //temp write_error output
	wire write_error;

    // Interface from SDRAM controller to SDRAM chip
    wire  [ 12: 0] zs_addr;
    wire  [  1: 0] zs_ba;
    wire           zs_cas_n;
    wire           zs_cke;
    wire           zs_cs_n;
    wire  [ 31: 0] zs_dq;
    wire  [  3: 0] zs_dqm;
    wire           zs_ras_n;
    wire           zs_we_n;
    wire	   sdram_clk;

	logic clk, rst;

	// interface with cache
	// data from miss handler
	logic [RDATA_W-1:0] from_mh_data;
	logic               from_mh_valid;
	logic               to_mh_stall;

	// data to miss handler
	logic [TAG_W+INDEX_W-1:0]  to_mh_addr;
	logic                      to_mh_valid;
	logic                      from_mh_stall;

	// upstream interface
	logic [SIDE_W-1:0]  us_sb_data;
	logic               us_valid;
	logic [ADDR_W-1:0]  us_addr;
	logic               us_stall;

	// downstream interface
	logic [RDATA_W-1:0] ds_rdata;
	logic [SIDE_W-1:0]  ds_sb_data;
	logic               ds_valid;
	logic               ds_stall;

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		#1;
		forever #(`CLOCK_PERIOD) clk = ~clk;
	end

	// There is no scene loader for this testbench
	initial begin
		sl_addr <= 'b0;
		writeReq <= 1'b0;

		repeat(100) begin
			@(posedge clk);
			writeReq <= 1'b1;
			writeData <= $random;
			sl_addr <= sl_addr + 1'b1;
		end
		@(posedge clk);
		writeReq <= 1'b0;
	end

	initial begin
		us_sb_data <= 'b0;
		us_valid <= 1'b0;
		us_addr <= 'b0;
		ds_stall <= 1'b0;

		repeat(200) @(posedge clk);
		$finish;
	end

	assign readReq[3:1] = 3'b000;

	cache #(.SIDE_W(SIDE_W),
            .ADDR_W(ADDR_W),
            .RDATA_W(RDATA_W),
            .TAG_W(TAG_W),
            .INDEX_W(INDEX_W),
            .NUM_LINES(NUM_LINES),
            .BLK_W(BLK_W),
            .RIF_DEPTH(RIF_DEPTH),
            .MRF_DEPTH(MRF_DEPTH))
			c(.*);

	miss_handler
		#(.RDATA_W(RDATA_W),
		  .TAG_W(TAG_W),
		  .INDEX_W(INDEX_W),
		  .BASE_ADDR(0)) // TODO
		  mh(
			.addr_cache_to_sdram(addr_cache_to_sdram[0]),
			.transSize(transSize[0]),
			.readReq(readReq[0]),
			.readValid_out(readValid_out[0]),
			.readData(readData[0]),
			.doneRead(doneRead[0]),
			.*);

	memory_request_arbiter mra(.*);

    qsys_sdram_mem_model_sdram_partner_module_0    dram(.*,.clk(sdram_clk));

endmodule
