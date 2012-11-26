

`define L_KEY 4'd6
`define J_KEY 4'd7
`define O_KEY 4'd8
`define U_KEY 4'd9
`define I_KEY 4'd10
`define K_KEY 4'd11


module camera_rotator(input [3:0] key,
		      input vector_t U, V, W,
		      output logic valid,
		      output vector_t U_n, V_n, W_n);


	// Determines if a rotation is occurring
	assign valid = (5 < key) && (key < 4'd12);

	// Determines if a CW or CCW rotation is occurring
	logic CW;
	assign CW = (key[0] == 0);

	float_t x_0, y_0, x_n_0, y_n_0;
	float_t x_1, y_1, x_n_1, y_n_1; 
	rotator r0(.CW(CW),.x(x_0),.y(y_0),.x_n(x_n_0),.y_n(y_n_0));
	rotator	r1(.CW(CW),.x(x_1),.y(y_1),.x_n(x_n_1),.y_n(y_n_1));

	always_comb begin
		U_n = U; V_n = V; W_n = W;
		if(valid) begin
			case(key)
				// V stays the same, W and U rotate CW
				`L_KEY:begin
					x_0 = W.x; y_0 = W.z;
					x_1 = U.x; y_1 = U.z;
					{W_n.x,W_n.z} = {x_n_0,y_n_0};
					{U_n.x,U_n.z} = {x_n_1,y_n_1};				
				end
				// V stays the same, W and U rotate CCW
				`J_KEY:begin
					x_0 = W.x; y_0 = W.z;
					x_1 = U.x; y_1 = U.z;
					{W_n.x,W_n.z} = {x_n_0,y_n_0};
					{U_n.x,U_n.z} = {x_n_1,y_n_1};	
				end
				// W stays the same, U and V rotate CW
				`O_KEY:begin
					x_0 = U.x; y_0 = U.y;
					x_1 = V.x; y_1 = V.y;
					{U_n.x,U_n.y} = {x_n_0,y_n_0};
					{V_n.x,V_n.y} = {x_n_1,y_n_1};
				end
				// W stays the same, U and V rotate CCW
				`U_KEY:begin
					x_0 = U.x; y_0 = U.y;
					x_1 = V.x; y_1 = V.y;
					{U_n.x,U_n.y} = {x_n_0,y_n_0};
					{V_n.x,V_n.y} = {x_n_1,y_n_1};
				end
				// U stays the same, V and W rotate CW
				`I_KEY:begin
					x_0 = V.z; y_0 = V.y;
					x_1 = W.z; y_1 = W.y;
					{V_n.z,V_n.y} = {x_n_0,y_n_0};
					{W_n.z,W_n.y} = {x_n_1,y_n_1};
				end
				// U stays the same, V and W rotate CCW
				`K_KEY:begin
					x_0 = V.z; y_0 = V.y;
					x_1 = W.z; y_1 = W.y;
					{V_n.z,V_n.y} = {x_n_0,y_n_0};
					{W_n.z,W_n.y} = {x_n_1,y_n_1};
				end
				default: begin
					U_n = U; V_n = V; W_n = W;	
				end
			endcase
		end
	end	


endmodule: camera_rotator





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
