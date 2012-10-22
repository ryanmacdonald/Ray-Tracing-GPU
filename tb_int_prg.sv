



module tb_int_prg;

	// PRG TO INTERSECT INTERFACE
	logic clk, rst, v0, v1, v2, start, rayReady, done;
	vector_t E, U, V, W;
	float_t pw;
	ray_t prg_data;
	
	logic full, we;
	rayID_t rayID;
	color_t color;

	prg       fuck(.*);
	int_wrap   545(.valid_in(rayready),.ray_in(prg_data),.*,.clk,.rst);

	initial begin


		// Set E to (3,-1,-10)
		// Set U, V, W to appropriate unit vectors
		E.x <= 32'h40400000; E.y <= 32'hBF800000; E.z <= 32'hC1200000;
		U.x <= `FP_1; U.y <= `FP_0; U.z <= `FP_0;
		V.x <= `FP_0; V.y <= `FP_1; V.z <= `FP_0;
		W.x <= `FP_0; W.y <= `FP_0; W.z <= `FP_1;
		// PW = 6/640 or 4/480 (.009375)
		pw <= 32'h3C19999A;
 
		start <= 0;
		clk <= 1; rst <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		start <= 1;
		@(posedge clk);
		start <= 0;
		
		while(~done) @(posedge clk);

		repeat(100) @(posedge clk);


		$finish;

	end


	assign cnt_nV = ((cntV == 2'b10) ? 2'b10 : cntV + 1'b1);
	
	ff_ar #(2,0) cnt(.q(cntV),.d(cnt_nV),.clk,.rst);

	assign v0 = (cntV == 2'b00);
	assign v1 = (cntV == 2'b01);
	assign v2 = (cntV == 2'b10);
				
	always #5 clk = ~clk;

endmodule: tb_int_prg
