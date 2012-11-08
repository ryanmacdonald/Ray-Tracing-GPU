



module prg_top(input logic clk, rst,
	       input logic v0, v1, v2,
	       input logic start,
	       input vector_t E, U, V, W,
	       input float_t pw,
	       input logic int_to_prg_stall,
	       output logic ready, done,
	       output prg_ray_t prg_data);
	
	`ifndef SYNTH
	shortreal px_q,py_q,pz_q;
	assign px_q = $bitstoshortreal(prg_data.dir.x);
	assign py_q = $bitstoshortreal(prg_data.dir.y);
	assign pz_q = $bitstoshortreal(prg_data.dir.z);
	`endif


	logic count_en;
	logic rayReady;
	logic x_y_valid;
	logic idle;
	logic rb_we,rb_re,rb_full,rb_empty;
	logic[9:0] x, nextX;
	logic[8:0] y, nextY;
	
	prg_ray_t prg_out;

	
	//fifo #(.WIDTH($bits(ray_t)),.K(4)) q(.clk,.rst,.data_in(prg_out),.we(rb_we),.re(rb_re),
	//				     .full(rb_full),.empty(rb_empty),.data_out(prg_data));

	
	altbramfifo_w211_d16 rb(.clock(clk),.data(prg_out),.rdreq(rb_re),.wrreq(rb_we),
				.empty(rb_empty),.full(rb_full),.q(prg_data));
					    

	ff_ar_en #(10,0)   xr(.q(x),.d(nextX),.en(count_en),.clk,.rst);
	ff_ar_en #(9,479)  yr(.q(y),.d(nextY),.en(count_en),.clk,.rst);

	prg poop(.prg_data(prg_out),.*);

	assign nextX = (x == 'd639) ? 0 : x + 1;
	assign nextY = (x == 'd639) ? y - 1 : y;

	assign count_en = ~int_to_prg_stall && v2;

	assign rb_we = rayReady;
	assign rb_re = ~rb_empty && ~int_to_prg_stall && v0;

	assign ready = rb_re;

	assign x_y_valid = ~int_to_prg_stall;


endmodule: prg_top
