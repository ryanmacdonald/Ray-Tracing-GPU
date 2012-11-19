`default_nettype none

`define DEPTH 2

module cache

#(parameter 
	SIDE_W=8,
	ADDR_W=8,
	RDATA_W=16,

	// NOTE: following should add up to ADDR_W
	TAG_W=3,
	INDEX_W=4,
	NUM_LINES=(1<<INDEX_W), // TODO: make sure block ram only has this many lines
	BLK_W=1,

	RIF_DEPTH=(`DEPTH+3),
	MRF_DEPTH=(RIF_DEPTH+`DEPTH)
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
	input  logic [RDATA_W-1:0] from_mh_data,
	input  logic               from_mh_valid,
	output logic               to_mh_stall,

	// data to miss handler
	output logic [TAG_W+INDEX_W-1:0]  to_mh_addr,
	output logic                      to_mh_valid,
	input  logic                      from_mh_stall,

	// downstream interface
	output logic [RDATA_W-1:0] ds_rdata,
	output logic [SIDE_W-1:0]  ds_sb_data,
	output logic               ds_valid,
	input  logic               ds_stall
);

typedef struct packed {
	logic [SIDE_W-1:0] side;
	logic [ADDR_W-1:0] addr;
} pvs_data_t;

typedef struct packed {
	logic [RDATA_W-1:0] rdata;
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
	logic [RDATA_W-1:0] wdata;
	logic cache_we;
	logic [TAG_W-1:0] pipe_tag;

	// outputs of cache storage
	logic [RDATA_W-1:0] rdata;
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
	logic [$clog2(`DEPTH+1):0] pvs_num_left_in_fifo;

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
	logic [$clog2(`DEPTH+1):0] hdf_num_left_in_fifo;

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
	assign pipe_tag = pvs_ds_data.addr[TAG_W+INDEX_W+BLK_W-1:INDEX_W+BLK_W]; // just tag
	assign raddr = (rif_re) ? rif_data_out.addr: us_addr;
	assign waddr = rif_data_out.addr;
	assign wdata = from_mh_data;
	assign cache_we = rif_re & rif_wait_flag;

	// PVS assignments
	assign pvs_ds_stall = ds_stall;
	assign pvs_us_valid = (us_valid & ~rif_full) | rif_re;
	assign pvs_us_data.side = (rif_re) ? rif_data_out.side : us_sb_data;
	assign pvs_us_data.addr = (rif_re) ? rif_data_out.addr : us_addr;
	assign pvs_num_left_in_fifo = hdf_num_left_in_fifo;

	// MRF assignments
	assign mrf_we = pvs_ds_valid & miss & ~exists_in_mrf;
	assign mrf_re = ~from_mh_stall;
	assign mrf_data_in = pvs_ds_data.addr[ADDR_W-1:BLK_W]; // tag and index

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
		.RDATA_W(RDATA_W),
		.TAG_W(TAG_W),
		.INDEX_W(INDEX_W),
		.NUM_LINES(NUM_LINES),
		.BLK_W(BLK_W))
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

// TODO: make wdata able to write only certain blocks
module cache_storage
#(parameter 
	SIDE_W=8,
	ADDR_W=8,
	RDATA_W=16,

	TAG_W=3,
	INDEX_W=4,
	NUM_LINES=(1<<INDEX_W),
	BLK_W=1,

	RIF_DEPTH=(`DEPTH+3),
	MRF_DEPTH=(`DEPTH+3)
)(
		// upstream side
	input logic [ADDR_W-1:0] waddr,
	input logic [RDATA_W-1:0] wdata,
	input logic cache_we,
	input logic [ADDR_W-1:0] raddr,
	// downstream side
	input logic [TAG_W-1:0] pipe_tag,
	output  logic [RDATA_W-1:0] rdata,
	output logic miss,
	output logic hit,
	input logic clk, rst
);

	// NOTE: this is just a simulation model
	// TODO: implement real block rams

	logic [RDATA_W-1:0] way0 [1<<(INDEX_W)];
	logic [RDATA_W-1:0] way1 [1<<(INDEX_W)];

	logic hit0, hit1;

	logic [TAG_W:0] tagstore0 [1<<(INDEX_W)]; // no -1 because one bit is needed for valid
	logic [TAG_W:0] tagstore1 [1<<(INDEX_W)];

	logic [RDATA_W-1:0] rdata0a, rdata0b, rdata1a, rdata1b;

	logic [TAG_W-1:0] tag0a, tag0b, tag1a, tag1b;
	logic [TAG_W-1:0] wr_tag; 
	logic [INDEX_W-1:0] rd_index, wr_index;

	logic valid0a, valid0b, valid1a, valid1b;

	assign rd_index = raddr[INDEX_W+BLK_W-1:BLK_W];
	assign wr_tag = waddr[TAG_W+INDEX_W+BLK_W-1:INDEX_W+BLK_W];
	assign wr_index = waddr[INDEX_W+BLK_W-1:BLK_W];

	logic way_choice;

	int i;
	always_ff @(posedge clk, posedge rst) begin

		// initialize tagstore valid bits to 0
		if(rst) begin
			valid0a <= 1'b0;
			valid1a <= 1'b0;
			valid0b <= 1'b0;
			valid1b <= 1'b0;
			for(i=0; i < 1<<INDEX_W; i++) begin
				tagstore0[i][TAG_W] <= 1'b0;
				tagstore1[i][TAG_W] <= 1'b0;
			end
		end
		else begin

			rdata0a <= way0[rd_index];
			rdata1a <= way1[rd_index];

			{valid0a,tag0a} <= tagstore0[rd_index];
			{valid1a,tag1a} <= tagstore1[rd_index];

			if(cache_we) begin
				way_choice = {$random} % 2;
				if(way_choice) begin // set valid bits to one
					way0[wr_index] <= wdata;
					tagstore0[wr_index] <= {1'b1,wr_tag};
				end
				else begin
					way1[wr_index] <= wdata;
					tagstore1[wr_index] <= {1'b1,wr_tag};
				end
				if(rd_index == wr_index) begin
					if(way_choice) begin
						rdata0a <= wdata;
						{valid0a,tag0a} <= {1'b1,wr_tag};
					end
					else begin
						rdata1a <= wdata;
						{valid1a,tag1a} <= {1'b1,wr_tag};
					end
				end
			end

			rdata0b <= rdata0a;
			rdata1b <= rdata1a;

			{valid0b,tag0b} <= {valid0a, tag0a};
			{valid1b,tag1b} <= {valid1a, tag1a};
		end
	end

	assign hit0 = (pipe_tag == tag0b) && valid0b;
	assign hit1 = (pipe_tag == tag1b) && valid1b;

	assign rdata = hit0 ? rdata0b : rdata1b;

	assign hit = hit0 | hit1;
	assign miss = ~hit;

// TODO:
//  * instantiate and wire block rams
//  * implement some replacement policy
//  * think about byte enable for tagstore

endmodule
