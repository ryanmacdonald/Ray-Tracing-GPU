



module prg(input logic clk, rst,
	       input logic v0, v1, v2,
	       input logic start,
	       input vector_t E, U, V, W,
	       input float_t pw,
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
	logic rb_we,rb_re,rb_full,rb_empty;

	logic[$clog2(`VGA_NUM_COLS)-1:0] x, nextX;
	logic[$clog2(`VGA_NUM_ROWS)-1:0] y, nextY;

	pixelID_t pixelID, pixelID_n;

	enum logic {IDLE, ACTIVE} state, nextState;

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
	pipe_valid_stall #(.WIDTH($bits(pixelID_t)),.DEPTH(40))
			 valid_pipe(.clk,.rst,.us_valid(x_y_valid),.us_data(pixelID),.us_stall,
			  .ds_valid,
  			  .ds_data(prg_to_shader_in.pixelID),
			  .ds_stall(prg_to_shader_stall),
			  .num_left_in_fifo({2'b0,num_left_in_rb}));

	ff_ar_en #($clog2(`VGA_NUM_COLS),0)   xr(.q(x),.d(nextX),.en(x_y_valid),.clk,.rst);
	ff_ar_en #($clog2(`VGA_NUM_ROWS),`VGA_NUM_ROWS-1)  yr(.q(y),.d(nextY),.en(x_y_valid),.clk,.rst);

	ff_ar_en #($bits(pixelID_t),0) rr(.q(pixelID),.d(pixelID_n),.en(x_y_valid),.clk,.rst);

	ff_ar_en #($bits(pixelID_t),0) rr(.q(pixelID),.d(pixelID_n),.en(x_y_valid),.clk,.rst);

	prg_pl poop(.prg_data(prg_out),.*);


	assign pixelID_n = (pixelID == `num_rays-1) ? 'h0 : pixelID + 1;

	assign nextX = (x == `VGA_NUM_COLS-1) ? 0 : x + 1;
	assign nextY = (x == `VGA_NUM_COLS-1) ? y - 1 : y;


	assign rb_we = ds_valid;
	assign rb_re = ~rb_empty && ~prg_to_shader_stall && v0;

	assign prg_to_shader_valid = ~rb_empty;

	assign x_y_valid = ~us_stall && (state==ACTIVE) && v0;


	always_comb begin
		case(state)
			IDLE:begin
				if(start) nextState = ACTIVE;
				else nextState = IDLE;
			end
			ACTIVE:begin
				if(pixelID == `num_rays-1) nextState = IDLE;
				else nextState = ACTIVE;
			end
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) state <= IDLE;
		else state <= nextState;
	end


endmodule: prg
