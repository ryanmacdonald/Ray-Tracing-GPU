`default_nettype none


`define CLOCK_PERIOD 20

module lshape_tb;

	parameter SIDE_W = 4, UNSTALL_W = 4, DEPTH = 20;

	logic clk, rst;
	logic us_valid;
	logic [SIDE_W-1:0] us_side_data;
	logic us_stall;
	
	logic [UNSTALL_W-1:0] us_unstall_data, us_unstall_data_in;

	logic empty;
	logic [SIDE_W + UNSTALL_W-1:0] ds_data;
	logic rdreq;
	logic ds_stall;

	initial begin
		clk <= 1'b0;
		rst <= 1'b0;
		#1;
		rst <= 1'b1;
		#1;
		rst <= 1'b0;
		#1;
		forever #(`CLOCK_PERIOD/2) clk = ~clk;
	end

	int watchdog = 1000;
	int num_reads = DEPTH+50;
	int num_writes = num_reads;
	int i;
	int us_stall_count = 0;
	int ds_stall_count = 0;

	initial begin
		// initialize inputs
		us_valid <= 1'b0;
		us_side_data <= 'b0;
		us_unstall_data_in <= 'b0;

		rdreq <= 1'b0;
		ds_stall <= 1'b0;

		i = 0;
		
		@(posedge clk);
		repeat(num_writes) begin
			if(!empty) begin
				ds_stall <= {$random} % 2;
				ds_stall_count++;
				rdreq <= ~ds_stall;
			end
			else begin
				ds_stall <= 1'b0;
				rdreq <= 1'b1;
			end

			if(!us_stall) begin // can send new data
				us_valid <= 1'b1;
				us_side_data <= ($random % SIDE_W);
				us_unstall_data_in <= ($random % UNSTALL_W);
			end
			else begin
				$display("stalling...");
				us_stall_count++;
				us_valid <= 1'b1; // hold the current data
			end
			@(posedge clk);
			if(rdreq)
				i++;
			$display("us_stall: %b us_valid: %b {us_side_data, us_unstall_data_in}: %h", us_stall, us_valid, {us_side_data, us_unstall_data_in});
			us_valid <= 1'b0; // only takes effect when leaving
		end

		$monitor("empty: %b",empty);

		while(i < num_writes) begin
			if(watchdog < 0) begin
				$display("WATCHDOG");
				$display("i: %d",i);
				break;
			end
			@(posedge clk); // at posedge clk, do first iteration
			if(rdreq)
				i++;
			while(!empty) begin
				if(empty) begin
					rdreq <= 1'b0;
					break;
				end
				else begin
					rdreq <= 1'b1;
				end
				@(posedge clk); // at posedge clk, do next iteration
				if(rdreq)
					i++;
				$display("ds_datin: %h", ds_data);
			end
			watchdog--;
		end

		$display("us_stall_count: %d",us_stall_count);
		$display("ds_stall_count: %d",ds_stall_count);

		repeat(100) @(posedge clk);
		$finish;
	end

	pipe_valid_stall #(.WIDTH(UNSTALL_W), .DEPTH(DEPTH)) unstall_pipe(
		.clk, .rst,
		.us_valid(us_valid),
		.us_data(us_unstall_data_in),
		.us_stall(),
		.ds_valid(),
		.ds_data(us_unstall_data),
		.ds_stall(ds_stall),
		.num_in_fifo()
	);

	lshape #(.SIDE_W(SIDE_W), .UNSTALL_W(UNSTALL_W), .DEPTH(DEPTH)) l(.*);

endmodule
