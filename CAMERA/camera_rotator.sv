

`define L_KEY 4'd6
`define J_KEY 4'd7
`define O_KEY 4'd8
`define U_KEY 4'd9
`define I_KEY 4'd10
`define K_KEY 4'd11




// Ugliest module 2012
module camera_rotator(input [3:0] key,
		      input vector_t U, V, W,
		      output logic valid,
		      output vector_t U_n, V_n, W_n);


	// Determines if a rotation is occurring
	assign valid = (4'd5 < key) && (key < 4'd12);

	// Determines if a CW or CCW rotation is occurring
	logic CW;
	assign CW = (key[0] == 0);

	/*enum logic[2:0] {ZERO,ONE,N_ONE,R2,N_R2} x_0, y_0, x_n_0, y_n_0,
						 x_1, y_1, x_n_1, y_n_1;*/

	float_t x_0, y_0, x_n_0, y_n_0, x_1, y_1, x_n_1, y_n_1;
	rotator r0(.CW(CW),.x(x_0),.y(y_0),.x_n(x_n_0),.y_n(y_n_0));
	rotator	r1(.CW(CW),.x(x_1),.y(y_1),.x_n(x_n_1),.y_n(y_n_1));

	always_comb begin
		U_n = U; V_n = V; W_n = W;
		if(valid) begin
			case(key[3:1])
				// Matches a key of L or J
				// V stays the same, W and U rotate CW or CCW
				3'd3:begin
					case({V.x,V.y,V.z})
						{`FP_1,`FP_0,`FP_0}: begin x_0 = W.y; y_0 = W.z; x_1 = U.y; y_1 = U.z;
									   W_n.y = x_n_0; W_n.z = y_n_0;
									   U_n.y = x_n_1; U_n.z = y_n_1; end
						{`FP_N1,`FP_0,`FP_0}:begin x_0 = W.z; y_0 = W.y; x_1 = U.z; y_1 = U.y;
									   W_n.z = x_n_0; W_n.y = y_n_0;
									   U_n.z = x_n_1; U_n.y = y_n_1; end	
						{`FP_0,`FP_1,`FP_0}: begin x_0 = W.x; y_0 = W.z; x_1 = U.x; y_1 = U.z;
									   W_n.x = x_n_0; W_n.z = y_n_0;
									   U_n.x = x_n_1; U_n.z = y_n_1; end
						{`FP_0,`FP_N1,`FP_0}:begin x_0 = W.z; y_0 = W.x; x_1 = U.z; y_1 = U.x;
									   W_n.z = x_n_0; W_n.x = y_n_0;
									   U_n.z = x_n_1; U_n.x = y_n_1; end	
						{`FP_0,`FP_0,`FP_1}: begin x_0 = W.y; y_0 = W.x; x_1 = U.y; y_1 = U.x;
									   W_n.y = x_n_0; W_n.x = y_n_0;
									   U_n.y = x_n_1; U_n.x = y_n_1; end
						{`FP_0,`FP_0,`FP_N1}:begin x_0 = W.x; y_0 = W.y; x_1 = U.x; y_1 = U.y;
									   W_n.x = x_n_0; W_n.y = y_n_0;
									   U_n.x = x_n_1; U_n.y = y_n_1; end	
						default: ;
					endcase		
				end
				// W stays the same, U and V rotate CW
				3'd4:begin
					case({W.x,W.y,W.z})
						{`FP_1,`FP_0,`FP_0}: begin x_0 = U.z; y_0 = U.y; x_1 = V.z; y_1 = V.y;
									   U_n.z = x_n_0; U_n.y = y_n_0;
									   V_n.z = x_n_1; V_n.y = y_n_1; end
						{`FP_N1,`FP_0,`FP_0}:begin x_0 = U.y; y_0 = U.z; x_1 = V.y; y_1 = V.z;
									   U_n.y = x_n_0; U_n.z = y_n_0;
									   V_n.y = x_n_1; V_n.z = y_n_1; end	
						{`FP_0,`FP_1,`FP_0}: begin x_0 = U.x; y_0 = U.z; x_1 = V.x; y_1 = V.z;
									   U_n.x = x_n_0; U_n.z = y_n_0;
									   V_n.x = x_n_1; V_n.z = y_n_1; end
						{`FP_0,`FP_N1,`FP_0}:begin x_0 = U.z; y_0 = U.x; x_1 = V.z; y_1 = V.x;
									   U_n.z = x_n_0; U_n.x = y_n_0;
									   V_n.z = x_n_1; V_n.x = y_n_1; end	
						{`FP_0,`FP_0,`FP_1}: begin x_0 = U.x; y_0 = U.y; x_1 = V.x; y_1 = V.y;
									   U_n.x = x_n_0; U_n.y = y_n_0;
									   V_n.x = x_n_1; V_n.y = y_n_1; end
						{`FP_0,`FP_0,`FP_N1}:begin x_0 = U.y; y_0 = U.x; x_1 = V.y; y_1 = V.x;
									   U_n.y = x_n_0; U_n.x = y_n_0;
									   V_n.y = x_n_1; V_n.x = y_n_1; end	
						default: ;
					endcase	
				end
				// U stays the same, V and W rotate CW
				3'd5:begin
					case({U.x,U.y,U.z})
						{`FP_1,`FP_0,`FP_0}: begin x_0 = V.z; y_0 = V.y; x_1 = W.z; y_1 = W.y;
									   V_n.z = x_n_0; V_n.y = y_n_0;
									   W_n.z = x_n_1; W_n.y = y_n_1; end
						{`FP_N1,`FP_0,`FP_0}:begin x_0 = V.y; y_0 = V.z; x_1 = W.y; y_1 = W.z;
									   V_n.y = x_n_0; V_n.z = y_n_0;
									   W_n.y = x_n_1; W_n.z = y_n_1; end	
						{`FP_0,`FP_1,`FP_0}: begin x_0 = V.z; y_0 = V.x; x_1 = W.z; y_1 = W.x;
									   V_n.z = x_n_0; V_n.x = y_n_0;
									   W_n.z = x_n_1; W_n.x = y_n_1; end
						{`FP_0,`FP_N1,`FP_0}:begin x_0 = V.x; y_0 = V.z; x_1 = W.x; y_1 = W.z;
									   V_n.x = x_n_0; V_n.z = y_n_0;
									   W_n.x = x_n_1; W_n.z = y_n_1; end	
						{`FP_0,`FP_0,`FP_1}: begin x_0 = V.x; y_0 = V.y; x_1 = W.x; y_1 = W.y;
									   V_n.x = x_n_0; V_n.y = y_n_0;
									   W_n.x = x_n_1; W_n.y = y_n_1; end
						{`FP_0,`FP_0,`FP_N1}:begin x_0 = V.y; y_0 = V.x; x_1 = W.y; y_1 = W.x;
									   V_n.y = x_n_0; V_n.x = y_n_0;
									   W_n.y = x_n_1; W_n.x = y_n_1; end	
						default: ;
					endcase
				end
				default: begin
					U_n = U; V_n = V; W_n = W;	
				end
			endcase
		end
	end	


