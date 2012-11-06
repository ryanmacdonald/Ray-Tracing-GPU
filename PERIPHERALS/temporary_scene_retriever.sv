


module temporary_scene_retriever(input logic clk, rst,
				 // Interface with scene loader and pixel buffer
				 input logic sl_done,
				 
				 // Interface with MRA
				 output logic readReq,
				 output logic[$clog2(`maxTrans)-1:0] readSize,
				 output logic[24:0] readAddr,
				 input logic[31:0] readData,
				 input logic readDone,
				 input logic readValid,

				 // Interface with pixel buffer
				 output pixel_buffer_entry_t pbData,
				 output logic pb_we,
				 input logic pb_full
				);

	enum logic {IDLE,ACTIVE} state, nextState;

	logic done, inc;

	logic[$clog2(`num_rays)-1:0] cnt, nextCnt;

	assign nextCnt = done ? 0 : cnt + 1;
	ff_ar_en #(19,0) counter(.q(cnt),.d(nextCnt),.en(inc),.clk,.rst);

	always_comb begin
		done = 0; readAddr = 'h0; readReq = 0; readSize = 1;
		pbData = 'h0; pb_we = 0; inc = 0; 
		case(state)
			IDLE:begin
				if(sl_done) begin
					nextState = ACTIVE;
				end
				else nextState = IDLE;
			end
			ACTIVE:begin
				if(cnt == `num_rays) begin
					//$display("4");
					done = 1;
					nextState = IDLE;
				end
				else if(~pb_full) begin
					//$display("1");
					if(~readValid) begin
						//$display("2");
						readReq = 1;
						readAddr = cnt;
						nextState = ACTIVE;
					end
					else begin
						//$display("3");
						inc = 1;
						pbData.color.red = readData[7:0];
						pbData.color.green = readData[15:8];
						pbData.color.blue = readData[23:16];
						pbData.pixelID = cnt;
						pb_we = 1;
						nextState = ACTIVE;
					end
				end
				else nextState = ACTIVE;
			end
			default: nextState = IDLE;
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) state <= IDLE;
		else state <= nextState;
	end

endmodule: temporary_scene_retriever



