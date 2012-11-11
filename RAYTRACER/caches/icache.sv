module cache(
	output logic us_stall,
	input logic re,
	input logic [] addr,
	output logic [] data
	output logic [] addr_to_miss_handler
	input logic ds_stall,
	input logic clk, rst
);

	logic [] tags;
	logic [] tag0, tag1;
	logic valid0, valid1;
	logic hit0, hit1;
	logic hit;

	assign tags = tagstore0[index];
	assign tag0 = tags[];
	assign valid0 = tags[];
	assign tag1 = tags[];
	assign valid1 = tags[]

	assign hit0 = (tag == tag0) && (valid0);
	assign hit1 = (tag == tag1) && (valid1);

	assign hit = hit0 | hit1;

	// TODO: instantiate miss fifo

	// TODO: if hit0, issue read from block RAM set 0
	// TODO: if hit1, issue read from block RAM set 1

	icache_set0_blkram rbram(
		.aclr(rst),
		.address_a(),
		.address_b(),
		.clock(clk),
		.data_a(),
		.data_b(),
		.wren_a(),
		.wren_b(1'b0),
		.q_a(rd_data0),
		.q_b(rd_data1));

	icache_set1_blkram rbram(
		.aclr(rst),
		.address_a(),
		.address_b(),
		.clock(clk),
		.data_a(),
		.data_b(),
		.wren_a(),
		.wren_b(1'b0),
		.q_a(rd_data0),
		.q_b(rd_data1));

	icache_tagstore_blkram rbram(
		.aclr(rst),
		.address_a(),
		.address_b(),
		.clock(clk),
		.data_a(),
		.data_b(),
		.wren_a(),
		.wren_b(1'b0),
		.q_a(rd_data0),
		.q_b(rd_data1));


endmodule
