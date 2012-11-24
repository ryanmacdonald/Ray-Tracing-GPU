`default_nettype none

`define DEPTH 2

module cache

#(parameter 
	SIDE_W=8,
	ADDR_W=8,
	LINE_W=16,
	BLK_W=8,

	// NOTE: following should add up to ADDR_W
	TAG_W=3,
	INDEX_W=4,
	NUM_LINES=(1<<INDEX_W),
	BO_W=1,

	RIF_DEPTH=(`DEPTH+3),
	MRF_DEPTH=(RIF_DEPTH+`DEPTH+1)
)
(
	input logic clk, rst,

	// upstream interface
	input  logic [SIDE_W-1:0]  us_sb_data,
	input  logic               us_valid,
	input  logic [ADDR_W-1:0]  us_addr,
	output logic               us_stall,

	// miss handler interface
	// data from miss handler
	input  logic [LINE_W-1:0] from_mh_data,
	input  logic               from_mh_valid,
	output logic               to_mh_stall,

	// data to miss handler
	output logic [TAG_W+INDEX_W-1:0]  to_mh_addr,
	output logic                      to_mh_valid,
	input  logic                      from_mh_stall,

	// downstream interface
	output logic [BLK_W-1:0] ds_rdata,
	output logic [SIDE_W-1:0]  ds_sb_data,
	output logic               ds_valid,
	input  logic               ds_stall
);

typedef struct packed {
	logic [SIDE_W-1:0] side;
	logic [ADDR_W-1:0] addr;
} pvs_data_t;

typedef struct packed {
	logic [BLK_W-1:0] rdata;
	logic [SIDE_W-1:0] side;
	logic [ADDR_W-1:0] addr;
} hdf_data_t;

typedef struct packed {
	logic [ADDR_W-1:0] addr;
	logic [SIDE_W-1:0] side;
	logic flag;
} rif_data_t;

/************** signal declarations **************/

// cache storage
	// inputs to cache storage
	logic [ADDR_W-1:0] waddr;
	logic [ADDR_W-1:0] raddr;
	logic [LINE_W-1:0] wdata;
	logic cache_we;
	logic [TAG_W-1:0] pipe_tag;
	logic [BO_W-1:0] pipe_bo;

	// outputs of cache storage
	logic [BLK_W-1:0] rdata;
	logic miss;
	logic hit;

// pipe valid stall
	// upstream side
	pvs_data_t pvs_us_data;
	logic pvs_us_valid;
	logic pvs_us_stall;

	// downstream side
	logic pvs_ds_stall;
	logic pvs_ds_valid;
	pvs_data_t pvs_ds_data;
	logic [$clog2(`DEPTH+2)-1:0] pvs_num_left_in_fifo;

// miss request fifo
	// inputs
	logic [TAG_W+INDEX_W-1:0] mrf_data_in;
	logic mrf_we;

	// outputs
	logic mrf_empty;
	logic [TAG_W+INDEX_W-1:0] mrf_data_out;
	logic mrf_re;
	logic exists_in_mrf;

// hit data fifo
	// upstream
	hdf_data_t hdf_data_in;
	logic hdf_we;
	logic [$clog2(`DEPTH+2)-1:0] hdf_num_left_in_fifo;

	// downstream
	logic hdf_empty;
	hdf_data_t hdf_data_out;
	logic hdf_re;

// reissue fifo buffer
	rif_data_t rif_buf_data_in;
	logic rif_buf_we;

	// downstream
	logic rif_buf_empty;
	rif_data_t rif_buf_data_out;
	logic rif_buf_re;

// reissue fifo
	// upstream
	rif_data_t rif_data_in;
	logic rif_we;
	logic rif_full;

	// downstream
	logic rif_empty;
	rif_data_t rif_data_out;
	logic rif_re;
	logic rif_wait_flag;

