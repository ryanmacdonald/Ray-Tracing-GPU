`default_nettype none


`define CLOCK_PERIOD 20

module cache_tb2;

/*	parameter SIDE_W=8,
              ADDR_W=16,
              RDATA_W=288,
              BLK_W=0,
              INDEX_W=11,
              TAG_W=5,
              NUM_LINES=(1<<INDEX_W); */

	// parameters for icache
	parameter	I_SIDE_W=8, // TODO
				I_ADDR_W=16,
				I_RDATA_W=288,
				I_BASE_ADDR=0, // TODO
				I_BLK_W=0,
				I_TAG_W=5,
				I_INDEX_W=11,
				I_NUM_LINES=1392;

	// parameters for tcaches
	parameter	T_SIDE_W=8, // TODO
				T_ADDR_W=16,
				T_RDATA_W=384,
				T_BASE_ADDR=0, // TODO
				T_BLK_W=3,
				T_TAG_W=4,
				T_INDEX_W=9,
				T_NUM_LINES=510;

	// parameters for lcache
	parameter	L_SIDE_W=8, // TODO
				L_ADDR_W=16,
				L_RDATA_W=256,
				L_BASE_ADDR=0, // TODO
				L_BLK_W=4,
				L_TAG_W=2,
				L_INDEX_W=10,
				L_NUM_LINES=1000;


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

	// upstream interface
	logic [I_SIDE_W-1:0]  ic_us_sb_data;
	logic [T_SIDE_W-1:0]  t0c_us_sb_data;
	logic [T_SIDE_W-1:0]  t1c_us_sb_data;
	logic [L_SIDE_W-1:0]  lc_us_sb_data;
	logic               ic_us_valid, t0c_us_valid, t1c_us_valid, lc_us_valid;
	logic [I_ADDR_W-1:0]  ic_us_addr;
	logic [T_ADDR_W-1:0]  t0c_us_addr;
	logic [T_ADDR_W-1:0]  t1c_us_addr;
	logic [L_ADDR_W-1:0]  lc_us_addr;
	logic               ic_us_stall, t0c_us_stall, t1c_us_stall, lc_us_stall;

	// downstream interface
	logic [I_RDATA_W-1:0] ic_ds_rdata;
	logic [T_RDATA_W-1:0] t0c_ds_rdata;
	logic [T_RDATA_W-1:0] t1c_ds_rdata;
	logic [L_RDATA_W-1:0] lc_ds_rdata;
	logic [I_SIDE_W-1:0]  ic_ds_sb_data;
	logic [T_SIDE_W-1:0]  t0c_ds_sb_data;
	logic [T_SIDE_W-1:0]  t1c_ds_sb_data;
	logic [L_SIDE_W-1:0]  lc_ds_sb_data;
	logic               ic_ds_valid, t0c_ds_valid, t1c_ds_valid, lc_ds_valid;
	logic               ic_ds_stall, t0c_ds_stall, t1c_ds_stall, lc_ds_stall;

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
	int num_reads = 210;
	logic [I_RDATA_W+I_SIDE_W-1:0] ic_read_table [210];
	logic [I_RDATA_W+I_SIDE_W-1:0] ic_issue_table [210];

	logic [T_RDATA_W+T_SIDE_W-1:0] t0c_read_table [210];
	logic [T_RDATA_W+T_SIDE_W-1:0] t0c_issue_table [210];

	logic [T_RDATA_W+T_SIDE_W-1:0] t1c_read_table [210];
	logic [T_RDATA_W+T_SIDE_W-1:0] t1c_issue_table [210];

	logic [L_RDATA_W+L_SIDE_W-1:0] lc_read_table [210];
	logic [L_RDATA_W+L_SIDE_W-1:0] lc_issue_table [210];

	integer a, b;
	integer ic_pre_id, ic_post_id;
	integer t0c_pre_id, t0c_post_id;
	integer t1c_pre_id, t1c_post_id;
	integer lc_pre_id, lc_post_id;

	// capture the reads into the read tables
	initial begin
		forever begin
			@(posedge clk);
			if(ic_ds_valid & ~ic_ds_stall) begin
				$display("ic data: %h",{ic_ds_rdata,ic_ds_sb_data});
				ic_post_id = ic_ds_sb_data;
				ic_read_table[ic_post_id] = {ic_ds_rdata,ic_ds_sb_data};
			end
			if(t0c_ds_valid & ~t0c_ds_stall) begin
				$display("t0c data: %h",{t0c_ds_rdata,t0c_ds_sb_data});
				t0c_post_id = t0c_ds_sb_data;
				t0c_read_table[t0c_post_id] = {t0c_ds_rdata,t0c_ds_sb_data};
			end
			if(t1c_ds_valid & ~t1c_ds_stall) begin
				$display("t1c data: %h",{t1c_ds_rdata,t1c_ds_sb_data});
				t1c_post_id = t1c_ds_sb_data;
				t1c_read_table[t1c_post_id] = {t1c_ds_rdata,t1c_ds_sb_data};
			end
			if(lc_ds_valid & ~lc_ds_stall) begin
				$display("lc data: %h",{lc_ds_rdata,lc_ds_sb_data});
				lc_post_id = lc_ds_sb_data;
				lc_read_table[lc_post_id] = {lc_ds_rdata,lc_ds_sb_data};
			end
		end
	end

	integer i;
	integer all_equal;

	initial begin
		ic_us_valid <= 1'b0;
		ic_us_addr <= 'b0;
		ic_us_sb_data <= 'b0;
		ic_ds_stall <= 1'b0;

		t0c_us_valid <= 1'b0;
		t0c_us_addr <= 'b0;
		t0c_us_sb_data <= 'b0;
		t0c_ds_stall <= 1'b0;

		t1c_us_valid <= 1'b0;
		t1c_us_addr <= 'b0;
		t1c_us_sb_data <= 'b0;
		t1c_ds_stall <= 1'b0;

		lc_us_valid <= 1'b0;
		lc_us_addr <= 'b0;
		lc_us_sb_data <= 'b0;
		lc_ds_stall <= 1'b0;

		ic_pre_id=0;
		t0c_pre_id=0;
		t1c_pre_id=0;
		lc_pre_id=0;
		all_equal = 1;

		@(posedge clk);

		while(~sl_done)
			@(posedge clk);

		$display("about to do reads...");

		repeat(100)
			@(posedge clk);

		fork // BEGIN OF FORK
			begin
				a = 1;
				@(posedge clk);
				repeat(10) begin
					do_ic_read(a, ic_pre_id);
					ic_pre_id++;
				end
				ic_us_valid <= 1'b0;
	
				@(posedge clk);
				repeat(200) begin
					do_ic_read({$random} % (100), ic_pre_id[I_SIDE_W-1:0]);
					ic_pre_id++;
				end
				ic_us_valid <= 1'b0;
			end

			begin
				b = 2;
				@(posedge clk);
				repeat(10) begin
					do_t0c_read(b, t0c_pre_id);
					t0c_pre_id++;
				end
				t0c_us_valid <= 1'b0;
	
				@(posedge clk);
				repeat(200) begin
					do_t0c_read({$random} % (100), t0c_pre_id[T_SIDE_W-1:0]);
					t0c_pre_id++;
				end
				t0c_us_valid <= 1'b0;
			end

			begin
				@(posedge clk);
				repeat(210) begin
					do_t1c_read({$random} % (100), t1c_pre_id[T_SIDE_W-1:0]);
					t1c_pre_id++;
				end
				t1c_us_valid <= 1'b0;
			end

			begin
				@(posedge clk);
				repeat(210) begin
					do_lc_read({$random} % (100), lc_pre_id[T_SIDE_W-1:0]);
					lc_pre_id++;
				end
				lc_us_valid <= 1'b0;
			end
		join // END OF FORK

		repeat(500) @(posedge clk); // allow the reads to retire

		$display("num_reads: %d",num_reads);

		$display("ic issue table:");
		for(i=0; i<num_reads; i++) begin
			if(!(ic_issue_table[i] === ic_read_table[i])) begin
				all_equal = 0;
				$display("%h: %h * read: %h",i,ic_issue_table[i], ic_read_table[i]);
			end
			else
				$display("%h: %h",i,ic_issue_table[i]);
		end

		$display("t0c issue table:");
		for(i=0; i<num_reads; i++) begin
			if(!(t0c_issue_table[i] === t0c_read_table[i])) begin
				all_equal = 0;
				$display("%h: %h * read: %h",i,t0c_issue_table[i], t0c_read_table[i]);
			end
			else
				$display("%h: %h",i,t0c_issue_table[i]);
		end

		$display("t1c issue table:");
		for(i=0; i<num_reads; i++) begin
			if(!(t1c_issue_table[i] === t1c_read_table[i])) begin
				all_equal = 0;
				$display("%h: %h * read: %h",i,t1c_issue_table[i], t1c_read_table[i]);
			end
			else
				$display("%h: %h",i,t1c_issue_table[i]);
		end

		$display("lc issue table:");
		for(i=0; i<num_reads; i++) begin
			if(!(lc_issue_table[i] === lc_read_table[i])) begin
				all_equal = 0;
				$display("%h: %h * read: %h",i,lc_issue_table[i], lc_read_table[i]);
			end
			else
				$display("%h: %h",i,lc_issue_table[i]);
		end

		if(!all_equal)
			$display("NOT ALL READS RETURNED CORRECT DATA");
		else
			$display("ALL READS RETURNED CORRECT DATA :)");

		$finish;
	end

	// introduce random stalls from downstream
	// TODO: these don't work. they show up one cycle late.
	initial begin
		forever begin
			@(posedge clk);
			ic_ds_stall = (ic_ds_valid) ? {$random} % 2 : 0;
			t0c_ds_stall = (t0c_ds_valid) ? {$random} % 2 : 0;
			t1c_ds_stall = (t0c_ds_valid) ? {$random} % 2 : 0;
			lc_ds_stall = (lc_ds_valid) ? {$random} % 2 : 0;
		end
	end

	//////////////// tasks ////////////////

	logic [I_RDATA_W/32][31:0] ic_data;
	int ic_translated_addr;
	task do_ic_read(input [I_ADDR_W-1:0] addr, input logic [I_SIDE_W-1:0] side);
		ic_us_valid <= 1'b1;
		ic_us_addr <= addr;
		ic_us_sb_data <= side;
		ic_translated_addr = (I_RDATA_W/32)*addr[I_ADDR_W-1:I_BLK_W] + I_BASE_ADDR;
		for(i=0; i<(I_RDATA_W/32); i++)
			ic_data[i] = dram.mem_array[ic_translated_addr+i];
		ic_issue_table[side] = {ic_data, side};
		$display("ic addr: %h (t+i: %h). DRAM: %h side: %h",addr,addr[I_ADDR_W-1:I_BLK_W],ic_data,side);
		@(posedge clk);
		while(ic_us_stall)
			@(posedge clk);
	endtask

	logic [T_RDATA_W/32][31:0] t0c_data;
	int t0c_translated_addr;
	task do_t0c_read(input [T_ADDR_W-1:0] addr, input logic [T_SIDE_W-1:0] side);
		t0c_us_valid <= 1'b1;
		t0c_us_addr <= addr;
		t0c_us_sb_data <= side;
		t0c_translated_addr = (T_RDATA_W/32)*addr[T_ADDR_W-1:T_BLK_W] + T_BASE_ADDR;
		for(i=0; i<(T_RDATA_W/32); i++)
			t0c_data[i] = dram.mem_array[t0c_translated_addr+i];
		t0c_issue_table[side] = {t0c_data, side};
		$display("t0c addr: %h (t+i: %h). DRAM: %h side: %h",addr,addr[T_ADDR_W-1:T_BLK_W],t0c_data,side);
		@(posedge clk);
		while(t0c_us_stall)
			@(posedge clk);
	endtask

	logic [T_RDATA_W/32][31:0] t1c_data;
	int t1c_translated_addr;
	task do_t1c_read(input [T_ADDR_W-1:0] addr, input logic [T_SIDE_W-1:0] side);
		t1c_us_valid <= 1'b1;
		t1c_us_addr <= addr;
		t1c_us_sb_data <= side;
		t1c_translated_addr = (T_RDATA_W/32)*addr[T_ADDR_W-1:T_BLK_W] + T_BASE_ADDR;
		for(i=0; i<(T_RDATA_W/32); i++)
			t1c_data[i] = dram.mem_array[t1c_translated_addr+i];
		t1c_issue_table[side] = {t1c_data, side};
		$display("t1c addr: %h (t+i: %h). DRAM: %h side: %h",addr,addr[T_ADDR_W-1:T_BLK_W],t1c_data,side);
		@(posedge clk);
		while(t1c_us_stall)
			@(posedge clk);
	endtask

	logic [L_RDATA_W/32][31:0] lc_data;
	int lc_translated_addr;
	task do_lc_read(input [L_ADDR_W-1:0] addr, input logic [L_SIDE_W-1:0] side);
		lc_us_valid <= 1'b1;
		lc_us_addr <= addr;
		lc_us_sb_data <= side;
		lc_translated_addr = (L_RDATA_W/32)*addr[L_ADDR_W-1:L_BLK_W] + L_BASE_ADDR;
		for(i=0; i<(L_RDATA_W/32); i++)
			lc_data[i] = dram.mem_array[lc_translated_addr+i];
		lc_issue_table[side] = {lc_data, side};
		$display("lc addr: %h (t+i: %h). DRAM: %h side: %h",addr,addr[L_ADDR_W-1:L_BLK_W],lc_data,side);
		@(posedge clk);
		while(lc_us_stall)
			@(posedge clk);
	endtask

	// to prevent running forever if something goes wrong
	initial begin
		repeat(200000) @(posedge clk);
		$finish;
	end

	//////////////////////// Intersection Cache ////////////////////////

	cache_and_miss_handler #(
         .ADDR_W(I_ADDR_W),
         .RDATA_W(I_RDATA_W),
         .TAG_W(I_TAG_W),
         .INDEX_W(I_INDEX_W),
         .NUM_LINES(I_NUM_LINES),
         .BLK_W(I_BLK_W),
         .BASE_ADDR(I_BASE_ADDR))
		icache (
			.us_sb_data(ic_us_sb_data),
			.us_valid(ic_us_valid),
			.us_addr(ic_us_addr),
			.us_stall(ic_us_stall),
			.ds_rdata(ic_ds_rdata),
			.ds_sb_data(ic_ds_sb_data),
			.ds_valid(ic_ds_valid),
			.ds_stall(ic_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[0]),
			.transSize(transSize[0]),
			.readReq(readReq[0]),
			.readValid_out(readValid_out[0]),
			.readData(readData[0]),
			.doneRead(doneRead[0]),
			.clk, .rst);

	//////////////////////// Traversal Cache 0 ////////////////////////
	cache_and_miss_handler #(
         .ADDR_W(T_ADDR_W),
         .RDATA_W(T_RDATA_W),
         .TAG_W(T_TAG_W),
         .INDEX_W(T_INDEX_W),
         .NUM_LINES(T_NUM_LINES),
         .BLK_W(T_BLK_W),
         .BASE_ADDR(T_BASE_ADDR))
		t0cache (
			.us_sb_data(t0c_us_sb_data),
			.us_valid(t0c_us_valid),
			.us_addr(t0c_us_addr),
			.us_stall(t0c_us_stall),
			.ds_rdata(t0c_ds_rdata),
			.ds_sb_data(t0c_ds_sb_data),
			.ds_valid(t0c_ds_valid),
			.ds_stall(t0c_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[1]),
			.transSize(transSize[1]),
			.readReq(readReq[1]),
			.readValid_out(readValid_out[1]),
			.readData(readData[1]),
			.doneRead(doneRead[1]),
			.clk, .rst);

	//////////////////////// Traversal Cache 1 ////////////////////////
	cache_and_miss_handler #(
         .ADDR_W(T_ADDR_W),
         .RDATA_W(T_RDATA_W),
         .TAG_W(T_TAG_W),
         .INDEX_W(T_INDEX_W),
         .NUM_LINES(T_NUM_LINES),
         .BLK_W(T_BLK_W),
         .BASE_ADDR(T_BASE_ADDR))
		t1cache (
			.us_sb_data(t1c_us_sb_data),
			.us_valid(t1c_us_valid),
			.us_addr(t1c_us_addr),
			.us_stall(t1c_us_stall),
			.ds_rdata(t1c_ds_rdata),
			.ds_sb_data(t1c_ds_sb_data),
			.ds_valid(t1c_ds_valid),
			.ds_stall(t1c_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[2]),
			.transSize(transSize[2]),
			.readReq(readReq[2]),
			.readValid_out(readValid_out[2]),
			.readData(readData[2]),
			.doneRead(doneRead[2]),
			.clk, .rst);

	//////////////////////// List Cache ////////////////////////

	cache_and_miss_handler #(
         .ADDR_W(L_ADDR_W),
         .RDATA_W(L_RDATA_W),
         .TAG_W(L_TAG_W),
         .INDEX_W(L_INDEX_W),
         .NUM_LINES(L_NUM_LINES),
         .BLK_W(L_BLK_W),
         .BASE_ADDR(L_BASE_ADDR))
		lcache (
			.us_sb_data(lc_us_sb_data),
			.us_valid(lc_us_valid),
			.us_addr(lc_us_addr),
			.us_stall(lc_us_stall),
			.ds_rdata(lc_ds_rdata),
			.ds_sb_data(lc_ds_sb_data),
			.ds_valid(lc_ds_valid),
			.ds_stall(lc_ds_stall),
			.addr_cache_to_sdram(addr_cache_to_sdram[3]),
			.transSize(transSize[3]),
			.readReq(readReq[3]),
			.readValid_out(readValid_out[3]),
			.readData(readData[3]),
			.doneRead(doneRead[3]),
			.clk, .rst);

	memory_request_arbiter mra(.*);

    qsys_sdram_mem_model_sdram_partner_module_0    dram(.*,.clk(clk));

endmodule
