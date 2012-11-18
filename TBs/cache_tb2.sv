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
    logic sl_done;
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
	logic [31:0] data_out;
	initial begin
		sl_done <= 1'b0;
		sl_addr <= 'b0;
		writeReq <= 1'b0;

		repeat(10000) @(posedge clk); // give sdram time to initialize

		repeat(1000) begin
			@(posedge clk);
			data_out = $random;
			$display("writeData: %h",data_out);
			writeReq <= 1'b1;
			writeData <= data_out;
			while(~doneWrite) begin
				@(posedge clk);
				writeReq <= 1'b0;
			end
			sl_addr <= sl_addr + 1'b1;
		end
		@(posedge clk);
		sl_done <= 1'b1;
		writeReq <= 1'b0;
	end

	//////////////// copied directly from cache_tb.sv ////////////////
	int num_reads = 30;
	logic [RDATA_W+SIDE_W-1:0] read_table [30];
	logic [RDATA_W+SIDE_W-1:0] issue_table [30];

	integer a,pre_id, post_id;
	int num_reads_done = 0;
	initial begin
		forever begin
			@(posedge clk);
			if(ds_valid & ~ds_stall) begin
				$display("data: %h",{ds_rdata,ds_sb_data});
				post_id = ds_sb_data;
				read_table[post_id] = {ds_rdata,ds_sb_data};
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

		@(posedge clk);

		while(~sl_done)
			@(posedge clk);

		$display("about to do reads...");

		repeat(100)
			@(posedge clk);

//		a = {$random} % (30);
		a = 1;
		@(posedge clk);
		repeat(10) begin
			do_read(a, pre_id);
			pre_id++;
		end
		us_valid <= 1'b0;

		@(posedge clk);
		repeat(20) begin
			do_read($random%(30), pre_id[SIDE_W-1:0]);
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
			if(!(issue_table[i] === read_table[i])) begin
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

	logic [9][31:0] data;
	int translated_addr;
	task do_read(input [ADDR_W-1:0] addr, input logic [SIDE_W-1:0] side);
//		@(posedge clk);
		us_valid <= 1'b1;
		us_addr <= addr;
		us_sb_data <= side;

		translated_addr = 9*addr[ADDR_W-1:BLK_W];

		for(i=0; i<9; i++)
			data[i] = dram.mem_array[translated_addr+i];
		issue_table[side] = {data, side};
		$display("addr: %h (t+i: %h). DRAM: %h side: %h",addr,addr[ADDR_W-1:BLK_W],data,side);

		@(posedge clk);
		while(us_stall) begin
			@(posedge clk);
		end

//		us_valid <= 1'b0;
	endtask

	initial begin
		repeat(200000) @(posedge clk);
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

   /*
	initial begin
		transSize[0] <= 'd9;

		@(posedge clk);

		while(~us_valid) begin
			@(posedge clk);
		end
		readReq[0] <= 1'b1;
		translated_addr = 9*us_addr[ADDR_W-1:BLK_W];
		addr_cache_to_sdram[0] <= translated_addr;

		while(~doneRead[0]) begin
			@(posedge clk);
		end
		readReq[0] <= 1'b0;

		repeat(100) @(posedge clk);
		$finish;
	end
	*/

	memory_request_arbiter mra(.*);

    qsys_sdram_mem_model_sdram_partner_module_0    dram(.*,.clk(sdram_clk));

endmodule