/************** continuous assigns **************/

	assign us_stall = rif_re | rif_full | pvs_us_stall;
	assign to_mh_stall = from_mh_valid & (~rif_re | ~rif_wait_flag);
	assign to_mh_addr = mrf_data_out;
	assign to_mh_valid = ~mrf_empty;
	assign ds_sb_data = hdf_data_out.side;
	assign ds_rdata = hdf_data_out.rdata;
	assign ds_valid = ~hdf_empty;

	// cache storage assignments
	assign pipe_tag = pvs_ds_data.addr[TAG_W+INDEX_W+BO_W-1:INDEX_W+BO_W]; // just tag
	assign raddr = (rif_re) ? rif_data_out.addr: us_addr;
	assign waddr = rif_data_out.addr;
	assign wdata = from_mh_data;
	assign cache_we = rif_re & rif_wait_flag;

	generate
		if(BO_W != 0) begin : bo_w_case
			assign pipe_bo = pvs_ds_data.addr[BO_W-1:0]; // just block offset
		end
		else begin
			assign pipe_bo = 1'b0;
		end
	endgenerate 

	// PVS assignments
	assign pvs_ds_stall = ds_stall;
	assign pvs_us_valid = (us_valid & ~rif_full) | rif_re;
	assign pvs_us_data.side = (rif_re) ? rif_data_out.side : us_sb_data;
	assign pvs_us_data.addr = (rif_re) ? rif_data_out.addr : us_addr;
	assign pvs_num_left_in_fifo = hdf_num_left_in_fifo;

	// MRF assignments
	assign mrf_we = pvs_ds_valid & miss & ~exists_in_mrf;
	assign mrf_re = ~from_mh_stall;
	assign mrf_data_in = pvs_ds_data.addr[ADDR_W-1:BO_W]; // tag and index

	// HDF assignments
	assign hdf_data_in.side = pvs_ds_data.side;
	assign hdf_data_in.rdata = rdata;
	assign hdf_data_in.addr = pvs_ds_data.addr;
	assign hdf_we = pvs_ds_valid & hit;
	assign hdf_re = ~ds_stall;

	// RIF buffer assignments
	assign rif_buf_we = pvs_ds_valid & miss;
	assign rif_buf_re = ~rif_buf_empty & ~rif_full;
	assign rif_buf_data_in.addr = pvs_ds_data.addr;
	assign rif_buf_data_in.side = pvs_ds_data.side;
	assign rif_buf_data_in.flag = ~exists_in_mrf;

	// RIF assignments
	assign rif_wait_flag = rif_data_out.flag;
	assign rif_re = ~rif_empty & ~pvs_us_stall & (~rif_wait_flag | from_mh_valid);
	assign rif_we = rif_buf_re;
	assign rif_data_in = rif_buf_data_out;

