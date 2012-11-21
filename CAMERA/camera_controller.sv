


module camera_controller(
  input clk, rst,
  input v0, v1, v2,

  input keys_t keys, // Keys packet from PS/2 
  
  input rendering_done,
  output logic render_frame,
  output vector_t E, U, V, W

  );
  // left right U
  // left = key_d   0
  // right = key_a  1

  // up/down V  
  // up = E         2
  // down = Q       3

  // in/out W       
  // in = W_key     4
  // out = S_key    5


  `ifndef SYNTH
  shortreal Ex,Ey,Ez;
  assign Ex = $bitstoshortreal(E.x);
  assign Ey = $bitstoshortreal(E.y);
  assign Ez = $bitstoshortreal(E.z);
  `endif
	logic ld_curr_camera;
	logic valid_key_press, valid_key_release;

	assign valid_key_press = (|{keys.d[0],keys.a[0],keys.e[0],keys.q[0],keys.w[0],keys.s[0]});
  	assign valid_key_release = (|{keys.d[1],keys.a[1],keys.e[1],keys.q[1],keys.w[1],keys.s[1]});

	logic rendering, rendering_n;
	assign rendering_n = valid_key_release ? 1'b0 :
			     ((valid_key_press || rendering) ? 1'b1 : 1'b0);
	ff_ar #(1,0) rd(.q(rendering),.d(rendering_n),.clk,.rst);

	logic[2:0] last_key, last_key_n;
	ff_ar #(3,0) kr(.q(last_key),.d(last_key_n),.clk,.rst);

	enum logic {IDLE, RENDERING} state, nextState;

	logic[31:0] cnt, cnt_n;
	logic cnt_cl;
	assign cnt_n = cnt_cl||(state == IDLE) ? 0 : (rendering  ? cnt + 10'd1 : 0);
	ff_ar #(32,0) ct(.q(cnt),.d(cnt_n),.clk,.rst);

	always_comb begin
		last_key_n = last_key;
		if(valid_key_press) begin
			case({keys.d[0],keys.a[0],keys.e[0],keys.q[0],keys.w[0],keys.s[0]})
				6'b10_00_00: last_key_n = 3'h0;
				6'b01_00_00: last_key_n = 3'h1;
				6'b00_10_00: last_key_n = 3'h2;
				6'b00_01_00: last_key_n = 3'h3;
				6'b00_00_10: last_key_n = 3'h4;
				6'b00_00_01: last_key_n = 3'h5;
				default: last_key_n = 3'h6;
			endcase
		end
		else if(valid_key_release) begin
			last_key_n = 3'h6;
		end
	end



	// Assumes that a key press will never be shorter than a render
	always_comb begin
		cnt_cl = 0; ld_curr_camera = 0; render_frame = 0; 
		case(state)
			IDLE:begin
				if(valid_key_press && ~rendering) begin
					ld_curr_camera = 1;
					render_frame = 1;	
					nextState = RENDERING;
				end
				else nextState = IDLE;
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
		

	camera_datapath cd(.clk,.rst,.v0,.v1,.v2,.ld_curr_camera,.render_frame,
			   .key(last_key),.cnt,.E,.U,.V,.W);


 /* 


  logic[1:0] CS0, NS0;

  logic rendering, rendering_n;
  logic valid_key_press, valid_key_release;
  logic pressed, released, ld_key_val;
  logic[2:0] key_val_n, key_val; 
  
  assign rendering_n = rendering_done ? 1'b0 : (render_frame ? 1'b1 : rendering);
  assign pressed = (CS0 == 2'b01);
  assign released = ~pressed;

  ff_ar #(1,'h0) ffrend(.q(rendering), .d(rendering_n), .clk, .rst);


  always_comb begin
    ld_key_val = 1'b0;
    case(CS0)
      2'b00 : begin
        NS0 = valid_key_press ? 2'b01 : 2'b00 ;
        ld_key_val = valid_key_press ;
      end
      2'b01 : begin
        NS0 = valid_key_release ? 2'b10 : 2'b01 ;
      end
      2'b10 : begin
        NS0 = rendering ? 2'b10 : 2'b00 ;
      end
      default: NS0 = 2'b00;
    endcase
  end

  ff_ar #(2,2'b00) ff(.q(CS0), .d(NS0), .clk, .rst);

  always_comb begin
    key_val_n = 'h0;
    if(ld_key_val) begin
      case({keys.d[0],keys.a[0],keys.e[0],keys.q[0],keys.w[0],keys.s[0]})
        6'b10_00_00 : key_val_n = 'h0;
        6'b01_00_00 : key_val_n = 'h1;
        6'b00_10_00 : key_val_n = 'h2;
        6'b00_01_00 : key_val_n = 'h3;
        6'b00_00_10 : key_val_n = 'h4;
        6'b00_00_01 : key_val_n = 'h5;
      endcase
    end 
  end
  
  ff_ar #(3,'h0) ff0(.q(key_val), .d(key_val_n), .clk, .rst);

  
  logic [31:0] mv_cnt, mv_cnt_n;
  logic stop_cnt, start_cnt0, start_cnt25, clr_cnt;
  logic is_counting, is_counting_n;

  assign is_counting_n = stop_cnt ? 1'b0 : (start_cnt0 | start_cnt25 ? 1'b1 : is_counting);
  
  ff_ar #(1,1'b0) ff1(.q(is_counting), .d(is_counting_n), .clk, .rst);
  
  // TODO might be sketchy, check this shit
  always_comb begin
    mv_cnt_n = mv_cnt ;
    case({clr_cnt|start_cnt0,start_cnt25,stop_cnt,v2&is_counting})
      4'b1??? : mv_cnt_n = 'h0;
      4'b01?? : mv_cnt_n = 'd25;
      4'b001? : mv_cnt_n = mv_cnt ;
      4'b0001 : mv_cnt_n = mv_cnt + 3'h3 ;
    endcase
  end

	assign mv_cnt_n = clr_cnt|start_cnt0 ? 'h0 :
		( start_cnt25 ? 'd25 :
		( stop_cnt ? mv_cnt :
		( v2 & is_counting ? mv_cnt+3'h3 : mv_cnt ) ) );

  ff_ar #(32,'h0) ff2(.q(mv_cnt), .d(mv_cnt_n), .clk, .rst);

  logic [1:0] CS1, NS1 ;
  
  always_comb begin
    clr_cnt = 1'b0;
    start_cnt0 = 1'b0;
    start_cnt25 = 1'b0;
    clr_cnt = 1'b0;
    render_frame = 1'b0;
    stop_cnt = 1'b0;
    case(CS1)
      2'b00 : begin
        NS1 = pressed ? 2'b01 : 2'b00 ;
        start_cnt0 = pressed;
        render_frame = pressed & ~rendering;
      end
      2'b01 : begin
        NS1 = released ? 2'b10 : 2'b01 ;
        stop_cnt = released ;
        render_frame = pressed & ~rendering;
        start_cnt25 = pressed & ~rendering;
      end
      2'b10 : begin
        NS1 = rendering ? 2'b10 : 2'b11 ;
        render_frame = ~rendering ;
      end
      2'b11 : begin
        NS1 = pressed ? 2'b01 : (rendering ? 2'b11 : 2'b00 ) ;
        start_cnt0 = pressed;
	clr_cnt = ~pressed & ~rendering;
        render_frame = pressed & ~rendering;
      end
    endcase
  end
  
  ff_ar #(2,2'b00) ff3(.q(CS1), .d(NS1), .clk, .rst);


	camera_datapath cd(.clk(clk),.rst(rst),.v0,.v1,.v2,.ld_curr_camera(render_frame),
			   .key(key_val),.cnt(mv_cnt),.E(E),.U(U),.V(V),.W(W));

	

*/

endmodule
