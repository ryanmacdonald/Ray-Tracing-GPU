



module prg_top(input logic clk, rst,
	       input logic v0, v1, v2,
	       input logic start,
	       input vector_t E, U, V, W,
	       input float_t pw,
	       input logic prg_to_shader_stall,
	       output logic prg_to_shader_valid, done,
	       output prg_ray_t prg_to_shader_data);
	
	`ifndef SYNTH
	shortreal px_q,py_q,pz_q;
	assign px_q = $bitstoshortreal(prg_to_shader_data.dir.x);
	assign py_q = $bitstoshortreal(prg_to_shader_data.dir.y);
	assign pz_q = $bitstoshortreal(prg_to_shader_data.dir.z);
	`endif


	logic count_en;
	logic rayReady;
	logic x_y_valid;
	logic idle;
	logic rb_we,rb_re,rb_full,rb_empty;
	logic[9:0] x, nextX;
	logic[8:0] y, nextY;
	
	prg_ray_t prg_out;

	
  // TODO replace .K with .DEPTH 
	//fifo #(.WIDTH($bits(ray_t)),.K(4)) q(.clk,.rst,.data_in(prg_out),.we(rb_we),.re(rb_re),
	//				     .full(rb_full),.empty(rb_empty),.data_out(prg_to_shader_data));

	
	altbramfifo_w211_d16 rb(.clock(clk),.data(prg_out),.rdreq(rb_re),.wrreq(rb_we),
				.empty(rb_empty),.full(rb_full),.q(prg_to_shader_data));
					    

	ff_ar_en #(10,0)   xr(.q(x),.d(nextX),.en(count_en),.clk,.rst);
	ff_ar_en #(9,479)  yr(.q(y),.d(nextY),.en(count_en),.clk,.rst);

	prg poop(.prg_data(prg_out),.*);

	assign nextX = (x == 'd639) ? 0 : x + 1;
	assign nextY = (x == 'd639) ? y - 1 : y;

	assign count_en = ~prg_to_shader_stall && v2;

	assign rb_we = rayReady;
	
  // TODO used to be anded with v0
  assign rb_re = ~rb_empty && ~prg_to_shader_stall;

	assign prg_to_shader_valid = rb_re;

	assign x_y_valid = ~prg_to_shader_stall;


endmodule: prg_top