/************** module instantiations **************/

	cache_storage #(
		.SIDE_W(SIDE_W),
		.ADDR_W(ADDR_W),
		.LINE_W(LINE_W),
		.BLK_W(BLK_W),
		.TAG_W(TAG_W),
		.INDEX_W(INDEX_W),
		.NUM_LINES(NUM_LINES),
		.BO_W(BO_W))
	csu (.*);

	pipe_valid_stall #(.WIDTH($bits(pvs_data_t)), .DEPTH(`DEPTH)) pvs(
		.clk, .rst,
		.us_valid(pvs_us_valid),
		.us_data(pvs_us_data),
		.us_stall(pvs_us_stall),

		.ds_valid(pvs_ds_valid),
		.ds_data(pvs_ds_data),
		.ds_stall(pvs_ds_stall),

		.num_left_in_fifo(pvs_num_left_in_fifo)
	);

	fifo #(.WIDTH(TAG_W+INDEX_W), .DEPTH(MRF_DEPTH))
	MRF(
		.clk, .rst,
		.data_in(mrf_data_in),
		.we(mrf_we),
		.re(mrf_re),
		.full(),
		.empty(mrf_empty),
		.data_out(mrf_data_out),
		.num_left_in_fifo(),
		.exists_in_fifo(exists_in_mrf)
	);

	fifo #(.WIDTH($bits(hdf_data_t)), .DEPTH(`DEPTH+1))
	HDF(
		.clk, .rst,
		.data_in(hdf_data_in),
		.we(hdf_we),
		.re(hdf_re),
		.full(),
		.empty(hdf_empty),
		.data_out(hdf_data_out),
		.num_left_in_fifo(hdf_num_left_in_fifo),
		.exists_in_fifo()
	);

	fifo #(.WIDTH($bits(rif_data_t)), .DEPTH(`DEPTH+1))
	RIF_buffer(
		.clk, .rst,
		.data_in(rif_buf_data_in),
		.we(rif_buf_we),
		.re(rif_buf_re),
		.full(),
		.empty(rif_buf_empty),
		.data_out(rif_buf_data_out),
		.num_left_in_fifo(),
		.exists_in_fifo()
	);

	fifo #(.WIDTH($bits(rif_data_t)), .DEPTH(RIF_DEPTH))
	RIF(
		.clk, .rst,
		.data_in(rif_data_in),
		.we(rif_we),
		.re(rif_re),
		.full(rif_full),
		.empty(rif_empty),
		.data_out(rif_data_out),
		.num_left_in_fifo(),
		.exists_in_fifo()
	);

endmodule

