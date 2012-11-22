



module prg(input logic clk, rst,
	       input logic v0, v1, v2,
	       input logic start,
	       input vector_t E, U, V, W,
	       input float_t pw,
	       input logic prg_to_shader_stall,
	       output logic prg_to_shader_valid,
	       output prg_ray_t prg_to_shader_data
         );
	
  logic done; //unused for now

	`ifndef SYNTH
	shortreal px_q,py_q,pz_q;
	assign px_q = $bitstoshortreal(prg_to_shader_data.dir.x);
	assign py_q = $bitstoshortreal(prg_to_shader_data.dir.y);
	assign pz_q = $bitstoshortreal(prg_to_shader_data.dir.z);
	`endif

	logic rayReady;
	logic x_y_valid;
	logic idle;
	logic rb_we,rb_re,rb_full,rb_empty;
	logic[9:0] x, nextX;
	logic[8:0] y, nextY;
	
	prg_ray_t prg_out;
	logic[3:0] num_in_rb, num_left_in_rb;
	altbramfifo_w211_d16 rb(.clock(clk),.data(prg_out),.rdreq(rb_re),.wrreq(rb_we),
				.empty(rb_empty),.full(rb_full),.q(prg_to_shader_data),
				.usedw(num_in_rb));

	assign num_left_in_rb = 5'd16 - {rb_full,num_in_rb};

	// TODO: depth param correct?
	logic ds_valid, us_stall;
	pipe_valid_stall #(.WIDTH(1),.DEPTH(40))
			 valid_pipe(.clk, .rst,.us_valid(x_y_valid),.us_data(1'b0),.us_stall,
			  .ds_valid,
  			  .ds_data(),
			  .ds_stall(prg_to_shader_stall),
			  .num_left_in_fifo({2'b0,num_left_in_rb}));
	    
	ff_ar_en #(10,0)   xr(.q(x),.d(nextX),.en(x_y_valid),.clk,.rst);
	ff_ar_en #(9,479)  yr(.q(y),.d(nextY),.en(x_y_valid),.clk,.rst);

	prg_pl poop(.prg_data(prg_out),.*);

	assign nextX = (x == 'd639) ? 0 : x + 1;
	assign nextY = (x == 'd639) ? y - 1 : y;

	assign rb_we = ds_valid;
	assign rb_re = ~rb_empty && ~prg_to_shader_stall && v0;

	assign prg_to_shader_valid = ~rb_empty;

	assign x_y_valid = ~us_stall && v0;


endmodule: prg
