
`define numcaches 4
`define maxTrans 64

// Caches send requests to sdram, which handles these
// requests using a round-robin priority scheme. When
// the transaction is done, the sdram asserts a valid
// signal to the given cache.

module memory_request_arbiter(
	     // Interface from caches to SDRAM controller
	     // Read Interface
	     input  logic[`numcaches-1:0][24:0] addr_cache_to_sdram,
	     input  logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize,
	     input  logic[`numcaches-1:0] readReq,
	     output logic[`numcaches-1:0] readValid_out,
	     output logic[`numcaches-1:0][31:0] readData,
	     output logic[`numcaches-1:0] doneRead,

	     // Write Interface
	     input  logic[24:0] sl_addr,
	     input  logic[31:0] writeData,
	     input logic  writeReq,
	     output logic doneWrite,
	
	     input  logic clk, rst,
		  //temp write_error output
		  output wire write_error,

	     // Interface from SDRAM controller to SDRAM chip
	     output wire  [ 12: 0] zs_addr,
	     output wire  [  1: 0] zs_ba,
	     output wire           zs_cas_n,
	     output wire           zs_cke,
	     output wire           zs_cs_n,
	     inout  wire  [ 31: 0] zs_dq,
	     output wire  [  3: 0] zs_dqm,
	     output wire           zs_ras_n,
	     output wire           zs_we_n,
	     output wire	   sdram_clk);


	enum logic[1:0] {IDLE,READ,WRITE} state, nextState;

	logic inc, busy, read, write;
	logic[$clog2(`numcaches)-1:0] currC, nextC;
	logic[$clog2(`maxTrans)-1:0]  cnt, nextCnt;

	logic[24:0] addr_in;
	logic[31:0] data_in, za_data;
	logic[$clog2(`maxTrans)-1:0] size;
	logic ready, readValid, writeValid;

	// TODO: declare and connect signals
	sdram_a2 sdram_ctrl(.*,.clk_clk(clk),.reset_reset_n(~rst),.altpll_0_c0_clk(sdram_clk));

	// Pointer to current cache
	assign nextC = currC + 1'b1;
	ff_ar_en #($clog2(`numcaches),0) cp(.q(currC),.d(nextC),.en(~busy),.clk,.rst);
	
	// Transaction counter
	assign nextCnt = (doneRead[currC] || doneWrite) ? 6'b0 : cnt + 6'b1;
	ff_ar_en #($clog2(`maxTrans),0) tc(.q(cnt),.d(nextCnt),.en(inc),.clk,.rst);	

	assign size = transSize[currC];

	always_comb begin
		busy = 1; read = 0; write = 0; addr_in = 'h0; data_in = 'h0;
		readData = 'h0; doneWrite = 'h0; readValid_out = 'h0;
		inc = 0; doneRead = 'h0;
		case(state)		
			IDLE:begin
				if(readReq[currC]) begin
//					$display("IDLE case 1\n");
					read = 1;
					addr_in = addr_cache_to_sdram[currC];
					nextState = READ;
				end
				else if(writeReq) begin
//					$display("IDLE case 2\n");
					inc = 1;
					write = 1;
					addr_in = sl_addr;
					data_in = writeData;
					nextState = WRITE;
				end
				else begin
//					$display("IDLE case 3\n");
					busy = 0;
					nextState = IDLE;	
				end
			end
			READ:begin
				addr_in = addr_cache_to_sdram[currC];
				// Send a word to the cache
				// readyReady means a valid word is coming from the controller
				if(cnt == transSize[currC]) begin
//					$display("READ case 2\n");
					inc = 1;
					busy = 0;
					doneRead[currC] = 1;
					nextState = IDLE;	
				end
				else if(readValid) begin
//					$display("READ case 1\n");
					readValid_out[currC] = 1;
					readData[currC] = za_data;
					inc = 1;
					nextState = READ;
				end
				// Go back to the IDLE state
				else begin 	
//					$display("READ case 3\n");
					nextState = READ;
				end
			end
			WRITE:begin
				addr_in = sl_addr;
				data_in = writeData;
				inc = 1;
				// Cannot support write 1 word now
				if(cnt == 1) begin
					busy = 0;
//					$display("WRITE case 1\n");
					doneWrite = 1;
					nextState = IDLE;
				end
				else begin
//					$display("WRITE case 2\n");
					nextState = WRITE;
				end
			end
			default: nextState = IDLE;
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) state <= IDLE;
		else state <= nextState;
	end

endmodule: memory_request_arbiter
