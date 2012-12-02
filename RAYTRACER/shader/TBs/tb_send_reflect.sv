



module tb_send_reflect;


	
	logic clk, rst;
	logic v0, v1, v2;
	logic dirpint_to_sendreflect_valid;
	dirpint_to_sendreflect_t dirpint_to_sendreflect_data;
	logic dirpint_to_sendreflect_stall;

	logic shader_to_sint_valid;
	shader_to_sint_t shader_to_sint_data;
	logic shader_to_sint_stall;

	logic[1:0] cnt, ncnt;
	assign ncnt = (2'b10 == cnt) ? 2'b00 : cnt + 1;
	ff_ar #(2,0) vr(.q(cnt),.d(ncnt),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);


	send_reflect sr(.*);


	initial begin

		clk <= 1; rst <= 0;
		dirpint_to_sendreflect_valid <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		@(posedge clk);
	
		@(posedge clk);
		reflect_ray(9'd0,
		            1.0,-1.0,0.0,
			    0.0,0.0,0.0,
			    0.0,1.0,0.0);


		reflect_ray(9'd1,
			    -1.0,-1.0,0.0,
			    1.0,2.0,3.0,
		            0.0,1.0,0.0);
		

		$finish;


	end

	always #10 clk = ~clk;


	integer i;
	initial begin
		forever @(posedge clk) begin
			i <= {$random} %2;
		end
	end


	always_comb begin
		//shader_to_sint_stall = (shader_to_sint_valid && i);
		shader_to_sint_stall = 1'b0;
	end


	task reflect_ray(rayID_t rID,
			 shortreal dirx, diry, dirz,
			 shortreal px, py, pz,
			 shortreal nrmx, nrmy, nrmz);


		@(posedge clk) begin
			dirpint_to_sendreflect_valid <= 1;
			dirpint_to_sendreflect_data.rayID <= rID;
			dirpint_to_sendreflect_data.dir.x <= $shortrealtobits(dirx);
			dirpint_to_sendreflect_data.dir.y <= $shortrealtobits(diry);
			dirpint_to_sendreflect_data.dir.z <= $shortrealtobits(dirz);
			dirpint_to_sendreflect_data.p_int.x <= $shortrealtobits(px);
			dirpint_to_sendreflect_data.p_int.y <= $shortrealtobits(py);
			dirpint_to_sendreflect_data.p_int.z <= $shortrealtobits(pz);
			dirpint_to_sendreflect_data.normal.x <= $shortrealtobits(nrmx);
			dirpint_to_sendreflect_data.normal.y <= $shortrealtobits(nrmy);
			dirpint_to_sendreflect_data.normal.z <= $shortrealtobits(nrmz);
		end

		@(posedge clk) begin
			dirpint_to_sendreflect_valid <= 0;
			dirpint_to_sendreflect_data.rayID <= 'h0;
			dirpint_to_sendreflect_data.dir.x <= 'h0;
			dirpint_to_sendreflect_data.dir.y <= 'h0;
			dirpint_to_sendreflect_data.dir.z <= 'h0;
			dirpint_to_sendreflect_data.p_int.x <= 'h0;
			dirpint_to_sendreflect_data.p_int.y <= 'h0;
			dirpint_to_sendreflect_data.p_int.z <= 'h0;
			dirpint_to_sendreflect_data.normal.x <= 'h0;
			dirpint_to_sendreflect_data.normal.y <= 'h0;
			dirpint_to_sendreflect_data.normal.z <= 'h0;
		end


		repeat(100) @(posedge clk);

	endtask



endmodule: tb_send_reflect
