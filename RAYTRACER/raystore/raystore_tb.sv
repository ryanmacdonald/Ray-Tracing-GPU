`default_nettype none

`define NUM_CYCLES 20

// TODO: constrain node_type to be 00, 01, or 10
class trav_to_rs_c;
	rand trav_to_rs_t trav_to_rs;

	constraint legal_node_type {
		trav_to_rs.node.node_type dist { [0:3] :/ 1 };
	}

endclass

class ray_vec_c;
	rand ray_vec_t ray_vec;
endclass

module raystore_tb;


	// upstream interface

	trav_to_rs_t    trav_to_rs0;
	logic           trav_to_rs0_valid;
	logic           trav_to_rs0_stall;

	trav_to_rs_t    trav_to_rs1;
	logic           trav_to_rs1_valid;
	logic           trav_to_rs1_stall;

	icache_to_rs_t  icache_to_rs;
	logic           icache_to_rs_valid;
	logic           icache_to_rs_stall;

	list_to_rs_t    list_to_rs;
	logic           list_to_rs_valid;
	logic           list_to_rs_stall;

	// downstream interface

	rs_to_trav_t    rs_to_trav0;
	logic           rs_to_trav0_valid;
	logic           rs_to_trav0_stall;

	rs_to_trav_t    rs_to_trav1;
	logic           rs_to_trav1_valid;
	logic           rs_to_trav1_stall;

	rs_to_int_t  rs_to_int;
	logic           rs_to_int_valid;
	logic           rs_to_int_stall;

	rs_to_pcalc_t   rs_to_pcalc;
	logic           rs_to_pcalc_valid;
	logic           rs_to_pcalc_stall;

	// write interface

	logic raystore_we;
	logic [8:0] raystore_write_addr;
	ray_vec_t raystore_write_data;

	logic clk, rst;

	raystore rs(.*);

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		#1;
		forever #1 clk = ~clk;
	end

	logic [8:0] addresses [10];
	int addr_cnt;

	trav_to_rs_c t_to_rs;
	ray_vec_c ray;
	initial begin
		t_to_rs = new;
		ray = new;

		for(addr_cnt = 0; addr_cnt < 10; addr_cnt++)
			addresses[addr_cnt] = $random;

		// initial values
		trav_to_rs0 <= 'b0;
		trav_to_rs0_valid <= 1'b0;

		trav_to_rs1 <= 'b0;
		trav_to_rs1_valid <= 1'b0;

		icache_to_rs <= 'b0;
		icache_to_rs_valid <= 1'b0;

		list_to_rs <= 'b0;
		list_to_rs_valid <= 1'b0;

		raystore_we <= 1'b0;
		raystore_write_addr <= 'd0;
		raystore_write_data <= 'b0;

		for(addr_cnt = 0; addr_cnt < 10; addr_cnt++) begin
			ray.randomize();
			write_to_rs(ray,addresses[addr_cnt]);
		end

		for(addr_cnt = 0; addr_cnt < 10; addr_cnt++) begin
			read_from_trav(addresses[addr_cnt],0);
		end

		repeat(`NUM_CYCLES) @(posedge clk);

		$finish;
	end

	int i;
	logic [59:0] r [4];
	initial begin
		r[0] = 60'b0;
		r[1] = 60'b0;
		r[2] = 60'b0;
		r[3] = 60'b0;
		forever begin
			@(posedge clk);
			for(i=0; i<4; i++)
				r[i] <= {$random}%60;
		end
	end

	initial begin
		forever begin
			@(posedge clk);
			if(rs_to_trav0_valid && ~rs_to_trav0_stall)
				$display("rs_to_trav0: origin: %h dir: %h",rs_to_trav0.origin, rs_to_trav0.dir);
			if(rs_to_trav1_valid && ~rs_to_trav1_valid)
				$display("rs_to_trav1: origin: %h dir: %h",rs_to_trav1.origin, rs_to_trav1.dir);
			if(rs_to_int_valid && ~rs_to_int_valid)
				$display("rs_to_int: %h",rs_to_int);
			if(rs_to_pcalc_valid && ~rs_to_pcalc_valid)
				$display("rs_to_pcacl: %h",rs_to_pcalc);
		end
	end

	assign rs_to_trav0_stall  = (rs_to_trav0_valid  && r[0] < 20)? 1 : 0;
	assign rs_to_trav1_stall  = (rs_to_trav1_valid  && r[1] < 20)? 1 : 0;
	assign rs_to_int_stall = (rs_to_int_stall && r[2] < 20)? 1 : 0;
	assign rs_to_pcalc_stall  = (rs_to_pcalc_stall  && r[3] < 20)? 1 : 0;

	task write_to_rs(input ray_vec_c ray_in, input [8:0] addr);
		@(posedge clk);
		ray = ray_in;
		$display("======================================================");
		$display("writing to %h:",addr);
		$display("x: origin: %h dir: %h",ray.ray_vec.origin.x, ray.ray_vec.dir.x);
		$display("y: origin: %h dir: %h",ray.ray_vec.origin.y, ray.ray_vec.dir.y);
		$display("z: origin: %h dir: %h",ray.ray_vec.origin.z, ray.ray_vec.dir.z);
		$display("======================================================");
		raystore_write_addr <= addr;
		raystore_we <= 1'b1;
		raystore_write_data <= ray.ray_vec;

		@(posedge clk);
		raystore_we <= 1'b0;
	endtask

	task read_from_trav(input rayID_t addr, input trav_sel);
		@(posedge clk);
		t_to_rs.randomize();
		$display("******************************************************");
		$display("reading from %h",addr);
		$display("node type: ",t_to_rs.trav_to_rs.node.node_type);
		$display("******************************************************");
		if(trav_sel == 0) begin
			trav_to_rs0 <= t_to_rs.trav_to_rs;
			trav_to_rs0.ray_info.rayID <= addr;
			trav_to_rs0_valid <= 1'b1;
		end
		else begin
			trav_to_rs1 <= t_to_rs.trav_to_rs;
			trav_to_rs1.ray_info.rayID <= addr;
			trav_to_rs1_valid <= 1'b1;
		end

		@(posedge clk);
		if(trav_sel == 0)
			trav_to_rs0_valid <= 1'b0;
		else 
			trav_to_rs1_valid <= 1'b0;
	endtask

	task read_from_icache(rayID_t addr);
		@(posedge clk);
		$display("******************************************************");
		$display("reading from %h",addr);
		$display("******************************************************");
		icache_to_rs <= $random;
		icache_to_rs.ray_info.rayID <= addr;
		icache_to_rs_valid <= 1'b1;

		@(posedge clk);
		icache_to_rs_valid <= 1'b0;

	endtask

endmodule: raystore_tb
