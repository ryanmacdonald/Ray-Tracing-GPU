



module prg(input logic clk, rst,
	       input logic v0, v1, v2,
	       input logic start,
	       input keys_t keys,
	       input vector_t E, U, V, W,
	       input logic prg_to_shader_stall,
	       output logic prg_to_shader_valid, 
	       output prg_ray_t prg_to_shader_data);
	
	`ifndef SYNTH
		shortreal px_q, py_q, pz_q;
		assign px_q = $bitstoshortreal(prg_to_shader_data.dir.x);
		assign py_q = $bitstoshortreal(prg_to_shader_data.dir.y);
		assign pz_q = $bitstoshortreal(prg_to_shader_data.dir.z);
	`endif

	logic rayReady;
	logic x_y_valid;
	logic valid_sr_key_press;
	logic rb_we,rb_re,rb_full,rb_empty;
	float_t pw;

	logic[$clog2(`MAX_COLS)-1:0] x, nextX;
	logic[$clog2(`MAX_ROWS)-1:0] y, nextY;

	pixelID_t pixelID, pixelID_n;

	enum logic {IDLE, ACTIVE} state, nextState;

	assign valid_sr_key_press = |{keys.n1[0],keys.n2[0],keys.n3[0],
				      keys.n4[0],keys.n5[0],keys.n6[0]};

	ray_vec_t prg_out;
	prg_ray_t prg_to_shader_in;
	assign prg_to_shader_in.origin = prg_out.origin;
	assign prg_to_shader_in.dir = prg_out.dir;
	logic[3:0] num_in_rb, num_left_in_rb;
	altbramfifo_w211_d16 rb(.clock(clk),.data(prg_to_shader_in),.rdreq(rb_re),.wrreq(rb_we),
				.empty(rb_empty),.full(rb_full),.q(prg_to_shader_data),
				.usedw(num_in_rb));

	assign num_left_in_rb = 5'd16 - {rb_full,num_in_rb};

	logic ds_valid, us_stall;
	pipe_valid_stall #(.WIDTH($bits(pixelID_t)),.DEPTH(41))
			 valid_pipe(.clk,.rst,.us_valid(x_y_valid),.us_data(pixelID),.us_stall,
			  .ds_valid,
  			  .ds_data(prg_to_shader_in.pixelID),
			  .ds_stall(prg_to_shader_stall),
			  .num_left_in_fifo({2'b0,num_left_in_rb}));

	logic[$clog2(`MAX_COLS)-1:0] x_prg;
	logic[$clog2(`MAX_ROWS)-1:0] y_prg;
	prg_pl poop(.prg_data(prg_out),.x(x_prg),.y(y_prg),.*);


	ff_ar_en #($clog2(`MAX_COLS),0)  		xr(.q(x),.d(nextX),.en(x_y_valid),.clk,.rst);
	ff_ar_en #($clog2(`MAX_ROWS),(`PRG_BOX_ROWS-1)) yr(.q(y),.d(nextY),.en(x_y_valid),.clk,.rst);


	assign nextX = (x == `PRG_BOX_COLS-1) ? 0 : x + 1;
	// nextY assigned in always_comb

	// For now, scale is constant, eventually this will be assigned to
	// three input switches or buttons or keys
	logic[2:0] scale, scale_n;
	logic sr_en;
	assign sr_en = valid_sr_key_press && (state == IDLE);
	ff_ar_en #(3,`RES_SCALE) sr(.q(scale),.d(scale_n),.en(sr_en),.clk,.rst);

	logic done;
	logic done_sub_box;	
	logic[9:0] cr_q, cr_d;

	// Scales which map the x/y_indexes to the correct x/y_offset
	logic[9:0] x_index, y_index;
	logic[9:0] x_os, y_os;
	
	logic[4:0] max_y_index;
	logic[9:0] rows, cols;
	logic[18:0] num_rays;
	
	
	// Logic to assign appropriate scales, indices, num_rays, constants
	always_comb begin
		//num_rays = `RES_0;
		//max_y_index = 5'd0; pw = `PW_0; 
		//rows = `ROWS_RES_0; cols = `COLS_RES_0;
		case(scale)
			3'd0:begin
				num_rays = `RES_0;
				max_y_index = 5'd0; pw = `PW_0;
				rows = `ROWS_RES_0; cols = `COLS_RES_0;
			end
			3'd1:begin
				num_rays = `RES_1;
				max_y_index = 5'd1; pw = `PW_1;
				rows = `ROWS_RES_1; cols = `COLS_RES_1;
			end
			3'd2:begin
				num_rays = `RES_2;
				max_y_index = 5'd3; pw = `PW_2;
				rows = `ROWS_RES_2; cols = `COLS_RES_2;
			end
			3'd3:begin
				num_rays = `RES_3;
				max_y_index = 5'd7; pw = `PW_3;
				rows = `ROWS_RES_3; cols = `COLS_RES_3;
			end
			3'd4:begin
				num_rays = `RES_4;
				max_y_index = 5'd15; pw = `PW_4;
				rows = `ROWS_RES_4; cols = `COLS_RES_4;
			end
			3'd5:begin
				num_rays = `RES_5;
				max_y_index = 5'd31; pw = `PW_5;
				rows = `ROWS_RES_5; cols = `COLS_RES_5;
			end
			default: ;
		endcase
	end


	// scale_n logic
	always_comb begin
		scale_n = 3'b101;
		case({keys.n1[0],keys.n2[0],keys.n3[0],
		      keys.n4[0],keys.n5[0],keys.n6[0]})
			6'b100_000: scale_n = 3'b000;
			6'b010_000: scale_n = 3'b001;
			6'b001_000: scale_n = 3'b010;
			6'b000_100: scale_n = 3'b011;
			6'b000_010: scale_n = 3'b100;
			6'b000_001: scale_n = 3'b101;
			default: ;
		endcase
	end




	// (x_os,y_os) is the coodinate of the lower left corner
	// of the current 15 x 20 box
	assign x_os = `X_MULT * x_index;
	assign y_os = `Y_MULT * (max_y_index - y_index);

	assign x_index = {5'b0,cr_q[8],cr_q[6],cr_q[4],cr_q[2],cr_q[0]};
	assign y_index = {5'b0,cr_q[9],cr_q[7],cr_q[5],cr_q[3],cr_q[1]};

	assign x_prg = x_os + x;
	assign y_prg = y_os + y;

	assign done_sub_box = ( (x == 19) && (y == 0) );
	assign done = (done_sub_box) && (pixelID == num_rays-1);

	assign pixelID = (((rows-1)-y_prg)*cols) + x_prg;

	
	logic cr_en;
	assign cr_d = done ? 'h0 : cr_q + 1;
	assign cr_en = done_sub_box && x_y_valid;
	ff_ar_en #(10,0) cr(.q(cr_q),.d(cr_d),.en(cr_en),.clk,.rst);


	assign rb_we = ds_valid;
	assign rb_re = ~rb_empty && ~prg_to_shader_stall;

	assign prg_to_shader_valid = ~rb_empty;

	assign x_y_valid = ~us_stall && (state==ACTIVE) && v0;


	always_comb begin
		nextY = done_sub_box ? `PRG_BOX_ROWS-1 : ( (x == `PRG_BOX_COLS-1) ? y - 1 : y );
		case(state)
			IDLE:begin
				if(start) nextState = ACTIVE;
				else nextState = IDLE;
			end
			ACTIVE:begin
				nextState = ((pixelID == num_rays-1) & x_y_valid) ? IDLE : ACTIVE;
				if(nextState == IDLE) begin
					nextY = `PRG_BOX_ROWS-1;
				end
			end
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) state <= IDLE;
		else state <= nextState;
	end


endmodule: prg
