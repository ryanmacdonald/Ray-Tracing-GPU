`default_nettype none

// TODO: constrain node_type to be 00, 01, or 10
class trav_to_rs_c;
	rand trav_to_rs_t trav_to_rs;
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

	lcache_to_rs_t  lcache_to_rs;
	logic           lcache_to_rs_valid;
	logic           lcache_to_rs_stall;

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

	rs_to_icache_t  rs_to_icache;
	logic           rs_to_icache_valid;
	logic           rs_to_icache_stall;

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

	integer i;
	trav_to_rs_c t;
	ray_vec_c r;
	initial begin
		t = new;
		r = new;

		// initial values
		trav_to_rs0 <= 'b0;
		trav_to_rs0_valid <= 1'b0;
		rs_to_trav0_stall <= 1'b0;

		trav_to_rs1 <= 'b0;
		trav_to_rs1_valid <= 1'b0;
		rs_to_trav1_stall <= 1'b0;

		lcache_to_rs <= 'b0;
		lcache_to_rs_valid <= 1'b0;
		rs_to_icache_stall <= 1'b0;

		list_to_rs <= 'b0;
		list_to_rs_valid <= 1'b0;
		rs_to_pcalc_stall <= 1'b0;

		raystore_we <= 1'b0;
		raystore_write_addr <= 'd0;
		raystore_write_data <= 'b0;

		@(posedge clk);
		r.randomize();
		raystore_we <= 1'b1;
		raystore_write_data <= r.ray_vec;

		@(posedge clk);
		raystore_we <= 1'b0;

		@(posedge clk);
		t.randomize();
		trav_to_rs0 <= t.trav_to_rs;
		trav_to_rs0.rayID.ID <= 'b0; // want to read from address 0
		trav_to_rs0_valid <= 1'b1;

		@(posedge clk);
		trav_to_rs0_valid <= 1'b0;

		repeat(20) @(posedge clk);

		$finish;
	end

	/*
	int i;
	initial begin
		num_to_list = 0;
		num_to_larb = 0;
		i = 0;
		repeat(6000) begin
			@(posedge clk) i <= {$random}%60;
		end
		$finish;
	end

	always_comb begin
		if(int_to_list_valid && i < 57 ) int_to_list_stall = 1;
		else int_to_list_stall = 0;
		if(int_to_larb_valid && (i<58)) int_to_larb_stall = 1;
		else int_to_larb_stall = 0;
	end
	*/

endmodule: raystore_tb
