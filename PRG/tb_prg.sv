


module tb_prg;

	logic clk, rst,v0,v1,v2, done,start, ready, idle, rayReady;
	logic[1:0] cntV,cnt_nV;
	logic int_to_prg_stall;
	vector_t E, U, V, W;
	float_t D, pw;
	prg_ray_t prg_data;


	assign cnt_nV =  ((cntV == 2'b10) ? 2'b0 : cntV + 1'b1);

 	ff_ar #(2,0) cnt3(.q(cntV), .d(cnt_nV), .clk, .rst);

	assign v0 = (cntV == 2'b00);
	assign v1 = (cntV == 2'b01);
	assign v2 = (cntV == 2'b10);


	prg_top fuck(.*);

	initial begin

			$monitor($time," \nray_t(%b) rayID = %d\ndata.dir.x = %f\ndata.dir.y = %f\ndata.dir.z = %f", rayReady,prg_data.pixelID,prg_data.dir.x,prg_data.dir.y,prg_data.dir.z);

		rst <= 0; clk <= 0;
		E.x <= `FP_0; E.y <= `FP_0; E.z <= `FP_0;
		U.x <= `FP_1; U.y <= `FP_0; U.z <= `FP_0;
		V.x <= `FP_0; V.y <= `FP_1; V.z <= `FP_0;
		W.x <= `FP_0; W.y <= `FP_0; W.z <= `FP_1;
		start <= 0;
		int_to_prg_stall <= 0;
		D <= 32'h42C80000;
		pw <= `FP_1;
		@(posedge clk); 
		rst <= 1;
		@(posedge clk); 
		rst <= 0;
		@(posedge v1); 
		start <= 1;
		@(posedge clk);
		start <= 0;

		repeat(100) @(posedge clk);

		int_to_prg_stall <= 1;

		repeat(100) @(posedge clk);

		int_to_prg_stall <= 0;

		while(~done)
			@(posedge clk);

		$finish;

	end
	

	always #5 clk = ~clk;

endmodule: tb_prg

