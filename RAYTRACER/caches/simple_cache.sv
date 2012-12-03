
module simple_cache
#(parameter 
	SIDE_W=8,
	ADDR_W=8,
	LINE_W=32,
	BLK_W=16,

	TAG_W=3,
	INDEX_W=4,
	NUM_LINES=(1<<INDEX_W),
	BO_W=1,
	BASE_ADDR=0
)
(
	input logic clk, rst,

	input logic segment_done,

	// upstream interface
	input  logic [SIDE_W-1:0]  us_sb_data,
	input  logic               us_valid,
	input  logic [ADDR_W-1:0]  us_addr,
	output logic               us_stall,

	input logic [31:0]         sl_io,
	input logic                sl_we,
	input logic [24:0]         sl_addr, // TODO: use this in the code

	// downstream interface
	output logic [BLK_W-1:0]   ds_rdata,
	output logic [SIDE_W-1:0]  ds_sb_data,
	output logic               ds_valid,
	input  logic               ds_stall
);

	localparam NUM_REQ = LINE_W/32;

	logic bram_we;
	logic base_addr_matches;

	logic write_to_write_data_reg;

	logic [24:0] base_addr;
	assign base_addr = BASE_ADDR;
	assign base_addr_matches = sl_addr[24:23] == base_addr[24:23];
	assign write_to_write_data_reg = sl_we & base_addr_matches;

	logic [INDEX_W-1:0] waddr;

	logic [0:(1<<BO_W)-1][BLK_W-1:0] rdata;

	/**************** address counter ****************/

	logic [INDEX_W-1:0] addr_cnt, addr_cnt_next;
	logic last_addr;
	assign last_addr = (addr_cnt == NUM_REQ);

	always_comb begin
		if(write_to_write_data_reg)
			addr_cnt_next = addr_cnt + 1'b1;
		else if(last_addr && bram_we)
			addr_cnt_next = 'b0;
		else
			addr_cnt_next = addr_cnt;
	end
	ff_ar #(.W(INDEX_W)) addr_counter(.q(addr_cnt), .d(addr_cnt_next), .clk, .rst);


	/**************** line counter ****************/

	logic [INDEX_W-1:0] line_cnt, next_line_cnt;
	assign waddr = line_cnt;

	always_comb begin
		if(last_addr)
			next_line_cnt = line_cnt + 1'b1;
		else
			next_line_cnt = line_cnt;
	end
	ff_ar #(.W(INDEX_W)) line_counter(.q(line_cnt), .d(next_line_cnt), .clk, .rst);

	/**************** address register ****************/

	logic ld_addr;
	assign ld_addr = sl_we; // TODO: is this  right?
	logic [24:0] addr, next_addr;
	always_comb begin
		next_addr = (ld_addr) ? sl_addr : addr;
	end
	ff_ar #(.W(25)) addr_reg(.q(addr), .d(sl_addr), .clk, .rst);

	/**************** write data register ****************/

	logic [0:NUM_REQ-1][31:0] write_data, next_write_data;
	always_comb begin
		next_write_data = write_data;
		if(write_to_write_data_reg)
			next_write_data[addr_cnt] = sl_io;
	end
	ff_ar #(.W(LINE_W)) write_data_reg(.clk, .rst, .q(write_data), .d(next_write_data));

	/**************** pvs ****************/

	logic [1:0]          num_left_in_fifo;
	logic                fifo_we;
	logic [SIDE_W-1:0]   pvs_ds_data;

	typedef struct packed {
		logic [BLK_W-1:0]  rdata;
		logic [SIDE_W-1:0] sb_data;
	} fifo_data_t;

	fifo_data_t fifo_data_out, fifo_data_in;

	pipe_valid_stall #(.WIDTH(SIDE_W), .DEPTH(2)) pvs (
		.clk, .rst,
		.us_valid,
		.us_data(us_sb_data),
		.us_stall,
		.ds_valid(fifo_we),
		.ds_data(pvs_ds_data),
		.ds_stall,
		.num_left_in_fifo);

	generate
		if(BO_W != 0) begin
			logic [BO_W-1:0] bo_a1;
			logic [BO_W-1:0] bo_a2;

			ff_ar #(.W(BO_W)) bo_a1_reg(.q(bo_a1), .d(us_addr[BO_W-1:0]), .clk, .rst);
			ff_ar #(.W(BO_W)) bo_a2_reg(.q(bo_a2), .d(bo_a1), .clk, .rst);
			assign fifo_data_in.rdata = rdata[bo_a2];
		end
		else begin
			assign fifo_data_in.rdata = rdata;
		end
	endgenerate


	assign fifo_data_in.sb_data = pvs_ds_data;
	assign ds_rdata = fifo_data_out.rdata;
	assign ds_sb_data = fifo_data_out.sb_data;

	/**************** fifo ****************/

	logic fifo_empty;

	fifo #(.WIDTH($bits(fifo_data_t)), .DEPTH(3)) cache_fifo(
		.clk, .rst,
		.data_in(fifo_data_in),
		.we(fifo_we),
		.re(~ds_stall),
		.full(), // not used
		.exists_in_fifo(), // not used
		.empty(fifo_empty),
		.data_out(fifo_data_out),
		.num_left_in_fifo);

	assign ds_valid = ~fifo_empty;

	/**************** block ram ****************/

	assign bram_we = (last_addr | segment_done) & base_addr_matches;

	generate
		if(NUM_LINES == 1024 && LINE_W == 288) begin : icache_generate
			bram_dual_rw_1024x288 bram(
				.aclr(rst),
				.rdaddress(us_addr[INDEX_W+BO_W-1:BO_W]),
				.wraddress(waddr), // TODO
				.clock(clk),
				.data(write_data),
				.wren(bram_we),
				.q(rdata)
			);
		end
		else if(NUM_LINES == 512 && LINE_W == 384) begin : tcache_generate
			bram_dual_rw_512x384 bram(
				.aclr(rst),
				.rdaddress(us_addr[INDEX_W+BO_W-1:BO_W]),
				.wraddress(waddr), // TODO
				.clock(clk),
				.data(write_data),
				.wren(bram_we),
				.q(rdata)
			);
		end
		else if(NUM_LINES == 1024 && LINE_W == 256) begin : lcache_generate
			bram_dual_rw_1024x256 bram(
				.aclr(rst),
				.rdaddress(us_addr[INDEX_W+BO_W-1:BO_W]),
				.wraddress(waddr), // TODO
				.clock(clk),
				.data(write_data),
				.wren(bram_we),
				.q(rdata)
			);
		end
		else if(NUM_LINES == 1024 && LINE_W == 320) begin : scache_generate
			initial begin
				assert(1) $fatal("scache_generate block has not been written yet in cache.sv");
			end
		end
		else begin : no_cache_generate
			initial begin
				assert(1) $fatal("no cache parameters matched in cache.sv -- no cache is being generated");
			end
		end
	endgenerate

endmodule

