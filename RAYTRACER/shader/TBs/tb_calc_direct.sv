




module tb_calc_direct;


	logic clk, rst;
	logic v0, v1, v2;

	float_color_t ambient, light_color;
	
	logic dirpint_to_calc_direct_stall;
	dirpint_to_calc_direct_t dirpint_to_calc_direct_data;
	logic dirpint_to_calc_direct_valid;

	logic calc_direct_to_BM_stall;
	calc_direct_to_BM_t calc_direct_to_BM_data;
	logic calc_direct_to_BM_valid;
	
	calc_direct cd(.*);

	logic[1:0] cnt, ncnt;
	ff_ar #(2,0) vr(.q(cnt),.d(ncnt),.clk,.rst);

	assign ncnt = (cnt == 2'b10) ? 2'b00 : cnt + 1;

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);


	initial begin
	

	
		clk <= 1; rst <= 0;
		dirpint_to_calc_direct_valid <= 0;
		@(posedge clk);
		test('h0,0.0,0.0,0.0,'h0,'h0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		repeat(2) @(posedge clk);
		
	
		test(9'hFF,
		     1.0,1.0,1.0,
		     1'b1,1'b1,
		     1.0,0.0,0.0,
		     0.0,0.0,0.0,
		     3.0,3.0,0.0,150);

		@(posedge clk);

		test(9'hFE,
		     1.0,2.0,1.0,
		     1'b1,1'b0,
		     1.0,0.0,0.0,
		     0.0,0.0,0.0,
	             1.0,0.0,0.0,150); 	



		$finish;
	
	end

	always #10 clk = ~clk;



	task test(logic[8:0] rID,
		  shortreal Kr, Kg, Kb,
		  logic s, m,
		  shortreal Nx, Ny, Nz,
		  shortreal px, py, pz,
		  shortreal Lx, Ly, Lz,
		  int r);

	
		@(posedge clk) begin
	
			dirpint_to_calc_direct_valid <= 1;

			dirpint_to_calc_direct_data.rayID <= rID;
		
			ambient.red <= 32'h0;
			ambient.green <= 32'h0;
			ambient.blue <= 32'h0;
			
			dirpint_to_calc_direct_data.K.red <= $shortrealtobits(Kr);
			dirpint_to_calc_direct_data.K.green <= $shortrealtobits(Kg);
			dirpint_to_calc_direct_data.K.blue <= $shortrealtobits(Kb);

			light_color.red <= 32'h0;
			light_color.green <= 32'h0;
			light_color.blue <= 32'h0;
	
			dirpint_to_calc_direct_data.is_miss <= m;
			dirpint_to_calc_direct_data.is_shadow <= s;			

			dirpint_to_calc_direct_data.N.x <= $shortrealtobits(Nx);
			dirpint_to_calc_direct_data.N.y <= $shortrealtobits(Ny);
			dirpint_to_calc_direct_data.N.z <= $shortrealtobits(Nz);
			
			dirpint_to_calc_direct_data.p_int.x <= $shortrealtobits(px);
			dirpint_to_calc_direct_data.p_int.y <= $shortrealtobits(py);
			dirpint_to_calc_direct_data.p_int.z <= $shortrealtobits(pz);
			
			dirpint_to_calc_direct_data.L.x <= $shortrealtobits(Lx);
			dirpint_to_calc_direct_data.L.y <= $shortrealtobits(Ly);
			dirpint_to_calc_direct_data.L.z <= $shortrealtobits(Lz);
			
		end

		@(posedge clk) dirpint_to_calc_direct_valid <= 0;

		
		repeat(r) @(posedge clk);


	endtask


endmodule: tb_calc_direct
