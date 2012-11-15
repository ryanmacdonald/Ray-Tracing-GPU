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
		forever begin
			@(posedge clk);
			if(ds_valid)
				$display("data: %h",ds_data);
		end
	end

	integer a;

	initial begin
		us_valid <= 1'b0;
		us_addr <= 'b0;
		us_sb_data <= 'b0;
		ds_stall <= 1'b0;

		a = $random;
		repeat(10) do_read(a, $random);

		repeat(20) do_read($random, $random);

		repeat(500) @(posedge clk);
		$finish;
	end

	task do_read(input [`ADDR_W-1:0] addr, input logic [`SIDE_W-1:0] side);
		@(posedge clk);
		us_valid <= 1'b1;
		us_addr <= addr;
		us_sb_data <= side;

		@(posedge clk);
		while(us_stall) begin
			@(posedge clk);
		end

		$display("reading from: %h (tag+index: %h). us_sb_data: %h",us_addr,us_addr[`TAG_W+`INDEX_W+`BLK_W-1:`BLK_W], us_sb_data);
		$display("\t(DRAM: %h)",m.memory[us_addr[`TAG_W+`INDEX_W+`BLK_W-1:`INDEX_W]]);
		us_valid <= 1'b0;
	endtask

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

	parameter NUM_STAGES = 8;

	// TODO: model stalls back to cache

	parameter NUM_ADDR = 1<<(`TAG_W+`INDEX_W);

	logic [`RDATA_W-1:0] memory [NUM_ADDR];

	logic [`RDATA_W-1:0] stages [NUM_STAGES];
	logic [NUM_STAGES-1:0] v;

	assign from_mh_stall = 1'b0;

	logic [`TAG_W+`INDEX_W-1:0] mem_addr;
	assign mem_addr = to_mh_addr[`TAG_W+`INDEX_W+`BLK_W-1:`INDEX_W];

	integer i;
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			for(i=0; i< NUM_ADDR; i++)
				memory[i] <= $random;
			from_mh_valid <= 1'b0;
			v <= 'b0;
		end
		else begin
			{v[0], stages[0]} <= {to_mh_valid, memory[mem_addr]};
			for(i=0; i < NUM_STAGES-1; i++)
				{v[i+1], stages[i+1]} <= {v[i], stages[i]};
			{from_mh_valid,from_mh_data} <= {v[NUM_STAGES-1],stages[NUM_STAGES-1]};
		end
	end

endmodule: miss_handler_model
