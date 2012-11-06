//`define SYNTH

`ifdef SYNTH
	`define DC 1'b0
`else
	`define DC 1'bx
`endif

typedef struct packed {
	float_t origin;
	float_t dir;
} single_axis_origin_dir_t;

typedef struct packed {
	trav_to_rs_t trav_to_rs;
	logic data_sel;
} rs_arb_to_trav_pipe_t;

typedef struct packed {
	lcache_to_rs_t lcache_to_rs;
	logic data_sel;
} rs_arb_to_lcache_pipe_t;

typedef struct packed {
	list_to_rs_t list_to_rs;
	logic data_sel;
} rs_arb_to_list_pipe_t;

module raystore(

	// upstream interface

	input  trav_to_rs_t    trav_to_rs0,
	input  logic           trav_to_rs0_valid,
	output logic           trav_to_rs0_stall,

	input  trav_to_rs_t    trav_to_rs1,
	input  logic           trav_to_rs1_valid,
	output logic           trav_to_rs1_stall,

	input  lcache_to_rs_t  lcache_to_rs,
	input  logic           lcache_to_rs_valid,
	output logic           lcache_to_rs_stall,

	input  list_to_rs_t    list_to_rs,
	input  logic           list_to_rs_valid,
	output logic           list_to_rs_stall,

	// downstream interface

	output rs_to_trav_t    rs_to_trav0,
	output logic           rs_to_trav0_valid,
	input  logic           rs_to_trav0_stall,

	output rs_to_trav_t    rs_to_trav1,
	output logic           rs_to_trav1_valid,
	input  logic           rs_to_trav1_stall,

	output rs_to_icache_t  rs_to_icache,
	output logic           rs_to_icache_valid,
	input  logic           rs_to_icache_stall,

	output rs_to_pcalc_t   rs_to_pcalc,
	output logic           rs_to_pcalc_valid,
	input  logic           rs_to_pcalc_stall,

	input logic raystore_we,
	input logic [8:0] raystore_write_addr,
	input ray_vec_t raystore_write_data,

	input logic clk, rst
);

	ray_vec_t rd_data0, rd_data1;

	logic [1:0] rrp;
	counter #(.W(2), .RV(2'b00)) round_robin_pointer(.cnt(rrp), .clr(1'b0), .inc(1'b1), .clk, .rst);

	logic [3:0] data_sel; // go to the pipes to be augmented with their data
	logic [3:0] us_pipe_stalls, us_pipe_valids, ds_pipe_valids;
	logic [1:0] mux_sel0, mux_sel1;

	raystore_arb rsa(
		.us_valid({list_to_rs_valid, lcache_to_rs_valid, trav_to_rs1_valid, trav_to_rs0_valid}),
		.us_stall({list_to_rs_stall, lcache_to_rs_stall, trav_to_rs1_stall, trav_to_rs0_stall}),
		.pipe_stall(us_pipe_stalls),
		.pipe_valid(us_pipe_valids),
		.data_sel,
		.mux_sel0,
		.mux_sel1,
		.raystore_we,
		.rrp
	);

	// PIPE/FIFO 00000000

	logic [1:0] nif0;

	rs_arb_to_trav_pipe_t pvs0_data_in;
	assign pvs0_data_in.trav_to_rs = trav_to_rs0;
	assign pvs0_data_in.data_sel = data_sel[0];

	rs_arb_to_trav_pipe_t pvs0_data_out;

	pipe_valid_stall
	#(.WIDTH($bits(rs_arb_to_trav_pipe_t)), .DEPTH(2))
	pvs0(
		.clk, .rst,

		.us_valid(us_pipe_valids[0]),
		.us_data(pvs0_data_in),
		.us_stall(us_pipe_stalls[0]),

		.ds_valid(ds_pipe_valids[0]),
		.ds_data(pvs0_data_out),
		.ds_stall(rs_to_trav0_stall),

		.num_in_fifo(nif0)
	);

	logic [1:0] nt0;
	assign nt0 = pvs0_data_out.trav_to_rs.node.node_type;

	single_axis_origin_dir_t f0_data_in0, f0_data_in1;

	always_comb begin
		case(nt0)
			2'b00: begin
				f0_data_in0.origin = rd_data0.origin.x;
				f0_data_in0.dir = rd_data0.dir.x;
				f0_data_in1.origin = rd_data1.origin.x;
				f0_data_in1.dir = rd_data1.dir.x;
			end
			2'b01: begin
				f0_data_in0.origin = rd_data0.origin.y;
				f0_data_in0.dir = rd_data0.dir.y;
				f0_data_in1.origin = rd_data1.origin.y;
				f0_data_in1.dir = rd_data1.dir.y;
			end
			2'b10: begin
				f0_data_in0.origin = rd_data0.origin.z;
				f0_data_in0.dir = rd_data0.dir.z;
				f0_data_in1.origin = rd_data1.origin.z;
				f0_data_in1.dir = rd_data1.dir.z;
			end
		endcase
	end

	rs_to_trav_t f0_data_in;

	assign f0_data_in.ray_info = pvs0_data_out.trav_to_rs.ray_info;
	assign f0_data_in.nodeID = pvs0_data_out.trav_to_rs.nodeID;
	assign f0_data_in.node = pvs0_data_out.trav_to_rs.node;
	assign f0_data_in.restnode_search = pvs0_data_out.trav_to_rs.restnode_search;
	assign f0_data_in.t_max = pvs0_data_out.trav_to_rs.t_max;
	assign f0_data_in.t_min = pvs0_data_out.trav_to_rs.t_min;

	assign f0_data_in.origin = (pvs0_data_out.data_sel) ? f0_data_in1.origin : f0_data_in0.origin;
	assign f0_data_in.dir = (pvs0_data_out.data_sel) ? f0_data_in1.dir : f0_data_in0.dir;

	logic f0_empty, f0_re;
	assign rs_to_trav0_valid = ~f0_empty;
	assign f0_re = ~rs_to_trav0_stall & ~f0_empty;

	fifo
	#(.WIDTH($bits(rs_to_trav_t)), .K(1))
	f0(
		.clk, .rst,
		.data_in(f0_data_in),
		.we(ds_pipe_valids[0]),
		.re(f0_re),
		.full(), // not used
		.empty(f0_empty),
		.data_out(rs_to_trav0),
		.num_in_fifo(nif0)
	);
	// PIPE/FIFO 00000000

	// PIPE/FIFO 11111111

	logic [1:0] nif1;

	rs_arb_to_trav_pipe_t pvs1_data_in;
	assign pvs1_data_in.trav_to_rs = trav_to_rs1;
	assign pvs1_data_in.data_sel = data_sel[1];

	rs_arb_to_trav_pipe_t pvs1_data_out;

	pipe_valid_stall
	#(.WIDTH($bits(rs_arb_to_trav_pipe_t)), .DEPTH(2))
	pvs1(
		.clk, .rst,

		.us_valid(us_pipe_valids[1]),
		.us_data(pvs1_data_in),
		.us_stall(us_pipe_stalls[1]),

		.ds_valid(ds_pipe_valids[1]),
		.ds_data(pvs1_data_out),
		.ds_stall(rs_to_trav1_stall),

		.num_in_fifo(nif1)
	);

	logic [1:0] nt1;
	assign nt1 = pvs1_data_out.trav_to_rs.node.node_type;

	single_axis_origin_dir_t f1_data_in0, f1_data_in1;

	always_comb begin
		case(nt1)
			2'b00: begin
				f1_data_in0.origin = rd_data0.origin.x;
				f1_data_in0.dir = rd_data0.dir.x;
				f1_data_in1.origin = rd_data1.origin.x;
				f1_data_in1.dir = rd_data1.dir.x;
			end
			2'b01: begin
				f1_data_in0.origin = rd_data0.origin.y;
				f1_data_in0.dir = rd_data0.dir.y;
				f1_data_in1.origin = rd_data1.origin.y;
				f1_data_in1.dir = rd_data1.dir.y;
			end
			2'b10: begin
				f1_data_in0.origin = rd_data0.origin.z;
				f1_data_in0.dir = rd_data0.dir.z;
				f1_data_in1.origin = rd_data1.origin.z;
				f1_data_in1.dir = rd_data1.dir.z;
			end
		endcase
	end

	rs_to_trav_t f1_data_in;

	assign f1_data_in.ray_info = pvs1_data_out.trav_to_rs.ray_info;
	assign f1_data_in.nodeID = pvs1_data_out.trav_to_rs.nodeID;
	assign f1_data_in.node = pvs1_data_out.trav_to_rs.node;
	assign f1_data_in.restnode_search = pvs1_data_out.trav_to_rs.restnode_search;
	assign f1_data_in.t_max = pvs1_data_out.trav_to_rs.t_max;
	assign f1_data_in.t_min = pvs1_data_out.trav_to_rs.t_min;

	assign f1_data_in.origin = (pvs1_data_out.data_sel) ? f1_data_in1.origin : f1_data_in0.origin;
	assign f1_data_in.dir = (pvs1_data_out.data_sel) ? f1_data_in1.dir : f1_data_in0.dir;

	logic f1_empty, f1_re;
	assign rs_to_trav1_valid = ~f1_empty;
	assign f1_re = ~rs_to_trav1_stall & ~f1_empty;

	fifo
	#(.WIDTH($bits(rs_to_trav_t)), .K(1))
	f1(
		.clk, .rst,
		.data_in(f1_data_in),
		.we(ds_pipe_valids[1]),
		.re(f1_re),
		.full(), // not used
		.empty(f1_empty),
		.data_out(rs_to_trav1),
		.num_in_fifo(nif1)
	);

	// PIPE/FIFO 11111111

	// PIPE/FIFO 22222222

	logic [1:0] nif2;

	rs_arb_to_lcache_pipe_t pvs2_data_in;
	assign pvs2_data_in.lcache_to_rs = lcache_to_rs;
	assign pvs2_data_in.data_sel = data_sel[2];

	rs_arb_to_lcache_pipe_t pvs2_data_out;

	pipe_valid_stall
	#(.WIDTH($bits(rs_arb_to_lcache_pipe_t)), .DEPTH(2))
	pvs2(
		.clk, .rst,

		.us_valid(us_pipe_valids[2]),
		.us_data(pvs2_data_in),
		.us_stall(us_pipe_stalls[2]),

		.ds_valid(ds_pipe_valids[2]),
		.ds_data(pvs2_data_out),
		.ds_stall(rs_to_icache_stall),

		.num_in_fifo(nif2)
	);

	rs_to_icache_t f2_data_in;

	assign f2_data_in.ray_info  = pvs2_data_out.lcache_to_rs.ray_info;
	assign f2_data_in.ln_tri = pvs2_data_out.lcache_to_rs.ln_tri;
	assign f2_data_in.triID  = pvs2_data_out.lcache_to_rs.triID;

	assign f2_data_in.ray_vec = (pvs2_data_out.data_sel) ? rd_data1 : rd_data0;

	logic f2_empty, f2_re;
	assign rs_to_icache_valid = ~f2_empty;
	assign f2_re = ~rs_to_icache_stall & ~f2_empty;

	fifo
	#(.WIDTH($bits(rs_to_icache_t)), .K(1))
	f2(
		.clk, .rst,
		.data_in(f2_data_in),
		.we(ds_pipe_valids[2]),
		.re(f2_re),
		.full(), // not used
		.empty(f2_empty),
		.data_out(rs_to_icache),
		.num_in_fifo(nif2)
	);

	// PIPE/FIFO 22222222

	// PIPE/FIFO 33333333

	logic [1:0] nif3;

	rs_arb_to_list_pipe_t pvs3_data_in;
	assign pvs3_data_in.list_to_rs = list_to_rs;
	assign pvs3_data_in.data_sel = data_sel[3];

	rs_arb_to_list_pipe_t pvs3_data_out;

	pipe_valid_stall
	#(.WIDTH($bits(rs_arb_to_list_pipe_t)), .DEPTH(2))
	pvs3(
		.clk, .rst,

		.us_valid(us_pipe_valids[3]),
		.us_data(pvs3_data_in),
		.us_stall(us_pipe_stalls[3]),

		.ds_valid(ds_pipe_valids[3]),
		.ds_data(pvs3_data_out),
		.ds_stall(rs_to_pcalc_stall),

		.num_in_fifo(nif3)
	);

	rs_to_pcalc_t f3_data_in;

	assign f3_data_in.rayID  = pvs3_data_out.list_to_rs.rayID;
	// TODO: other things for list_to_rs struct...

	assign f3_data_in.ray_vec = (pvs3_data_out.data_sel) ? rd_data1 : rd_data0;

	logic f3_empty, f3_re;
	assign rs_to_pcalc_valid = ~f3_empty;
	assign f3_re = ~rs_to_pcalc_stall & ~f3_empty;

	fifo
	#(.WIDTH($bits(rs_to_pcalc_t)), .K(1))
	f3(
		.clk, .rst,
		.data_in(f3_data_in),
		.we(ds_pipe_valids[3]),
		.re(f3_re),
		.full(), // not used
		.empty(f3_empty),
		.data_out(rs_to_pcalc),
		.num_in_fifo(nif3)
	);

	// PIPE/FIFO 33333333

	// block ram addresses
	logic [8:0] addr0, addr1;

	always_comb begin
		case(mux_sel0)
			2'b00: addr0 = trav_to_rs0.ray_info.rayID;
			2'b01: addr0 = trav_to_rs1.ray_info.rayID;
			2'b10: addr0 = lcache_to_rs.ray_info.rayID;
			2'b11: addr0 = list_to_rs.rayID;
		endcase
	end

	always_comb begin
		case(mux_sel1)
			2'b00: addr1 = trav_to_rs0.ray_info.rayID;
			2'b01: addr1 = trav_to_rs1.ray_info.rayID;
			2'b10: addr1 = lcache_to_rs.ray_info.rayID;
			2'b11: addr1 = list_to_rs.rayID;
		endcase
	end

	logic [8:0] addr0_mux_out;
	assign addr0_mux_out = (raystore_we) ? raystore_write_addr : addr0;

	// ^^^^^ block ram addresses ^^^^^

	raystore_blkram rbram(
		.aclr(rst),
		.address_a(addr0_mux_out),
		.address_b(addr1),
		.clock(clk),
		.data_a(raystore_write_data),
		.data_b(),
		.wren_a(raystore_we),
		.wren_b(1'b0),
		.q_a(rd_data0),
		.q_b(rd_data1));

endmodule: raystore

module raystore_arb #(parameter N=4) (
	input logic [N-1:0] us_valid,
	output logic [N-1:0] us_stall,

	input logic [N-1:0] pipe_stall,
	output logic [N-1:0] pipe_valid,
	output logic [N-1:0] data_sel,

	output logic [1:0] mux_sel0,
	output logic [1:0] mux_sel1,

	input logic raystore_we,

	input logic [$clog2(N)-1:0] rrp
);

	logic [N-1:0] trans_valid;

	assign trans_valid = ~pipe_stall & us_valid;

	logic [N-1:0] trans_choice;

	logic [$clog2(N)-1:0] rrp1, rrp2, rrp3;
	assign rrp1 = rrp + 2'd1;
	assign rrp2 = rrp + 2'd2;
	assign rrp3 = rrp + 2'd3;

	always_comb begin
		trans_choice = 4'b0000;
		trans_choice[rrp] = trans_valid[rrp];
		trans_choice[rrp1] = trans_valid[rrp1];
		trans_choice[rrp2] = trans_valid[rrp2] & (trans_choice[rrp] + trans_choice[rrp1] < 3'd2);
		trans_choice[rrp3] = trans_valid[rrp3] & (trans_choice[rrp] + trans_choice[rrp1] + trans_choice[rrp2] < 3'd2);
	end

	assign pipe_valid = trans_choice & ~{4{raystore_we}};

	assign us_stall = (~trans_choice | {4{raystore_we}}) & us_valid;

	logic [7:0] ms;

	always_comb begin
		ms = {2'b00, 2'b00, 4'b0000};

						//  sel0  sel1    data_sel
		case(trans_choice)
			4'b0000: ms = {{2{`DC}},{2{`DC}}, {4{`DC}}};

			4'b0001: ms = {2'b00,{2{`DC}}, `DC,`DC,`DC,1'b0};
			4'b0010: ms = {2'b01,{2{`DC}}, `DC,`DC,1'b0,`DC};
			4'b0100: ms = {2'b10,{2{`DC}}, `DC,1'b0,`DC,`DC};
			4'b1000: ms = {2'b11,{2{`DC}}, 1'b0,`DC,`DC,`DC};

			4'b0011: ms = {2'b01,2'b00, `DC,`DC,1'b0,1'b1};
			4'b0101: ms = {2'b10,2'b00, `DC,1'b0,`DC,1'b1};
			4'b0110: ms = {2'b10,2'b01, `DC,1'b0,1'b1,`DC};
			4'b1001: ms = {2'b11,2'b00, 1'b0,`DC,`DC,1'b1};
			4'b1010: ms = {2'b11,2'b01, 1'b0,`DC,1'b1,`DC};
			4'b1100: ms = {2'b11,2'b10, 1'b0,1'b1,`DC,`DC};
		endcase
	end

	assign mux_sel0 = ms[7:6];
	assign mux_sel1 = ms[5:4];
	assign data_sel = ms[3:0];


endmodule: raystore_arb
