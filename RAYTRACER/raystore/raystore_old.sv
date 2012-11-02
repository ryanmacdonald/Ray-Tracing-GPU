
module raystore(
	output rs_to_trav_t rstt1,
	output logic rstt1_valid,
	input logic rstt1_stall,

	output rs_to_trav_t rstt2,
	output logic rstt2_valid,
	input logic rstt2_stall,

	output rs_to_icache_t rstic,
	output logic rstic_valid,
	input logic rstic_stall,

	input trav_to_rs_t ttrs1,
	input logic ttrs1_re,
	output logic ttrs1_stall,

	input trav_to_rs_t ttrs2,
	input logic ttrs2_re,
	output logic ttrs2_stall,

	input lcache_to_rs_t lctrs,
	input logic lctrs_re,
	output logic lctrs_stall,

	input logic clk, rst
);

	logic [2:0] rr;
	shifter #(.W(3), .RV(3'b110)) rr_sr(.q(rr), .d(rr[0]), .en(1'b1), .clr(1'b0), .clk, .rst);

	logic [2:0] ABC_out, ABC_out1, ABC_out2, ABC_in;
	assign ABC_in = {ttrs1_re, ttrs2_re, lctrs_re};

	always_comb begin
		ttrs1_stall = 1'b0;
		ttrs2_stall = 1'b0;
		lctrs_stall = 1'b0;
		ABC_out = ABC_in;
		if(ABC_in == 3'b111) begin
			ABC_out = rr;
			ttrs1_stall = ~ABC_out[0];
			ttrs2_stall = ~ABC_out[1];
			lctrs_stall = ~ABC_out[2];
		end
	end

	ff_ar #(3, 3'b000) ABC_out_reg1(.q(ABC_out1), .d(ABC_out), .clk, .rst);
	ff_ar #(3, 3'b000) ABC_out_reg2(.q(ABC_out2), .d(ABC_out1), .clk, .rst);

	logic blkram_re1, blkram_re2;

	assign blkram_re1 = |ABC_out;
	assign blkram_re2 = (ABC_out == 3'b011 || ABC_out == 3'b110 || ABC_out == 3'b101);

	rayID_t A_addr, B_addr, C_addr;
	assign A_addr = ttrs1.rayID;
	assign B_addr = ttrs2.rayID;
	assign C_addr = lctrs.rayID;

	logic [$bits(rayID_t)-1:0] blkram_addr1, blkram_addr2;

	assign blkram_addr1 = (ABC_out[1]) ? B_addr : A_addr;
	assign blkram_addr2 = (ABC_out[2]) ? C_addr : B_addr;

	logic [$bits(ray_vec_t)-1:0] blkq1, blkq2;

	assign blkq1 = 'b0;
	assign blkq2 = 'b0;

	assign rstt1.ray_vec = blkq1;
	assign rstt2.ray_vec = (ABC_out2[1]) ? blkq2 : blkq1;
	assign rstic.ray_vec = blkq2;

	assign {rstt1_valid, rstt2_valid, rstic_valid} = ABC_out2;

	// TODO: instantiate block ram
	// inputs to block ram:
	// * blkram_addr1
	// * blkram_addr2
	// * blkram_re1
	// * blkram_re2
	// outputs of block ram:
	// * blkq1
	// * blkq2
	raystore_blkram (
		aclr,
		address_a,
		address_b,
		clock,
		data_a,
		data_b,
		wren_a,
		wren_b,
		q_a,
		q_b);


endmodule: raystore
