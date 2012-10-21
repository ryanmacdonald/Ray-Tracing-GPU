
`default_nettype none

`define screen_width  640
`define screen_height 480 
`define num_rays 307200

`define half_screen_width  $bitstoshortreal(32'd320)
`define half_screen_height $bitstoshortreal(32'd240)

// -frame_done asserted from FBH
// -ready asserted from intersection unit
// -output idle asserted when prg is idle
// -output rayReady asserted every three cycles when
//  a new primary ray is available 
module prg(input logic clk, rst,
	   input logic frame_done, ready,
	   input vector_t E, U, V, W,
	   input float_t D, pw,
	   output logic idle, rayReady,
	   output prg_data_t);

	// start signal asserted when frame_done, idle, and ready asserted
	logic start;
	assign start = frame_done&ready&idle;

	// counter to determine when to begin outputting rayReady
	logic[5:0] cnt,nextCnt;

	// u, v vector scalar multipliers
	float_t u_dist, v_dist, next_u_dist, next_v_dist;
	// the primary ray's direction
	vector_t prayD;
	
	// coordinates of pixel
	logic[$clog2(`screen_width)-1:0]  x,nextX;
	logic[$clog2(`screen_height)-1:0] y,nextY;

	// RayID
	logic[$clog2(`num_rays)-1:0] rayID,nextrayID;

	assign prg_data_t.rayID  = rayID;
	assign prg_data_t.origin = E;
	assign prg_data_t.dir    = prayD;

	////// FP INSTATIATIONS AND INTERCONNECT //////	 

	logic conv_aclr;
	logic[31:0] conv_dataa, conv_result;
	assign conv_aclr = rst;	
	assign conv_dataa = v0 ? x : y;
	altfp_convert conv(.aclr(conv_aclr),.clock(clk),
			   .dataa(conv_dataa),.result(conv_result));

	logic mult_1_aclr;
	logic[31:0] mult_1_dataa, mult_1_datab;
	logic mult_1_nan,mult_1_zero;
	logic mult_1_overflow, mult_1_underflow;
	logic[31:0] mult_1_result;
	assign mult_1_dataa = conv_result;
	assign mult_1_datab = pw; 
	altfp_mult mult_1(.aclr(mult_1_aclr),.clock(clk),
			  .dataa(mult_1_dataa),.datab(mult_1_datab),
			  .nan(mult_1_nan),.overflow(mult_1_overflow),
			  .result(mult_1_result),.underflow(mult_1_underflow),
			  .zero(mult_1_zero));

 	logic add_1_aclr;
	logic[31:0] add_1_dataa,add_1_datab;
	logic add_1_nan, add_1_overflow;
	logic add_1_underflow, add_1_zero;
	logic[31:0] add_1_result;
	assign add_1_dataa = mult_1_result;
	assign add_1_datab = v2 ? half_screen_width : half_screen_height;
	altfp_add add_1(.aclr(add_1_aclr),.clock(clk),
			.dataa(add_1_dataa),.datab(add_1_datab),
			.nan(add_1_nan),.overflow(add_1_overflow),
			.result(add_1_result),.underflow(add_1_underflow),
			.zero(add_1_zero));
	
	logic mult_2_aclr;
	logic[31:0] mult_2_dataa, mult_2_datab;
	logic mult_2_nan,mult_2_zero;
	logic mult_2_overflow, mult_2_underflow;
	logic[31:0] mult_2_result;
	assign mult_2_dataa = u_dist;
	assign mult_2_datab = v2 ? U.x : (v0 ? U.y : U.z); 
	altfp_mult mult_2(.aclr(mult_2_aclr),.clock(clk),
			  .dataa(mult_2_dataa),.datab(mult_2_datab),
			  .nan(mult_2_nan),.overflow(mult_2_overflow),
			  .result(mult_2_result),.underflow(mult_2_underflow),
			  .zero(mult_2_zero));

	logic mult_3_aclr;
	logic[31:0] mult_3_dataa, mult_3_datab;
	logic mult_3_nan,mult_3_zero;
	logic mult_3_overflow, mult_3_underflow;
	logic[31:0] mult_3_result;
	assign mult_3_dataa = v_dist;
	assign mult_3_datab = v2 ? V.x : (v0 ? V.y : V.z);
	altfp_mult mult_3(.aclr(mult_3_aclr),.clock(clk),
			  .dataa(mult_3_dataa),.datab(mult_3_datab),
			  .nan(mult_3_nan),.overflow(mult_3_overflow),
			  .result(mult_3_result),.underflow(mult_3_underflow),
			  .zero(mult_1_zero));

	logic mult_4_aclr;
	logic[31:0] mult_4_dataa, mult_4_datab;
	logic mult_4_nan,mult_4_zero;
	logic mult_4_overflow, mult_4_underflow;
	logic[31:0] mult_4_result;
	assign mult_4_dataa = v0 ? W.x : (v1 ? W.y : W.z);
	assign mult_4_datab = D;
	altfp_mult mult_4(.aclr(mult_4_aclr),.clocK(clk),
			  .dataa(mult_4_dataa),.datab(mult4_datab)
			  .nan(mult_4_nan),.overflow(mult_4_overflow),
			  .result(mult_4_result),.underflow(mult_4_underflow),
			  .zero(mult_4_zero));	

 	logic add_2_aclr;
	logic[31:0] add_2_dataa,add_2_datab;
	logic add_2_nan, add_2_overflow;
	logic add_2_underflow,add_2_zero;
	logic[31:0] add_2_result;
	assign add_2_dataa = mult_2_result;
	assign add_2_datab = mult_3_result;
	altfp_add add_2(.aclr(add_2_aclr),.clock(clk),
			.dataa(add_2_dataa),.datab(add_2_datab),
			.nan(add_2_nan),.overflow(add_2_overflow),
			.result(add_2_result),.underflow(add_2_underflow),
			.zero(add_2_zero));

 	logic add_3_aclr;
	logic[31:0] add_3_dataa,add_3_datab;
	logic add_3_nan, add_3_overflow;
	logic add_3_underflow, add_3_zero;
	logic[31:0] add_3_result;
	assign add_3_dataa = add_2_result;
	assign add_3_datab = wD;
	altfp_add add_3(.aclr(add_3_aclr),.clock(clk),
			.dataa(add_3_dataa),.datab(add_3_datab),
			.nan(add_3_nan),.overflow(add_3_overflow),
			.result(add_3_result),.underflow(add_3_underflow),
			.zero(prayD));


	always_comb begin
		nextX = x; nextY = y; nextrayID = rayID;
		nextCnt = cnt; rayReady = 0;
		case(state)
			// In IDLE state, just wait for start
			IDLE:begin
				if(~start) nextState = IDLE;
				else nextState = ACTIVE;
			end
			// In ACTIVE state, increment x, y, and rayID
			// every 3 cycles until rayID = 307200
			ACTIVE:begin
				if(rayID == numRays) begin
					nextState = IDLE;
				end
				else if(v0) begin
					if(cnt >= 6'd39) rayReady = 1;
					nextState = ACTIVE;
				end
				else if(v2) begin
					nextrayID = rayID + 1'b1;
					nextState = ACTIVE;
					if(x == 10'd639) begin
						nextX = 1'b0;
						nextY = y - 1'b1;
					end
					else nextX = x + 1'b1;
				end
				else nextState = ACTIVE;
			end
			default: nextState = IDLE;
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			state <= IDLE;
			x <= 0;
			y <= 9'd479;
			rayID <= 0;
			cnt <= 0;
			u_dist <= 0;
			v_dist <= 0;
		end
		else begin
			if(cnt == 6'd18) begin
				u_dist <= add_1_result;
			end
			else if(cnt == 6'd19) begin
				v_dist <= add_1_result;
			end
			state <= nextState;
			x <= nextX;
			y <= nextY;
			rayID <= nextrayID;
			cnt <= nextCnt;
		end
	end

endmodule: prg


