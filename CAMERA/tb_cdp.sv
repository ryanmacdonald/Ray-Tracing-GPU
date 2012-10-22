



module tb_cdp;

	logic clk,rst,v0,v1,v2,ld_curr_camera;
	logic[2:0] key;
	logic[31:0] cnt;
	logic[1:0] cntV,cnt_nV;
	vector_t E,U,V,W;

	assign cnt_nV = (cntV == 2'b10) ? 2'b00 : cntV+ 1'b1;

	ff_ar #(2,0) lol(.q(cntV),.d(cnt_nV),.clk,.rst);
	
	assign v0 = (cntV == 2'b00);
	assign v1 = (cntV == 2'b01);
	assign v2 = (cntV == 2'b10);

	camera_datapath cd(.*);

	initial begin	


		key <= 3'd0;		
		clk <= 0; rst <= 0; ld_curr_camera <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		cnt <= 32'h25;
		@(posedge clk);	

		repeat(50) @(posedge clk);
		
		ld_curr_camera <= 1;	
	
		@(posedge clk);
		
		ld_curr_camera <= 0;

		repeat(50) @(posedge clk);

		$finish;

	end

	
	always #5 clk = ~clk;

endmodule: tb_cdp
