`default_nettype none

`define CLOCK_PERIOD 20

module raystore_simple_tb;

	parameter SB_WIDTH = 8;

	logic clk, rst;

	logic                 us_valid;
	logic [SB_WIDTH-1:0]  us_sb_data;
	rayID_t               raddr;
	logic                 us_stall;

	logic     we;
	ray_vec_t wdata;
	rayID_t   waddr;

	logic                ds_valid;
	logic [SB_WIDTH-1:0] ds_sb_data;
	ray_vec_t            ds_rd_data;
	logic                ds_stall;

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		forever #(`CLOCK_PERIOD/2) clk = ~clk;
	end

	logic [$bits(rayID_t)-1:0] r;
	int x;
	initial begin
		$monitor("ds_rd_data: %h", ds_rd_data);

		us_valid <= 1'b0;
		us_sb_data <= 'b0;
		raddr <= 'b0;
		we <= 1'b0;
		wdata <= 'b0;
		waddr <= 'b0;
		ds_stall <= 1'b0;

		@(posedge clk);
		repeat(100) begin
			we <= 1'b1;
			r = $random;
			waddr <= r;
			if(~us_stall) begin
				raddr <= ~r;
				us_sb_data <= x;
			end
			us_valid <= 1'b1;
			wdata <= $random;
			x++;
			@(posedge clk);
		end
		we <= 1'b0;
		us_valid <= 1'b0;

		repeat(100) @(posedge clk);
		$finish;
	end

	raystore_simple #(.SB_WIDTH(SB_WIDTH)) rss(.*);

endmodule
