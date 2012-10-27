
`default_nettype none

`define screen_width  640
`define screen_height 480 
`define num_rays 307200

// defines for -w/2 and -h/2 //half width = -4, half height = -3
`ifndef SYNTH
	`define half_screen_width  $shortrealtobits(-320.0)
	`define half_screen_height $shortrealtobits(-240.0)
	// D = 6 for now
	`define D $shortrealtobits(100)
`else
	`define half_screen_width  32'hC080_0000 // -4
	`define half_screen_height 32'hC040_0000 // -3
	// D = 6 for now
	`define D 32'h4080_0000 // 4
`endif

// -frame_done asserted from FBH
// -output rayReady asserted every three cycles when
//  a new primary ray is available 
module prg(input logic clk, rst,
	   input logic v0, v1, v2,
	   input logic start,
	   input logic[$clog2(`screen_width)-1:0] x,
	   input logic[$clog2(`screen_height)-1:0] y,
	   input vector_t E, U, V, W,
	   input float_t pw,
	   input logic int_to_prg_stall,
	   output logic rayReady, done,
	   output ray_t prg_data);

`ifndef SYNTH
	shortreal px,py,pz;
	assign px = $bitstoshortreal(prg_data.dir.x);
	assign py = $bitstoshortreal(prg_data.dir.y);
	assign pz = $bitstoshortreal(prg_data.dir.z);
`endif
	logic start_prg;

	sync_to_v #(2) sv(.synced_signal(start_prg),.clk,.rst,.v0,.v1,.v2,.signal_to_sync(start));	

	// counter to determine when to begin outputting rayReady
	logic[5:0] cnt,nextCnt;

	// u, v vector scalar multipliers
	float_t u_dist, v_dist, next_u_dist, next_v_dist;
	// the primary ray's direction
	vector_t prayD,wD;

	// RayID
	logic[$clog2(`num_rays)-1:0] rayID,nextrayID;

	assign prg_data.rayID  = rayID;
	assign prg_data.origin = E;
	assign prg_data.dir    = prayD;

	////// FP INSTATIATIONS AND INTERCONNECT //////	 

	logic[31:0] conv_dataa, conv_result;
	assign conv_dataa = v0 ? {22'b0,x} : {21'b0,y};
	altfp_convert conv(.aclr(rst),.clock(clk),
			   .dataa(conv_dataa),.result(conv_result));

	logic[31:0] mult_1_dataa, mult_1_datab;
	logic mult_1_nan,mult_1_zero;
	logic mult_1_overflow, mult_1_underflow;
	logic[31:0] mult_1_result;
	assign mult_1_dataa = conv_result;
	assign mult_1_datab = pw; 
	altfp_mult mult_1(.aclr(rst),.clock(clk),
			  .dataa(mult_1_dataa),.datab(mult_1_datab),
			  .nan(mult_1_nan),.overflow(mult_1_overflow),
			  .result(mult_1_result),.underflow(mult_1_underflow),
			  .zero(mult_1_zero));

	logic[31:0] add_1_dataa,add_1_datab;
	logic add_1_nan, add_1_overflow;
	logic add_1_underflow, add_1_zero;
	logic[31:0] add_1_result;
	assign add_1_dataa = mult_1_result;
	assign add_1_datab = v2 ? `half_screen_width : `half_screen_height;
	altfp_add add_1(.aclr(rst),.clock(clk),
			.dataa(add_1_dataa),.datab(add_1_datab),
			.nan(add_1_nan),.overflow(add_1_overflow),
			.result(add_1_result),.underflow(add_1_underflow),
			.zero(add_1_zero));
	

	logic[31:0] mult_2_dataa, mult_2_datab;
	logic mult_2_nan,mult_2_zero;
	logic mult_2_overflow, mult_2_underflow;
	logic[31:0] mult_2_result;
	assign mult_2_dataa = u_dist;
	assign mult_2_datab = v1 ? U.x : (v2 ? U.y : U.z); 
	altfp_mult mult_2(.aclr(rst),.clock(clk),
			  .dataa(mult_2_dataa),.datab(mult_2_datab),
			  .nan(mult_2_nan),.overflow(mult_2_overflow),
			  .result(mult_2_result),.underflow(mult_2_underflow),
			  .zero(mult_2_zero));

	
	logic[31:0] mult_3_dataa, mult_3_datab;
	logic mult_3_nan,mult_3_zero;
	logic mult_3_overflow, mult_3_underflow;
	logic[31:0] mult_3_result;
	assign mult_3_dataa = v1 ? add_1_result : v_dist;
	assign mult_3_datab = v1 ? V.x : (v2 ? V.y : V.z);
	altfp_mult mult_3(.aclr(rst),.clock(clk),
			  .dataa(mult_3_dataa),.datab(mult_3_datab),
			  .nan(mult_3_nan),.overflow(mult_3_overflow),
			  .result(mult_3_result),.underflow(mult_3_underflow),
			  .zero(mult_3_zero));

	
	logic[31:0] mult_4_dataa, mult_4_datab;
	logic mult_4_nan,mult_4_zero;
	logic mult_4_overflow, mult_4_underflow;
	logic[31:0] mult_4_result;
	assign mult_4_dataa = v0 ? W.x : (v1 ? W.y : W.z);
	assign mult_4_datab = `D;
	altfp_mult mult_4(.aclr(rst),.clock(clk),
			  .dataa(mult_4_dataa),.datab(mult_4_datab),
			  .nan(mult_4_nan),.overflow(mult_4_overflow),
			  .result(mult_4_result),.underflow(mult_4_underflow),
			  .zero(mult_4_zero));	

 	
	logic[31:0] add_2_dataa,add_2_datab;
	logic add_2_nan, add_2_overflow;
	logic add_2_underflow,add_2_zero;
	logic[31:0] add_2_result;
	assign add_2_dataa = mult_2_result;
	assign add_2_datab = mult_3_result;
	altfp_add add_2(.aclr(rst),.clock(clk),
			.dataa(add_2_dataa),.datab(add_2_datab),
			.nan(add_2_nan),.overflow(add_2_overflow),
			.result(add_2_result),.underflow(add_2_underflow),
			.zero(add_2_zero));

 	
	logic[31:0] add_3_dataa,add_3_datab;
	logic add_3_nan, add_3_overflow;
	logic add_3_underflow, add_3_zero;
	logic[31:0] add_3_result;
	assign add_3_dataa = add_2_result;
	assign add_3_datab = v1 ? wD.x : (v2 ? wD.y : wD.z);
	altfp_add add_3(.aclr(rst),.clock(clk),
			.dataa(add_3_dataa),.datab(add_3_datab),
			.nan(add_3_nan),.overflow(add_3_overflow),
			.result(add_3_result),.underflow(add_3_underflow),
			.zero(add_3_zero));



	////// NEXTSTATE AND OUTPUT LOGIC //////

	enum logic {IDLE,ACTIVE} state, nextState;



	always_comb begin
		nextrayID = rayID;
		nextCnt = cnt; rayReady = 0;
		next_u_dist = u_dist; next_v_dist = v_dist;
		done = 0;
		case(state)
			// In IDLE state, just wait for start
			IDLE:begin
				if(~start_prg) nextState = IDLE;
				else nextState = ACTIVE;
			end
			// In ACTIVE state, increment x, y, and rayID
			// every 3 cycles until rayID = 307200
			ACTIVE:begin
				nextCnt = cnt + 1'b1;
				if(rayID == `num_rays) begin
					done = 1;
					nextState = IDLE;
				end
				else if(v0) begin
					next_u_dist = add_1_result;
					nextState = ACTIVE;
				end
				else if(v1) begin
					if(cnt >= 6'd39 || rayID > 0) begin
						nextCnt = 0;
						rayReady = 1;
						nextrayID = rayID + 1'b1;
					end
					next_v_dist = add_1_result;
					nextState = ACTIVE;
				end
				else if(v2) begin
					nextState = ACTIVE;
				end
				else nextState = ACTIVE;
			end
			default: nextState = IDLE;
		endcase
	end

	ff_ar #(19,0) rd(.q(rayID),.d(nextrayID),.clk,.rst);
	ff_ar #(32,0) ud(.q(u_dist),.d(next_u_dist),.clk,.rst);
	ff_ar #(32,0) vd(.q(v_dist),.d(next_v_dist),.clk,.rst);
	ff_ar #( 6,0) ct(.q(cnt),.d(nextCnt),.clk,.rst);




	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			state <= IDLE;
		end
		else begin	

			if(v0) begin
				prayD.y <= add_3_result;
				wD.y    <= mult_4_result;
			end
			else if(v1) begin
				prayD.z <= add_3_result;
				wD.z    <= mult_4_result;
			end
			else if(v2) begin
				prayD.x <= add_3_result;
				wD.x    <= mult_4_result;
			end

			state <= nextState;
			end
	end

endmodule: prg


