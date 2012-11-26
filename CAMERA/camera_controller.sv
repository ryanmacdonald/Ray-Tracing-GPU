
  // left right U
  // left = key_d   0
  // right = key_a  1

  // up/down V  
  // up = E         2
  // down = Q       3

  // in/out W       
  // in = W_key     4
  // out = S_key    5

module camera_controller(
  input clk, rst,
  input v0, v1, v2,

  input keys_t keys, // Keys packet from PS/2 
  
  input rendering_done,
  output logic render_frame,
  output vector_t E, U, V, W

  );



	`ifndef SYNTH
		shortreal Ex,Ey,Ez;
		shortreal Ux,Uy,Uz;
		shortreal Vx,Vy,Vz;
		shortreal Wx,Wy,Wz;
		assign Ex = $bitstoshortreal(E.x);
		assign Ey = $bitstoshortreal(E.y);
		assign Ez = $bitstoshortreal(E.z);
		assign Ux = $bitstoshortreal(U.x);
		assign Uy = $bitstoshortreal(U.y);
		assign Uz = $bitstoshortreal(U.z);
		assign Vx = $bitstoshortreal(V.x);
		assign Vy = $bitstoshortreal(V.y);
		assign Vz = $bitstoshortreal(V.z);
		assign Wx = $bitstoshortreal(W.x);
		assign Wy = $bitstoshortreal(W.y);
		assign Wz = $bitstoshortreal(W.z);	
	`endif


	logic cr_valid;
	logic valid_rot;
	vector_t U_n, V_n, W_n;

	logic ld_curr_camera;
	logic valid_key_press, valid_key_release, valid_rot_key_press;

	assign valid_key_press = (|{keys.d[0],keys.a[0],keys.e[0],keys.q[0],keys.w[0],keys.s[0],
				    keys.l[0],keys.j[0],keys.o[0],keys.u[0],keys.i[0],keys.k[0]});
  	assign valid_key_release = (|{keys.d[1],keys.a[1],keys.e[1],keys.q[1],keys.w[1],keys.s[1],
				      keys.l[1],keys.j[1],keys.o[1],keys.u[1],keys.i[1],keys.k[1]});

	assign valid_rot_key_press =  |{keys.l[0],keys.j[0],keys.o[0],keys.u[0],keys.i[0],keys.k[0]};
	//assign valid_rot_key_release =  |{keys.l[1],keys.j[1],keys.o[1],keys.u[1],keys.i[1],keys.k[1]};

	logic rendering, rendering_n;
	assign rendering_n = valid_key_release ? 1'b0 :
			     ((valid_key_press || rendering) ? 1'b1 : 1'b0);
	ff_ar #(1,0) rd(.q(rendering),.d(rendering_n),.clk,.rst);

	logic[3:0] last_key, last_key_n;
	ff_ar #(4,0) kr(.q(last_key),.d(last_key_n),.clk,.rst);

	logic rot_en;

	enum logic [1:0] {IDLE, ROTATING, RENDERING} state, nextState;

	logic[31:0] cnt, cnt_n;
	logic cnt_cl;
	assign cnt_n = cnt_cl||(state == IDLE) ? 0 : (rendering  ? cnt + 10'd1 : 0);
	ff_ar #(32,0) ct(.q(cnt),.d(cnt_n),.clk,.rst);

	always_comb begin
		last_key_n = last_key;
		if(valid_key_press) begin
			case({keys.d[0],keys.a[0],keys.e[0],keys.q[0],keys.w[0],keys.s[0],
			      keys.l[0],keys.j[0],keys.o[0],keys.u[0],keys.i[0],keys.k[0]})
				12'b10_00_00_00_00_00: last_key_n = 4'd0;
				12'b01_00_00_00_00_00: last_key_n = 4'd1;
				12'b00_10_00_00_00_00: last_key_n = 4'd2;
				12'b00_01_00_00_00_00: last_key_n = 4'd3;
				12'b00_00_10_00_00_00: last_key_n = 4'd4;
				12'b00_00_01_00_00_00: last_key_n = 4'd5;
				12'b00_00_00_10_00_00: last_key_n = 4'd6;
				12'b00_00_00_01_00_00: last_key_n = 4'd7;
				12'b00_00_00_00_10_00: last_key_n = 4'd8;
				12'b00_00_00_00_01_00: last_key_n = 4'd9;
				12'b00_00_00_00_00_10: last_key_n = 4'd10;
				12'b00_00_00_00_00_01: last_key_n = 4'd11;
				default: last_key_n = 4'd12;
			endcase
		end
		/*else if(valid_key_release) begin
			last_key_n = 4'd12;
		end*/
	end


	logic vr_q, vr_d;
	assign vr_d = vr_q ? 1'b0 : 1'b1;
	ff_ar_en #(1,0) vr(.q(vr_q),.d(vr_d),.en(rot_en),.clk,.rst);
	
	
	// Determines if a rotation is valid
	assign valid_rot = ~vr_q ||
			   (last_key == last_key_n || last_key == last_key_n+1);

	// TODO: Assumes that a key press will never be shorter than a render
	//	 Might need to change this for more complicated scenes
	always_comb begin
		rot_en = 0; cnt_cl = 0; ld_curr_camera = 0; render_frame = 0; 
		case(state)
			IDLE:begin
				if(valid_rot_key_press && ~rendering && valid_rot) begin
					render_frame = 1;
					nextState = ROTATING;
				end
				else if(valid_key_press && ~rendering) begin
					ld_curr_camera = 1;
					render_frame = 1;	
					nextState = RENDERING;
				end
				else nextState = IDLE;
			end
			ROTATING:begin
				rot_en = 1;
				nextState = IDLE;	
			end
			RENDERING:begin
				if(valid_key_release) begin
					cnt_cl = 1;
					ld_curr_camera = 1;
					nextState = IDLE;
				end
				else if(rendering_done) begin
					cnt_cl = 1;
					ld_curr_camera = 1;
					render_frame = 1;
					nextState = RENDERING;
				end
				else nextState = RENDERING;
			end
			default: nextState = IDLE;
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) state <= IDLE;
		else state <= nextState;
	end	

	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin	
			U <= {`FP_1,`FP_0,`FP_0};
			V <= {`FP_0,`FP_1,`FP_0};
			W <= {`FP_0,`FP_0,`FP_1};
		end
		else begin
			if(rot_en) begin
				U <= U_n;
				V <= V_n;
				W <= W_n;
			end
		end
	end

	camera_rotator  cr(.key(last_key),
			   .valid(cr_valid),
			   .U,.V,.W,
			   .U_n,.V_n,.W_n);

	camera_datapath cd(.clk,.rst,.v0,.v1,.v2,.ld_curr_camera,.render_frame,
			   .key(last_key),.cnt,.E,.U,.V,.W);


endmodule
