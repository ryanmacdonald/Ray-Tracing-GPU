`default_nettype none



module tb_int_prg;

	// PRG TO INTERSECT INTERFACE
	logic clk, rst, v0, v1, v2, start, rayReady, done;
	vector_t E, U, V, W;
	float_t pw;
	prg_ray_t prg_data;
	
	logic full, we;
	pixelID_t pixelID;
	color_t color_out;
 	pixel_buffer_entry_t pixel_entry_out;

	prg       fuck(.*);
	int_wrap   int_inst(.valid_in(rayReady),.ray_in(prg_data),.v0(v1), .v1(v2), .v2(v0), .*);

	initial begin


		// Set E to (3,-1,-10)
		// Set U, V, W to appropriate unit vectors
		E.x <= $shortrealtobits(2.0); E.y <= $shortrealtobits(0); E.z <= $shortrealtobits(0);
		U.x <= `FP_1; U.y <= `FP_0; U.z <= `FP_0;
		V.x <= `FP_0; V.y <= `FP_1; V.z <= `FP_0;
		W.x <= `FP_0; W.y <= `FP_0; W.z <= `FP_1;
		// PW = 8/640 or 6/480 (.0125)
		pw <= 32'h3C4CCCCD;
 
		start <= 0;
		clk <= 1; rst <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		start <= 1;
		@(posedge clk);
		start <= 0;

		repeat(1000) @(posedge clk);


		$finish;

	end

  logic [1:0] cnt_nV, cntV;

	assign cnt_nV = ((cntV == 2'b10) ? 2'b00 : cntV + 1'b1);
	
	ff_ar #(2,0) cnt(.q(cntV),.d(cnt_nV),.clk,.rst);

	assign v0 = (cntV == 2'b00);
	assign v1 = (cntV == 2'b01);
	assign v2 = (cntV == 2'b10);
				
	always #5 clk = ~clk;

endmodule: tb_int_prg
