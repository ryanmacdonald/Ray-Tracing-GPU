module cache_and_miss_handler
#(parameter 
	SIDE_W=8,
	ADDR_W=8,
	LINE_W=16,
	BLK_W=8,
	TAG_W=3,
	INDEX_W=4,
	NUM_LINES=(1<<INDEX_W),
	BO_W=1,
	BASE_ADDR=0) (

	// upstream interface
	input  logic [SIDE_W-1:0]  us_sb_data,
	input  logic               us_valid,
	input  logic [ADDR_W-1:0]  us_addr,
	output logic               us_stall,

	// downstream interface
	output logic [BLK_W-1:0] ds_rdata,
	output logic [SIDE_W-1:0]  ds_sb_data,
	output logic               ds_valid,
	input  logic               ds_stall,

    output logic [24:0]                  addr_cache_to_sdram,
    output logic [$clog2(`maxTrans)-1:0] transSize,
    output logic                         readReq,
    input  logic                         readValid_out,
    input  logic [31:0]                  readData,
    input  logic                         doneRead,

	input logic clk, rst
);

	logic [LINE_W-1:0] from_mh_data;
	logic               from_mh_valid;
	logic               to_mh_stall;
	logic [TAG_W+INDEX_W-1:0]  to_mh_addr;
	logic                      to_mh_valid;
	logic                      from_mh_stall;

	cache #(.SIDE_W(SIDE_W),
            .ADDR_W(ADDR_W),
            .LINE_W(LINE_W),
            .BLK_W(BLK_W),
            .TAG_W(TAG_W),
            .INDEX_W(INDEX_W),
            .NUM_LINES(NUM_LINES),
            .BO_W(BO_W))
			c(.*);

	miss_handler
		#(.LINE_W(LINE_W),
		  .TAG_W(TAG_W),
		  .INDEX_W(INDEX_W),
		  .BASE_ADDR(BASE_ADDR))
		  mh(.*);
			

endmodule
