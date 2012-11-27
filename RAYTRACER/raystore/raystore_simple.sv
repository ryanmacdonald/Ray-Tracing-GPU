module raystore_simple
#(parameter SB_WIDTH=8)
(
	input logic clk, rst,

	input  logic                 us_valid,
	input  logic [SB_WIDTH-1:0]  us_sb_data,
	input  rayID_t               raddr,
	output logic                 us_stall,

	input  logic     we,
	input  ray_vec_t wdata,
	input  rayID_t   waddr,

	output logic                ds_valid,
	output logic [SB_WIDTH-1:0] ds_sb_data,
	output ray_vec_t            ds_rd_data,
	input  logic                ds_stall
);

	always @(*) assert(!((raddr == waddr) && we && us_valid));

	typedef struct packed {
		logic [SB_WIDTH-1:0] sb_data;
		ray_vec_t            rd_data;
	} rs_fifo_data_t;

	// signal declarations

	// PVS
	logic                 pvs_ds_valid;
	logic [SB_WIDTH-1:0]  pvs_ds_data;
	logic                 pvs_ds_stall;

	// FIFO
	logic [1:0] num_left_in_fifo;
	logic fifo_we;
	logic fifo_re;
	logic fifo_empty;
	rs_fifo_data_t fifo_data_in;
	rs_fifo_data_t fifo_data_out;

	// block RAM
	ray_vec_t bram_data_out;

	// continuous assignments

	// primary outputs
	assign ds_valid = ~fifo_empty;
	assign ds_rd_data = fifo_data_out.rd_data;
	assign ds_sb_data = fifo_data_out.sb_data;

	// pvs inputs
	assign pvs_ds_stall = ds_stall;

	// fifo inputs
	assign fifo_data_in.sb_data = pvs_ds_data;
	assign fifo_data_in.rd_data = bram_data_out;
	assign fifo_re = ~fifo_empty & ~ds_stall;
	assign fifo_we = pvs_ds_valid;

	pipe_valid_stall #(.WIDTH(SB_WIDTH),.DEPTH(2)) pvs(
		.clk, .rst,
		.us_valid,
		.us_data(us_sb_data),
		.us_stall,
		.ds_valid(pvs_ds_valid),
		.ds_data(pvs_ds_data),
		.ds_stall(pvs_ds_stall),
		.num_left_in_fifo);

	bram_dual_rw_512x192 bram(
		.aclr(rst),
		.clock(clk),
		.data(wdata),
		.rdaddress(raddr),
		.wraddress(waddr),
		.wren(we),
		.q(bram_data_out));

	fifo #(.WIDTH($bits(rs_fifo_data_t)), .DEPTH(3)) rs_fifo(
		.clk, .rst,
		.data_in(fifo_data_in),
		.we(fifo_we),
		.re(fifo_re),
		.full(), // not used here
		.exists_in_fifo(), // not used here
		.empty(fifo_empty),
		.data_out(fifo_data_out),
		.num_left_in_fifo);

endmodule: raystore_simple
