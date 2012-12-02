


module tb_send_shadow;

	logic clk, rst;
	logic v0, v1, v2;
	logic scache_to_sendshadow_valid;
  	scache_to_sendshadow_t scache_to_sendshadow_data;
	logic scache_to_sendshadow_stall;

	logic sendshadow_to_sint_valid;
	shader_to_sint_t sendshadow_to_sint_data;
	logic sendshadow_to_sint_stall;

	logic shadow_or_miss_valid;
	shadow_or_miss_t shadow_or_miss_data;
	logic shadow_or_miss_stall;
	

	send_shadow ss(.*);

	logic[1:0] cnt, ncnt;
	assign ncnt = (cnt == 2'b10) ? 2'b00 : cnt + 1;
	ff_ar #(2,0) vr(.q(cnt),.d(ncnt),.clk,.rst);

	assign v0 = (cnt == 2'b00);
	assign v1 = (cnt == 2'b01);
	assign v2 = (cnt == 2'b10);


	initial begin

		clk <= 1; rst <= 0;
		shadow_or_miss_stall <= 0;
		sendshadow_to_sint_stall <= 0;
		@(posedge clk);
		rst <= 1;
		@(posedge clk);
		rst <= 0;
		@(posedge clk);
		@(posedge clk);
		
		shadow(9'd0,
		       0.0,0.0,0.0,
		       0.0,0.0,0.0,
		       0.0,0.0,0.0);

		
		shadow(9'd1,
		       1.0,1.0,0.0,
		       0.0,1.0,0.0,
		       3.0,3.0,0.0);	
		


		$finish;

	end
	
	always #10 clk = ~clk;


	task shadow(logic[8:0] rID,
		    shortreal px, py, pz,
		    shortreal nx, ny, nz,
		    shortreal lx, ly, lz);


		@(posedge clk) begin
			scache_to_sendshadow_valid <= 1;
			scache_to_sendshadow_data.rayID <= rID;
			scache_to_sendshadow_data.p_int.x <= $shortrealtobits(px);
			scache_to_sendshadow_data.p_int.y <= $shortrealtobits(py);
			scache_to_sendshadow_data.p_int.z <= $shortrealtobits(pz);
			scache_to_sendshadow_data.normal.x <= $shortrealtobits(nx);
			scache_to_sendshadow_data.normal.y <= $shortrealtobits(ny);
			scache_to_sendshadow_data.normal.z <= $shortrealtobits(nz);
			scache_to_sendshadow_data.light.x <= $shortrealtobits(lx);
			scache_to_sendshadow_data.light.y <= $shortrealtobits(ly);
			scache_to_sendshadow_data.light.z <= $shortrealtobits(lz);
		end
		
		@(posedge clk);
		scache_to_sendshadow_valid <= 0;

		repeat(100) @(posedge clk);


	endtask


endmodule: tb_send_shadow