endmodule: camera_rotator




// Old, non-enum rotator 
module rotator(input logic CW,
	       input float_t x, y,
	       output float_t x_n, y_n);



	always_comb begin
		if(CW) begin
			case({x,y})
				{`FP_0,`FP_1}:		 {x_n,y_n} = {`FP_R2,`FP_R2};
				{`FP_R2,`FP_R2}:	 {x_n,y_n} = {`FP_1,`FP_0};
				{`FP_1,`FP_0}:		 {x_n,y_n} = {`FP_R2,`FP_NR2}; 
				{`FP_R2,`FP_NR2}:	 {x_n,y_n} = {`FP_0,`FP_N1};
				{`FP_0,`FP_N1}:		 {x_n,y_n} = {`FP_NR2,`FP_NR2};
				{`FP_NR2,`FP_NR2}:	 {x_n,y_n} = {`FP_N1,`FP_0};
				{`FP_N1,`FP_0}:		 {x_n,y_n} = {`FP_NR2,`FP_R2};
				{`FP_NR2,`FP_R2}:	 {x_n,y_n} = {`FP_0,`FP_1};
				default: begin x_n = `FP_0; y_n = `FP_0; end
			endcase	
		end
		else begin
			case({x,y})
				{`FP_0,`FP_1}:		 {x_n,y_n} = {`FP_NR2,`FP_R2};
				{`FP_R2,`FP_R2}:	 {x_n,y_n} = {`FP_0,`FP_1};
				{`FP_1,`FP_0}:		 {x_n,y_n} = {`FP_R2,`FP_R2};  
				{`FP_R2,`FP_NR2}:	 {x_n,y_n} = {`FP_1,`FP_0};
				{`FP_0,`FP_N1}:		 {x_n,y_n} = {`FP_R2,`FP_NR2};
				{`FP_NR2,`FP_NR2}:	 {x_n,y_n} = {`FP_0,`FP_N1};
				{`FP_N1,`FP_0}:		 {x_n,y_n} = {`FP_NR2,`FP_NR2};
				{`FP_NR2,`FP_R2}:	 {x_n,y_n} = {`FP_N1,`FP_0};
				default: begin x_n = `FP_0; y_n = `FP_0; end
			endcase
		end
	end

endmodule: rotator






