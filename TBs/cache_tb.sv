`default_nettype none

`define CLOCK_PERIOD 20

module cache_tb;

	logic clk, rst;

	// upstream interface
	logic [`SIDE_W-1:0]  us_sb_data;
	logic                us_valid;
	logic [`ADDR_W-1:0]  us_addr;
	logic                us_stall;

	// miss handler interface
	// data from miss handler
	logic [`RDATA_W-1:0] from_mh_data;
	logic                from_mh_valid;
	logic                to_mh_stall;

	// data to miss handler
	logic [`ADDR_W-1:0]  to_mh_addr;
	logic                to_mh_valid;
	logic                from_mh_stall;

	// downstream interface
	logic [$bits(hdf_data_t)-1:0] ds_data; // TODO: should use a struct...
	logic                         ds_valid;
	logic                         ds_stall;

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		#1;
		forever #(`CLOCK_PERIOD/2) clk = ~clk;
	end

	initial begin
		us_valid <= 1'b0;
		us_addr <= 'b0;
		us_sb_data <= 'b0;
		ds_stall <= 1'b0;

		@(posedge clk);
		us_valid <= 1'b1;
		us_addr <= $random;

		@(posedge clk)
		us_valid <= 1'b0;

		repeat(50) @(posedge clk);
		$finish;
	end

	cache c(.*);
	miss_handler_model m(.*);

endmodule: cache_tb

module miss_handler_model(
	input logic clk, rst,

	// data from miss handler
	output logic [`RDATA_W-1:0] from_mh_data,
	output logic                from_mh_valid,
	input  logic                to_mh_stall,

	// data to miss handler
	input  logic [`ADDR_W-1:0]  to_mh_addr,
	input  logic                to_mh_valid,
	output logic                from_mh_stall
);

	// TODO: model stalls back to cache

	parameter NUM_ADDR = 1<<(`TAG_W+`INDEX_W);

	logic [`RDATA_W-1:0] memory [NUM_ADDR];

	logic [`RDATA_W-1:0] stage0, stage1, stage2, stage3, stage4;
	logic v0, v1, v2, v3, v4;

	assign from_mh_stall = 1'b0;

	logic [`TAG_W+`INDEX_W-1:0] mem_addr;
	assign mem_addr = to_mh_addr[`TAG_W+`INDEX_W+`BLK_W-1:`INDEX_W];

	integer i;
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			for(i=0; i< NUM_ADDR; i++)
				memory[i] <= $random;
			from_mh_valid <= 1'b0;
			v0 <= 1'b0;
			v1 <= 1'b0;
			v2 <= 1'b0;
			v3 <= 1'b0;
			v4 <= 1'b0;
		end
		else begin
			{v0, stage0} <= {to_mh_valid, memory[mem_addr]};
			{v1, stage1} <= {v0, stage0};
			{v2, stage2} <= {v1, stage1};
			{v3, stage3} <= {v2, stage2};
			{v4, stage4} <= {v3, stage3};
			{from_mh_valid,from_mh_data} <= {v4,stage4};
		end
	end

endmodule: miss_handler_model
