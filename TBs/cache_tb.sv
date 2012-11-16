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

	//////////////// rst/clk initial blocks ////////////////

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

	//////////////// stimuli initial blocks ////////////////

	int num_reads = 30;
	logic [$bits(hdf_data_t)-1:0] read_table [30];
	logic [$bits(hdf_data_t)-1:0] issue_table [30];

	integer a,pre_id, post_id;
	int num_reads_done = 0;
	initial begin
		forever begin
			@(posedge clk);
			if(ds_valid & ~ds_stall) begin
				$display("data: %h",ds_data);
				post_id = ds_data[`SIDE_W-1:0];
				read_table[post_id] = ds_data;
				num_reads_done++;
			end
		end
	end

	integer i;
	integer all_equal;

	initial begin
		us_valid <= 1'b0;
		us_addr <= 'b0;
		us_sb_data <= 'b0;
		ds_stall <= 1'b0;

		pre_id=0;
		all_equal = 1;

		a = $random;
		@(posedge clk);
		repeat(10) begin
			do_read(a, pre_id);
			pre_id++;
		end
		us_valid <= 1'b0;

		@(posedge clk);
		repeat(20) begin
			do_read($random, pre_id[`SIDE_W-1:0]);
			pre_id++;
		end
		us_valid <= 1'b0;

		repeat(500) @(posedge clk);

		$display("num_reads: %d",num_reads);
		$display("read table:");
		for(i=0; i<num_reads; i++) begin
			$display("%h: %h",i,read_table[i]);
		end
		$display("issue table:");
		for(i=0; i<num_reads; i++) begin
			if(issue_table[i] != read_table[i]) begin
				all_equal = 0;
				$display("%h: %h *",i,issue_table[i]);
			end
			else begin
				$display("%h: %h",i,issue_table[i]);
			end
		end

		if(!all_equal)
			$display("NOT ALL READS RETURNED CORRECT DATA");
		else
			$display("ALL READS RETURNED CORRECT DATA :)");

		$finish;
	end


	initial begin
		forever begin
			@(posedge clk);
			if(ds_valid)
				ds_stall = {$random} % 2;
			else
				ds_stall = 1'b0;
		end
	end

	//////////////// tasks ////////////////

	int data;
	task do_read(input [`ADDR_W-1:0] addr, input logic [`SIDE_W-1:0] side);
//		@(posedge clk);
		us_valid <= 1'b1;
		us_addr <= addr;
		us_sb_data <= side;

		data = m.memory[addr[`TAG_W+`INDEX_W+`BLK_W-1:`INDEX_W]];
		issue_table[side] = {data, side};
		$display("side: %h addr: %h (t+i: %h). DRAM: %h",side, addr,addr[`TAG_W+`INDEX_W+`BLK_W-1:`BLK_W],data);

		@(posedge clk);
		while(us_stall) begin
			@(posedge clk);
		end

//		us_valid <= 1'b0;
	endtask

	//////////////// modules ////////////////

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

	parameter NUM_STAGES = 80;

	parameter NUM_ADDR = 1<<(`TAG_W+`INDEX_W);

	logic [`RDATA_W-1:0] memory [NUM_ADDR];

	logic [`RDATA_W-1:0] stages [NUM_STAGES];
	logic [NUM_STAGES-1:0] v;

	logic [`TAG_W+`INDEX_W-1:0] mem_addr;
	assign mem_addr = to_mh_addr[`TAG_W+`INDEX_W+`BLK_W-1:`INDEX_W];

	assign from_mh_stall = to_mh_stall & from_mh_valid;

	integer i;
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			for(i=0; i< NUM_ADDR; i++)
				memory[i] <= $random;
			from_mh_valid <= 1'b0;
			v <= 'b0;
		end
		else begin
			if(~to_mh_stall || ~from_mh_valid) begin
				{v[0], stages[0]} <= {to_mh_valid, memory[mem_addr]};
				for(i=0; i < NUM_STAGES-1; i++)
					{v[i+1], stages[i+1]} <= {v[i], stages[i]};
				{from_mh_valid,from_mh_data} <= {v[NUM_STAGES-1],stages[NUM_STAGES-1]};
			end
		end
	end

endmodule: miss_handler_model
