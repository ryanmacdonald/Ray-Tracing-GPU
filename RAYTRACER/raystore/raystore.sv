module raystore(
	input trav_to_rs_t trav_to_rs0,
	input logic trav_to_rs0_valid,
	output logic trav_to_rs0_stall,

	input trav_to_rs_t trav_to_rs1,
	input logic trav_to_rs1_valid,
	output logic trav_to_rs1_stall,

	input lcache_to_rs_t lcache_to_rs,
	input logic lcache_to_rs_valid,
	output logic lcache_to_rs_stall,

	input pcalc_to_rs_t pcalc_to_rs,
	input logic pcalc_to_rs_valid,
	output logic pcalc_to_rs_stall,

	input logic clk, rst
);

/*	raystore_pipe rsp0 #() ();
	raystore_pipe rsp1 #() ();
	raystore_pipe rsp2 #() ();
	raystore_pipe rsp3 #() (); */

	// TODO: instantiate block ram

endmodule: raystore

module raystore_arb #(parameter N=4) (
	input logic [N-1:0] us_valid,
	output logic [N-1:0] us_stall,
	input rayID_t us_data [N-1:0],

	input logic [N-1:0] ds_stall,
	output logic [N-1:0] ds_valid,
	output logic data_sel,
	output logic [N-1:0] ds_data,

	input logic [$clog2(N)-1:0] rrp
);



endmodule: raystore_arb

/*
module raystore_pipe #(parameter WIDTH = 8) (
	input logic [WIDTH-1:0] us_data,
	input logic us_valid,
	output logic us_stall,
	input logic mux_sel, // TODO

	input logic [WIDTH-1:0] rd_data1, rd_data2,
	
	output logic [WIDTH-1:0] ds_data_out,
	output logic ds_valid,
	input logic ds_stall,
	input logic re,

	input logic clk, rst
);

	logic [$clog2(DEPTH+2)-1:0] num_in_fifo;
	logic we, re;

	logic [] pipe_data_out; // TODO: define width

	// TODO: define depth
	pipe_valid_stall #(.WIDTH, .DEPTH()) pvs(
		.clk, .rst,
		.us_valid,
		.us_data,
		.us_stall,
		.ds_valid(we),
		.ds_data(pipe_data_out),
		.ds_stall,
		.num_in_fifo);

	logic full, empty;
	logic [WIDTH-1:0] fifo_data_out;

	logic [] mux_out; // TODO: define width
	assign mux_out = {}; // TODO

	logic [WIDTH-1:0] fifo_data_in;
	assign fifo_data_in = ; // TODO: mux data1, data2

	assign ds_valid = ~empty;

	assign re = ; // TODO: define re

	fifo f(
		.clk, .rst,
		.data_in(fifo_data_in),
		.we,
		.re,
		.full,
		.empty,
		.data_out(fifo_data_out),
		.num_in_fifo);

endmodule: raystore_pipe
*/
