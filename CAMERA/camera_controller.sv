


module camera_controller(
  input clk, rst,
  input v0, v1, v2,

  input keys_t keys, // Keys packet from 
  
  input rendering_done,
  output logic render_frame


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
  
  logic render_frame;

  logic rendering, rendering_n;
  logic pressed, released; 
  
  assign rendering_n = rendering_done ? 1'b0 : (render_frame ? 1'b1 : rendering);
  assign pressed = (CS0 == PRESSED);
  assign released = ~pressed;
  
  typedef enum[1:0] {NOT_PRESSED, PRESSED, RENDERING} CS0, NS0;

  always_comb begin
    ld_key_val = 1'b0;
    case(CS0)
      NOT_PRESSED : begin
        NS0 = keys.pressed ? PRESSED : NOT_PRESSED ;
        ld_key_val = keys.pressed ;
      end
      PRESSED : begin
        NS0 = keys.released ? RENDERING : PRESSED ;
      end
      RENDERING : begin
        NS0 = rendering ? RENDERING : ~RENDERING ;
      end
    endcase
  end

  ff_ar #(2,2'b00) ff(.q(CS0), .d(NS0), .clk, .rst);

  always_comb begin
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
  
  ff_ar #(3,'h0) ff(.q(key_val), .d(key_val_n), .clk, .rst);

  
  logic [31:0] mv_cnt, mv_cnt_n;
  logic stop_cnt, start_cnt0, start_cnt25, clr_cnt;
  logic is_counting, is_counting_n;

  assign is_counting_n = stop_cnt ? 1'b0 : (start_cnt0 | start_cnt25 ? 1'b1 : is_counting);
  
  ff_ar #(1,1'b0) ff(.q(is_counting), .d(is_counting_n), .clk, .rst);
  
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

  ff_ar #(32,'h0) ff(.q(mv_cnt), .d(mv_cnt_n), .clk, .rst);

  logic [1:0] CS1, NS1 ;
  
  always_comb begin
    clr_cnt = 1'b0;
    start_cnt0 = 1'b0;
    start_cnt25 = 1'b0;
    clr_cnt = 1'b0;
    render_frame = 1'b0;
    case(CS1)
      2'b00 : begin
        NS1 = pressed ? 2'b01 : 2'b00 ;
        start_cnt0 = pressed;
        render_frame = pressed & ~rendering;
      end
      2'b01 : begin
        NS1 = released ? 2'b10 : 1'b01 ;
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
        render_frame = pressed & ~rendering;
      end
    endcase
  end
  
  ff_ar #(2,2'b00) ff(.q(CS1), .d(NS1), .clk, .rst);



endmodule
