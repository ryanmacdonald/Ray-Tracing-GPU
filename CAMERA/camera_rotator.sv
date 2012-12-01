

`define L_KEY 4'd6
`define J_KEY 4'd7
`define O_KEY 4'd8
`define U_KEY 4'd9
`define I_KEY 4'd10
`define K_KEY 4'd11




// Ugliest module 2012

typedef enum logic[2:0] {ZERO = 3'b000,
	      	  	 ONE = 3'b011, N_ONE = 3'b111,
	    		 R2  = 3'b010, N_R2  = 3'b110} coord; 

module camera_rotator(input [3:0] key,
		      input vector_t U, V, W,
		      output logic valid,
		      output vector_t U_n, V_n, W_n);


	// Determines if a rotation is occurring
	assign valid = (4'd5 < key) && (key < 4'd12);

	// Determines if a CW or CCW rotation is occurring
	logic CW;
	assign CW = (key[0] == 0);


	coord x_0, y_0, x_1, y_1;
	float_t x_n_0, y_n_0, x_n_1, y_n_1;
	rotator r0(.CW(CW),.x(x_0),.y(y_0),.x_n(x_n_0),.y_n(y_n_0));
	rotator	r1(.CW(CW),.x(x_1),.y(y_1),.x_n(x_n_1),.y_n(y_n_1));

	coord Ux, Uy, Uz, Vx, Vy, Vz, Wx, Wy, Wz;

	assign Ux = float_to_enum(U.x); 
	assign Uy = float_to_enum(U.y); 
	assign Uz = float_to_enum(U.z);
	assign Vx = float_to_enum(V.x); 
	assign Vy = float_to_enum(V.y); 
	assign Vz = float_to_enum(V.z);
	assign Wx = float_to_enum(W.x); 
	assign Wy = float_to_enum(W.y); 
	assign Wz = float_to_enum(W.z);

	always_comb begin
		U_n = U; V_n = V; W_n = W;
		x_0 = ZERO; y_0 = ZERO; x_1 = ZERO; y_1 = ZERO;
		if(valid) begin
			casex(key[3:1])
				// Matches a key of L or J
				// V stays the same, W and U rotate CW or CCW
				3'd3:begin
					casex({Vx,Vy,Vz})
						{3'hX,ZERO,ZERO}: begin x_0 = Wy; y_0 = Wz; x_1 = Uy; y_1 = Uz;
									   W_n.y = x_n_0; W_n.z = y_n_0;
									   U_n.y = x_n_1; U_n.z = y_n_1; end
						{ZERO,3'hX,ZERO}: begin x_0 = Wx; y_0 = Wz; x_1 = Ux; y_1 = Uz;
									   W_n.x = x_n_0; W_n.z = y_n_0;
									   U_n.x = x_n_1; U_n.z = y_n_1; end
						{ZERO,ZERO,3'hX}: begin x_0 = Wy; y_0 = Wx; x_1 = Uy; y_1 = Ux;
									   W_n.y = x_n_0; W_n.x = y_n_0;
									   U_n.y = x_n_1; U_n.x = y_n_1; end
						default: ;
					endcase		
				end
				// W stays the same, U and V rotate CW
				3'd4:begin
					casex({Wx,Wy,Wz})
						{3'hX,ZERO,ZERO}: begin x_0 = Uz; y_0 = Uy; x_1 = Vz; y_1 = Vy;
									   U_n.z = x_n_0; U_n.y = y_n_0;
									   V_n.z = x_n_1; V_n.y = y_n_1; end
						{ZERO,3'hX,ZERO}: begin x_0 = Ux; y_0 = Uz; x_1 = Vx; y_1 = Vz;
									   U_n.x = x_n_0; U_n.z = y_n_0;
									   V_n.x = x_n_1; V_n.z = y_n_1; end
						{ZERO,ZERO,3'hX}: begin x_0 = Ux; y_0 = Uy; x_1 = Vx; y_1 = Vy;
									   U_n.x = x_n_0; U_n.y = y_n_0;
									   V_n.x = x_n_1; V_n.y = y_n_1; end
						default: ;
					endcase	
				end
				// U stays the same, V and W rotate CW
				3'd5:begin
					casex({Ux,Uy,Uz})
						{3'hX,ZERO,ZERO}: begin x_0 = Vz; y_0 = Vy; x_1 = Wz; y_1 = Wy;
									   V_n.z = x_n_0; V_n.y = y_n_0;
									   W_n.z = x_n_1; W_n.y = y_n_1; end
						{ZERO,3'hX,ZERO}: begin x_0 = Vz; y_0 = Vx; x_1 = Wz; y_1 = Wx;
									   V_n.z = x_n_0; V_n.x = y_n_0;
									   W_n.z = x_n_1; W_n.x = y_n_1; end
						{ZERO,ZERO,3'hX}: begin x_0 = Vx; y_0 = Vy; x_1 = Wx; y_1 = Wy;
									   V_n.x = x_n_0; V_n.y = y_n_0;
									   W_n.x = x_n_1; W_n.y = y_n_1; end
						default: ;
					endcase
				end
				default: begin
					U_n = U; V_n = V; W_n = W;	
				end
			endcase
		end
	end	

	function coord float_to_enum(float_t x);

		case({x[31],x[24],x[23]})
			3'b000: return ZERO;
			3'b011: return ONE;
			3'b111: return N_ONE;
			3'b010: return R2;
			3'b110: return N_R2;
			default: return ZERO;
		endcase

	endfunction


endmodule: camera_rotator





module rotator(input logic CW,
	       input  coord x, y,
	       output float_t x_n, y_n);



	always_comb begin
		if(CW) begin
			case({x,y})
				{ZERO,ONE}:	{x_n,y_n} = {`FP_R2,`FP_R2};
				{R2,R2}:	{x_n,y_n} = {`FP_1,`FP_0};
				{ONE,ZERO}:	{x_n,y_n} = {`FP_R2,`FP_NR2}; 
				{R2,N_R2}:	{x_n,y_n} = {`FP_0,`FP_N1};
				{ZERO,N_ONE}:	{x_n,y_n} = {`FP_NR2,`FP_NR2};
				{N_R2,N_R2}:	{x_n,y_n} = {`FP_N1,`FP_0};
				{N_ONE,ZERO}:	{x_n,y_n} = {`FP_NR2,`FP_R2};
				{N_R2,R2}:	{x_n,y_n} = {`FP_0,`FP_1};
				default: begin {x_n,y_n} = {`FP_0,`FP_0}; end
			endcase	
		end
		else begin
			case({x,y})
				{ZERO,ONE}:	{x_n,y_n} = {`FP_NR2,`FP_R2};
				{R2,R2}:	{x_n,y_n} = {`FP_0,`FP_1};
				{ONE,ZERO}:	{x_n,y_n} = {`FP_R2,`FP_R2};  
				{R2,N_R2}:	{x_n,y_n} = {`FP_1,`FP_0};
				{ZERO,N_ONE}:	{x_n,y_n} = {`FP_R2,`FP_NR2};
				{N_R2,N_R2}:	{x_n,y_n} = {`FP_0,`FP_N1};
				{N_ONE,ZERO}:	{x_n,y_n} = {`FP_NR2,`FP_NR2};
				{N_R2,R2}:	{x_n,y_n} = {`FP_N1,`FP_0};
				default: begin {x_n,y_n} = {`FP_0,`FP_0}; end
			endcase
		end
	end

endmodule: rotator





/*
// Old, non-enum rotator 
module rotator(input logic CW,
	       input float_t x, y,
	       output float_t x_n, y_n);



	always_comb begin
		if(CW) begin
			case({x,y})
				{ZERO,ONE}:		 {x_n,y_n} = {R2,R2};
				{R2,R2}:	 {x_n,y_n} = {ONE,ZERO};
				{ONE,ZERO}:		 {x_n,y_n} = {R2,N_R2}; 
				{R2,N_R2}:	 {x_n,y_n} = {ZERO,N_ONE};
				{ZERO,N_ONE}:		 {x_n,y_n} = {N_R2,`FP_NR2};
				{N_R2,`FP_NR2}:	 {x_n,y_n} = {N_ONE,ZERO};
				{N_ONE,ZERO}:		 {x_n,y_n} = {N_R2,R2};
				{N_R2,R2}:	 {x_n,y_n} = {ZERO,ONE};
				default: begin x_n = ZERO; y_n = ZERO; end
			endcase	
		end
		else begin
			case({x,y})
				{ZERO,ONE}:		 {x_n,y_n} = {N_R2,R2};
				{R2,R2}:	 {x_n,y_n} = {ZERO,ONE};
				{ONE,ZERO}:		 {x_n,y_n} = {R2,R2};  
				{R2,N_R2}:	 {x_n,y_n} = {ONE,ZERO};
				{ZERO,N_ONE}:		 {x_n,y_n} = {R2,N_R2};
				{N_R2,`FP_NR2}:	 {x_n,y_n} = {ZERO,N_ONE};
				{N_ONE,ZERO}:		 {x_n,y_n} = {N_R2,`FP_NR2};
				{N_R2,R2}:	 {x_n,y_n} = {N_ONE,ZERO};
				default: begin x_n = ZERO; y_n = ZERO; end
			endcase
		end
	end

endmodule: rotator
*/

/*
module camera_rotator(input [3:0] key,
		      input vector_t U, V, W,
		      output logic valid,
		      output vector_t U_n, V_n, W_n);


	// Determines if a rotation is occurring
	assign valid = (4'd5 < key) && (key < 4'd12);

	// Determines if a CW or CCW rotation is occurring
	logic CW;
	assign CW = (key[0] == 0);


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
						{ONE,ZERO,ZERO}: begin x_0 = W.y; y_0 = W.z; x_1 = U.y; y_1 = U.z;
									   W_n.y = x_n_0; W_n.z = y_n_0;
									   U_n.y = x_n_1; U_n.z = y_n_1; end
						{N_ONE,ZERO,ZERO}:begin x_0 = W.z; y_0 = W.y; x_1 = U.z; y_1 = U.y;
									   W_n.z = x_n_0; W_n.y = y_n_0;
									   U_n.z = x_n_1; U_n.y = y_n_1; end	
						{ZERO,ONE,ZERO}: begin x_0 = W.x; y_0 = W.z; x_1 = U.x; y_1 = U.z;
									   W_n.x = x_n_0; W_n.z = y_n_0;
									   U_n.x = x_n_1; U_n.z = y_n_1; end
						{ZERO,N_ONE,ZERO}:begin x_0 = W.z; y_0 = W.x; x_1 = U.z; y_1 = U.x;
									   W_n.z = x_n_0; W_n.x = y_n_0;
									   U_n.z = x_n_1; U_n.x = y_n_1; end	
						{ZERO,ZERO,ONE}: begin x_0 = W.y; y_0 = W.x; x_1 = U.y; y_1 = U.x;
									   W_n.y = x_n_0; W_n.x = y_n_0;
									   U_n.y = x_n_1; U_n.x = y_n_1; end
						{ZERO,ZERO,N_ONE}:begin x_0 = W.x; y_0 = W.y; x_1 = U.x; y_1 = U.y;
									   W_n.x = x_n_0; W_n.y = y_n_0;
									   U_n.x = x_n_1; U_n.y = y_n_1; end	
						default: ;
					endcase		
				end
				// W stays the same, U and V rotate CW
				3'd4:begin
					case({W.x,W.y,W.z})
						{ONE,ZERO,ZERO}: begin x_0 = U.z; y_0 = U.y; x_1 = V.z; y_1 = V.y;
									   U_n.z = x_n_0; U_n.y = y_n_0;
									   V_n.z = x_n_1; V_n.y = y_n_1; end
						{N_ONE,ZERO,ZERO}:begin x_0 = U.y; y_0 = U.z; x_1 = V.y; y_1 = V.z;
									   U_n.y = x_n_0; U_n.z = y_n_0;
									   V_n.y = x_n_1; V_n.z = y_n_1; end	
						{ZERO,ONE,ZERO}: begin x_0 = U.x; y_0 = U.z; x_1 = V.x; y_1 = V.z;
									   U_n.x = x_n_0; U_n.z = y_n_0;
									   V_n.x = x_n_1; V_n.z = y_n_1; end
						{ZERO,N_ONE,ZERO}:begin x_0 = U.z; y_0 = U.x; x_1 = V.z; y_1 = V.x;
									   U_n.z = x_n_0; U_n.x = y_n_0;
									   V_n.z = x_n_1; V_n.x = y_n_1; end	
						{ZERO,ZERO,ONE}: begin x_0 = U.x; y_0 = U.y; x_1 = V.x; y_1 = V.y;
									   U_n.x = x_n_0; U_n.y = y_n_0;
									   V_n.x = x_n_1; V_n.y = y_n_1; end
						{ZERO,ZERO,N_ONE}:begin x_0 = U.y; y_0 = U.x; x_1 = V.y; y_1 = V.x;
									   U_n.y = x_n_0; U_n.x = y_n_0;
									   V_n.y = x_n_1; V_n.x = y_n_1; end	
						default: ;
					endcase	
				end
				// U stays the same, V and W rotate CW
				3'd5:begin
					case({U.x,U.y,U.z})
						{ONE,ZERO,ZERO}: begin x_0 = V.z; y_0 = V.y; x_1 = W.z; y_1 = W.y;
									   V_n.z = x_n_0; V_n.y = y_n_0;
									   W_n.z = x_n_1; W_n.y = y_n_1; end
						{N_ONE,ZERO,ZERO}:begin x_0 = V.y; y_0 = V.z; x_1 = W.y; y_1 = W.z;
									   V_n.y = x_n_0; V_n.z = y_n_0;
									   W_n.y = x_n_1; W_n.z = y_n_1; end	
						{ZERO,ONE,ZERO}: begin x_0 = V.z; y_0 = V.x; x_1 = W.z; y_1 = W.x;
									   V_n.z = x_n_0; V_n.x = y_n_0;
									   W_n.z = x_n_1; W_n.x = y_n_1; end
						{ZERO,N_ONE,ZERO}:begin x_0 = V.x; y_0 = V.z; x_1 = W.x; y_1 = W.z;
									   V_n.x = x_n_0; V_n.z = y_n_0;
									   W_n.x = x_n_1; W_n.z = y_n_1; end	
						{ZERO,ZERO,ONE}: begin x_0 = V.x; y_0 = V.y; x_1 = W.x; y_1 = W.y;
									   V_n.x = x_n_0; V_n.y = y_n_0;
									   W_n.x = x_n_1; W_n.y = y_n_1; end
						{ZERO,ZERO,N_ONE}:begin x_0 = V.y; y_0 = V.x; x_1 = W.y; y_1 = W.x;
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
*/

