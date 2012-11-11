

//`define FP_0 32'h00000000
//`define FP_1 32'h3F800000

`define INIT_CAM_X 32'h40800000
`define INIT_CAM_Y 32'h40400000
`define INIT_CAM_Z 32'hC1200000

// move_scale = 1/50Mhz
`ifndef SYNTH
`define move_scale 32'h3F800000
`else
`define move_scale 32'h32ABCC77 
`endif


`define UNEG 3'b001
`define UPOS 3'b000

`define VNEG 3'b011
`define VPOS 3'b010

`define WNEG 3'b101
`define WPOS 3'b100


module camera_datapath (input logic clk, rst,
			input logic v0, v1, v2,
			input logic ld_curr_camera,
			input logic[2:0] key,
			input logic[31:0] cnt,
			output vector_t E, U, V, W);

`ifndef SYNTH
	shortreal nc_x,nc_y,nc_z;
	assign nc_x = $bitstoshortreal(nextCam.x);
	assign nc_y = $bitstoshortreal(nextCam.y);
	assign nc_z = $bitstoshortreal(nextCam.z);	
`endif

	logic[31:0] move_val, move_val_n;
	logic[2:0] last_key;
	logic update_cam;
	vector_t E_n,U_n,V_n,W_n;
	vector_t nextCam,nextCam_n;

	
	// Synchronizer
	sync_to_v #(0) vs(.synced_signal(update_cam),.clk,.rst,.v0,.v1,.v2,
			  .signal_to_sync(ld_curr_camera));
	

	////// FP INSTANTIATIONS AND LOGIC //////

	
	logic[31:0] conv_dataa, conv_result;
	assign conv_dataa = cnt;
	altfp_convert conv(.dataa(conv_dataa),.result(conv_result),
			   .clock(clk),.aclr(rst));

	logic[31:0] mult_1_dataa, mult_1_datab;
	logic mult_1_underflow, mult_1_overflow, mult_1_zero, mult_1_nan;
	logic[31:0] mult_1_result;
	assign mult_1_dataa = conv_result;
	assign mult_1_datab = `move_scale; 
	altfp_mult  mult_1(.dataa(mult_1_dataa),.datab(mult_1_datab),
			   .underflow(mult_1_underflow),.overflow(mult_1_overflow),
			   .nan(mult_1_nan),.zero(mult_1_zero),
			   .result(mult_1_result),
			   .clock(clk),.aclr(rst));

	logic[31:0] mult_2_dataa, mult_2_datab;
	logic mult_2_underflow, mult_2_overflow, mult_2_zero, mult_2_nan;
	logic[31:0] mult_2_result;
	assign mult_2_dataa = v2 ? mult_1_result : move_val;
	// mult_2_datab combinationally assigned in case 
	altfp_mult  mult_2(.dataa(mult_2_dataa),.datab(mult_2_datab),
			   .underflow(mult_2_underflow),.overflow(mult_2_overflow),
			   .nan(mult_2_nan),.zero(mult_2_zero),
			   .result(mult_2_result),
			   .clock(clk),.aclr(rst));

	logic[31:0] add_1_dataa, add_1_datab;
	logic add_1_underflow, add_1_overflow, add_1_zero, add_1_nan;
	logic[31:0] add_1_result;
	assign add_1_dataa = mult_2_result;
	assign add_1_datab = v1 ? E.x : (v2 ? E.y : E.z);
	altfp_add    add_1(.dataa(add_1_dataa),.datab(add_1_datab),
			   .underflow(add_1_underflow),.overflow(add_1_overflow),
			   .nan(add_1_nan),.zero(add_1_zero),
			   .result(add_1_result),
			   .clock(clk),.aclr(rst));

	
	////// FF INSTANTIATIONS FOR CAMERA REGS //////

	ff_ar_en #(32,0) mv(.q(move_val),.d(move_val_n),.en(v2),.clk,.rst);
	

	// Combinational logic for selecting vector (U,V,W),
	// component (x,y,z), and negation

	vector_t vector_sel;
	float_t  comp_sel;

	always_comb begin
		// Don't change these -> we aren't thinking about rotation yet		
		U_n = U;
		V_n = V;
		W_n = W;
		E_n = E;
		nextCam_n = nextCam;
		move_val_n = move_val;	

		if(v2) begin
			move_val_n = mult_1_result;
			nextCam_n.x = add_1_result;
		end
		else if(v0) begin
			nextCam_n.y = add_1_result;
		end
		else if(v1) begin
			nextCam_n.z = add_1_result;
		end

		case(last_key)
			`UPOS: vector_sel = U;
			`UNEG: vector_sel = U;
			`VPOS: vector_sel = V;
			`VNEG: vector_sel = V;
			`WPOS: vector_sel = W;
			`WNEG: vector_sel = W;
		default: vector_sel = 32'b0;
		endcase

		comp_sel = v2 ? vector_sel.x : (v0 ? vector_sel.y : vector_sel.z);

		mult_2_datab = last_key[0] ? {~comp_sel[31],comp_sel[30:0]} : comp_sel;

	end	

	ff_ar_en #(3,0) kreg(.q(last_key),.d(key),.en(ld_curr_camera),.clk,.rst);

	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			E <= {`INIT_CAM_X,`INIT_CAM_Y,`INIT_CAM_Z};
			U <= {`FP_1,`FP_0,`FP_0};
			V <= {`FP_0,`FP_1,`FP_0};
			W <= {`FP_0,`FP_0,`FP_1};
			nextCam <= {`FP_0,`FP_0,`FP_0};	
		end
		else begin
			if(update_cam) E <= nextCam_n;
			else E <= E_n;
			U <= U_n;
			V <= V_n;
			W <= W_n;
			nextCam <= nextCam_n;
		end
	end

endmodule: camera_datapath	