module cache_storage
#(parameter
	SIDE_W=8,
	ADDR_W=8,
	LINE_W=16,
	BLK_W=8,

	TAG_W=3,
	INDEX_W=4,
	NUM_LINES=(1<<INDEX_W),
	BO_W=1,
	NUM_BLK=(1<<BO_W)
)(
		// upstream side
	input logic [ADDR_W-1:0] waddr,
	input logic [0:NUM_BLK-1][BLK_W-1:0] wdata,
	input logic cache_we,
	input logic [ADDR_W-1:0] raddr,
	// downstream side
	input logic [TAG_W-1:0] pipe_tag,
	input logic [BO_W-1:0] pipe_bo,
	output  logic [BLK_W-1:0] rdata,
	output logic miss,
	output logic hit,
	input logic clk, rst
);

	localparam TAG_PAD_W = 7 - TAG_W;

	// flips every clock cycle; used for pseudo random replacement
	logic way_choice;
	ff_ar way_choice_ff(.q(way_choice), .d(~way_choice), .clk, .rst);

	logic [LINE_W-1:0] way0_data_in;
	logic [LINE_W-1:0] way0_data_out;
	logic [LINE_W-1:0] way1_data_in;
	logic [LINE_W-1:0] way1_data_out;
	logic [15:0] ts_data_in;
	logic [15:0] ts_data_out;
	logic [1:0] ts_be;
	logic [$clog2(NUM_LINES)-1:0] cache_addr;
	logic way0_we, way1_we;

	logic [0:NUM_BLK-1][BLK_W-1:0] rdata_line;
	logic hit0, hit1;
	logic valid0, valid1;

	logic [INDEX_W-1:0] rd_index;
	logic [INDEX_W-1:0] wr_index;
	logic [TAG_W-1:0] wr_tag;

	assign rd_index = raddr[INDEX_W+BO_W-1:BO_W];
	assign wr_tag = waddr[TAG_W+INDEX_W+BO_W-1:INDEX_W+BO_W];
	assign wr_index = waddr[INDEX_W+BO_W-1:BO_W];

	assign way0_data_in = wdata;
	assign way1_data_in = wdata;
	assign ts_data_in = {1'b1,{TAG_PAD_W{1'b0}}, wr_tag, 1'b1,{TAG_PAD_W{1'b0}}, wr_tag};
	assign ts_be = {way0_we, way1_we};
	assign cache_addr = cache_we ? wr_index : rd_index;
	assign way0_we = cache_we & ~way_choice;
	assign way1_we = cache_we & way_choice;

	// these flip flops are needed so that once we get the data from the tagstore,
	// we know which way we wrote to. this is needed because the output is xxxx for
	// the byte we don't write to in the tagstore so the valid bit will be x. this means
	// we have to use the write enable bit from 2 cycles ago to decide whether it is a hit or miss
	logic way0_we1, way0_we2;
	ff_ar way0_we_ff0(.q(way0_we1), .d(way0_we), .clk, .rst);
	ff_ar way0_we_ff1(.q(way0_we2), .d(way0_we1), .clk, .rst);

	logic way1_we1, way1_we2;
	ff_ar way1_we_ff0(.q(way1_we1), .d(way1_we), .clk, .rst);
	ff_ar way1_we_ff1(.q(way1_we2), .d(way1_we1), .clk, .rst);

	assign valid0 = ts_data_out[15] ; // needs to be consistent with ts_data_in
	assign valid1 = ts_data_out[7] ; // needs to be consistent with ts_data_in
	assign hit0 = (~way1_we2 & valid0 & (ts_data_out[TAG_W+7:8] == pipe_tag)) | way0_we2;
	assign hit1 = (~way0_we2 & valid1 & (ts_data_out[TAG_W-1:0] == pipe_tag)) | way1_we2 ;

	assign rdata_line = hit0 ? way0_data_out : way1_data_out;
	assign rdata = rdata_line[pipe_bo];
	assign hit = hit0 | hit1;
	assign miss = ~hit;

	generate
		if(NUM_LINES == 1024 && LINE_W == 288) begin : icache_generate
			bram_single_rw_1024x288 way0_bram(
				.aclr(rst),
				.address(cache_addr),
				.clock(clk),
				.data(way0_data_in),
				.wren(way0_we),
				.q(way0_data_out));

			bram_single_rw_1024x288 way1_bram(
				.aclr(rst),
				.address(cache_addr),
				.clock(clk),
				.data(way1_data_in),
				.wren(way1_we),
				.q(way1_data_out));

			// TODO: Ross cannot spell bram, apparently
			brwam_single_rw_1024x16 tagstore_bram(
				.aclr(rst),
				.address(cache_addr),
				.byteena(ts_be),
				.clock(clk),
				.data(ts_data_in),
				.wren(way0_we | way1_we),
				.q(ts_data_out));
		end
		if(NUM_LINES == 512 && LINE_W == 384) begin : tcache_generate
			bram_single_rw_512x384 way0_bram(
				.aclr(rst),
				.address(cache_addr),
				.clock(clk),
				.data(way0_data_in),
				.wren(way0_we),
				.q(way0_data_out));

			bram_single_rw_512x384 way1_bram(
				.aclr(rst),
				.address(cache_addr),
				.clock(clk),
				.data(way1_data_in),
				.wren(way1_we),
				.q(way1_data_out));

			bram_single_rw_512x16 tagstore_bram(
				.aclr(rst),
				.address(cache_addr),
				.byteena(ts_be),
				.clock(clk),
				.data(ts_data_in),
				.wren(way0_we | way1_we),
				.q(ts_data_out));
		end
		if(NUM_LINES == 1024 && LINE_W == 256) begin : lcache_generate
			bram_single_rw_1024x256 way0_bram(
				.aclr(rst),
				.address(cache_addr),
				.clock(clk),
				.data(way0_data_in),
				.wren(way0_we),
				.q(way0_data_out));

			bram_single_rw_1024x256 way1_bram(
				.aclr(rst),
				.address(cache_addr),
				.clock(clk),
				.data(way1_data_in),
				.wren(way1_we),
				.q(way1_data_out));

			// TODO: Ross cannot spell bram, apparently
			brwam_single_rw_1024x16 tagstore_bram(
				.aclr(rst),
				.address(cache_addr),
				.byteena(ts_be),
				.clock(clk),
				.data(ts_data_in),
				.wren(way0_we | way1_we),
				.q(ts_data_out));

		end
	endgenerate

endmodule
