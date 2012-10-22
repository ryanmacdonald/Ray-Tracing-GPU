



module tb_cdp;

	logic clk,rst,v0,v1,v2,ld_curr_camera;
	logic[2:0] key;
	logic[31:0] cnt;
	vector_t E,U,V,W;

	camera_datapath cd(.*);


	initial begin	

		clk <= 0; rst <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		cnt <= 32'h25;

		repeat(50) @(posedge clk);		

		$finish;

	end

	
	always #5 clk = ~clk;

endmodule: tb_cdp
