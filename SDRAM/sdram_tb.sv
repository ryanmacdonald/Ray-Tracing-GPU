`define numcaches 4
`define maxTrans 64


`timescale 1ns / 1ps

module top();

	logic clk, rst_l, read_l, write_l;

	trans_model tm(.*);

	initial begin
		
		clk <= 1; rst_l <= 1; write_l <= 1;
		read_l <= 1;
		@(posedge clk);
		rst_l <= 0;
		@(posedge clk);
		rst_l <= 1;
		repeat(100000) @(posedge clk);
		write_l <= 0;
		@(posedge clk);
		write_l <= 1;

		repeat(10) @(posedge clk);

		read_l <= 0;

		@(posedge clk);

		read_l <= 1;
	
		repeat(100) @(posedge clk);

		$finish;

	end

	always #10 clk = ~clk;

endmodule: top



module trans_model(input logic clk, rst_l,
	   input logic read_l, write_l);
						
	   wire  [ 12: 0] zs_addr;
	   wire  [  1: 0] zs_ba;
           wire		  zs_cas_n;
	   wire           zs_cke;
	   wire           zs_cs_n;
	   wire  [ 31: 0] zs_dq;
	   wire  [  3: 0] zs_dqm;
	   wire           zs_ras_n;
	   wire           zs_we_n;
	   wire	          sdram_clk;

	

		  logic rst;
		  assign rst = ~rst_l;
		  
		  /*logic[1:0] 0;
		  assign 0 = 2'b0;
		  */
		  enum logic[2:0] {IDLE,READ1,READ2,WRITE1,WRITE2} state, nextState;

	     // Interface from caches to SDRAM controller
	     logic[`numcaches-1:0][24:0] addr_cache_to_sdram;
	     logic[24:0] sl_addr;
	     logic[31:0] writeData;
	     logic[`numcaches-1:0][$clog2(`maxTrans)-1:0] transSize;
	     logic[`numcaches-1:0] readReq;
	     logic  writeReq;
	     logic doneWrite_out;

	     logic[`numcaches-1:0] readValid_out;
	     logic[`numcaches-1:0][31:0] readData;
	     logic[`numcaches-1:0] doneRead;
	     logic doneWrite;
						
		  memory_request_arbiter mra(.*);
		  qsys_sdram_mem_model_sdram_partner_module_0 model(.clk(clk),.*);
	
			always_comb begin
				addr_cache_to_sdram[0] = 25'hA5A5A5;
				sl_addr = 25'hA5A5A5;
				writeData  = 'h0;
				transSize = 'h0;
				writeReq = 'h0;
				readReq = 'h0;
				case(state) 
					IDLE:begin
						if(~read_l) begin
							readReq[2'b0] = 1;
							transSize[2'b0] = 2;
							nextState = READ1;
						end
						else if(~write_l) begin
					
							nextState = WRITE2;
						end
						else nextState = IDLE;
					end
					WRITE1:begin	
						writeReq = 1;
						transSize = 2;
						writeData = 32'hDEADBEEF;
						nextState = WRITE2;
					end
					WRITE2:begin
						writeReq = 1;	
						writeData = 32'hFEEDBABE;
						if(doneWrite == 1) nextState = IDLE;
						else nextState = WRITE2;
					end
					READ1:begin
						readReq[2'b0] = 1;
						transSize[2'b0] = 2;
						if(readValid_out[2'b0]) nextState = READ2;
						else nextState = READ1;
					end
					READ2:begin
						readReq[2'b0] = 1;
						transSize[2'b0] = 2;
						if(readValid_out[2'b0]) nextState = IDLE;
						else nextState = READ2;
					end
					default: nextState = IDLE;
				endcase
			end

			
			always_ff @(posedge clk, posedge rst) begin
				if(rst) state <= IDLE;
				else state <= nextState;
			end

endmodule: trans_model


module ff_ar_en #(parameter W = 8, RV = {W{1'b0}})
					(output logic[W-1:0] q,
					 input  logic[W-1:0] d,
					 input logic en,
					 input logic clk,
					 input logic rst);
					 
		always_ff@(posedge clk, posedge rst) begin
			if(rst) q <= RV;
			else if(en) q <= d;
		end		 
					 
endmodule: ff_ar_en
