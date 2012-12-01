



module tb_camera;

	logic clk, rst, v0, v1, v2, rendering_done, render_frame;
	keys_t keys;
	vector_t E, U, V, W;
	logic[1:0] cnt, cnt_n;

	camera_controller cc(.*);

	initial begin

		
		clk <= 1; rst <= 0; rendering_done <= 0;
		keys <= 'h0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		repeat(25) @(posedge clk);	
		@(posedge clk);
		keys.a[0] <= 1;
		keys.pressed <= 1;	
		@(posedge clk);
		keys.a[0] <= 0;
		keys.pressed <= 0;
		@(posedge clk);
		fork 
			render_done_ctrl(200);
			render_done_ctrl(300);
			key_release_ctrl(500);
		join




		// Change move scale
		@(posedge clk);
		keys.n8[0] <= 1;
		keys.pressed <= 1;
		@(posedge clk);
		keys.n8[0] <= 0;
		keys.pressed <= 0;
		repeat(10) @(posedge clk);
		keys.n8[1] <= 1;
		keys.released <= 1;
		@(posedge clk)
		keys.n8[1] <= 0;
		keys.released <= 0;



		@(posedge clk);
		keys.w[0] <= 1;
		keys.pressed <= 1;	
		@(posedge clk);
		keys.w[0] <= 0;
		keys.pressed <= 0;
		@(posedge clk);
		fork 
			render_done_ctrl(200);
			render_done_ctrl(300);
			key_release_ctrl_w(500);
		join

		// Hit the K key
		@(posedge clk);
		keys.k[0] <= 1;
		keys.pressed <= 1;	
		@(posedge clk);
		keys.k[0] <= 0;
		keys.pressed <= 0;
		@(posedge clk);
		fork 
			render_done_ctrl(200);
			render_done_ctrl(300);
			key_release_ctrl_o(500);
		join

		// Hit the K key
		@(posedge clk);
		keys.k[0] <= 1;
		keys.pressed <= 1;	
		@(posedge clk);
		keys.k[0] <= 0;
		keys.pressed <= 0;
		@(posedge clk);
		fork 
			render_done_ctrl(200);
			render_done_ctrl(300);
			key_release_ctrl_o(500);
		join

		// Hit the L key
		@(posedge clk);
		keys.l[0] <= 1;
		keys.pressed <= 1;	
		@(posedge clk);
		keys.l[0] <= 0;
		keys.pressed <= 0;
		@(posedge clk);
		fork 
			render_done_ctrl(200);
			render_done_ctrl(300);
			key_release_ctrl_l(500);
		join

		// Hit the I key
		@(posedge clk);
		keys.i[0] <= 1;
		keys.pressed <= 1;	
		@(posedge clk);
		keys.i[0] <= 0;
		keys.pressed <= 0;
		@(posedge clk);
		fork 
			render_done_ctrl(200);
			render_done_ctrl(300);
			key_release_ctrl_i(500);
		join
		//render_done_ctrl(50);
		//render_done_ctrl(50);

		repeat(1000) @(posedge clk);	

		$finish;

	end

	ff_ar #(2,0) vc(.q(cnt),.d(cnt_n),.clk,.rst);

	assign cnt_n = (cnt == 2'b10) ? 2'b00 : (cnt + 1'b1);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);

	always #5 clk = ~clk;


	task render_done_ctrl(int cycles);

		repeat(cycles) @(posedge clk);

		rendering_done <= 1;
	
		@(posedge clk);

		rendering_done <= 0;


	endtask


	task key_release_ctrl(int cycles);


		repeat(cycles) @(posedge clk);

		keys.a[1] <= 1;
		keys.released <= 1;

		@(posedge clk);

		keys.a[1] <= 0;
		keys.released <= 0;		


	endtask

	task key_release_ctrl_w(int cycles);


		repeat(cycles) @(posedge clk);

		keys.w[1] <= 1;
		keys.released <= 1;

		@(posedge clk);

		keys.w[1] <= 0;
		keys.released <= 0;		


	endtask


	task key_release_ctrl_l(int cycles);


		repeat(cycles) @(posedge clk);

		keys.l[1] <= 1;
		keys.released <= 1;

		@(posedge clk);

		keys.l[1] <= 0;
		keys.released <= 0;		


	endtask

	task key_release_ctrl_o(int cycles);


		repeat(cycles) @(posedge clk);

		keys.o[1] <= 1;
		keys.released <= 1;

		@(posedge clk);

		keys.o[1] <= 0;
		keys.released <= 0;		


	endtask


	task key_release_ctrl_i(int cycles);


		repeat(cycles) @(posedge clk);

		keys.i[1] <= 1;
		keys.released <= 1;

		@(posedge clk);

		keys.i[1] <= 0;
		keys.released <= 0;		


	endtask


endmodule: tb_camera
