module miss_handler
#(parameter LINE_W = 64,
            TAG_W = 3,
	        INDEX_W=4,
	        BASE_ADDR = 0
) (
	input logic clk, rst,

	// interface with memory request arbiter
    output logic [24:0]                  addr_cache_to_sdram,
    output logic [$clog2(`maxTrans)-1:0] transSize,
    output logic                         readReq,
    input  logic                         readValid_out,
    input  logic [31:0]                  readData,
    input  logic                         doneRead,

	// interface with cache
	// data from miss handler
	output logic [LINE_W-1:0] from_mh_data,
	output logic               from_mh_valid,
	input  logic               to_mh_stall,

	// data to miss handler
	input  logic [TAG_W+INDEX_W-1:0]  to_mh_addr,
	input  logic                      to_mh_valid,
	output logic                      from_mh_stall);

	localparam NUM_REQ = LINE_W/32;
	assign transSize = NUM_REQ;

	/**************** address translator ****************/

	// TODO: just concatenate the upper bits of BASE_ADDR with the address
	// NOTE: before I was subtracting 4 instead of 1 when shifting left by 3. I think this was wrong.
	logic [24:0] translated_addr;
	generate
		case(NUM_REQ)
			8: begin : addr_translator
				assign translated_addr = BASE_ADDR + {to_mh_addr[TAG_W+INDEX_W-1:0],3'b000}; end
			9: begin : addr_translator
				assign translated_addr = BASE_ADDR + {to_mh_addr[TAG_W+INDEX_W-1:0],3'b000} + to_mh_addr; end
			10: begin : addr_translator
				assign translated_addr = BASE_ADDR + {to_mh_addr[TAG_W+INDEX_W-1:0],3'b000} + {to_mh_addr[TAG_W+INDEX_W-1:0],1'b0}; end
			12: begin : addr_translator
				assign translated_addr = BASE_ADDR + {to_mh_addr[TAG_W+INDEX_W-1:0],3'b000} + {to_mh_addr[TAG_W+INDEX_W-1:0],2'b00}; end
			default: begin : addr_translator
				initial begin
					assert(1) $fatal("need NUM_REQ to be one of the options in addr_translator case statement");
				end
			end
		endcase
	endgenerate

	/**************** address register ****************/

	logic [24:0] next_addr;
	logic ld_addr_reg, ld_data_inc_addr;
	always_comb begin
		casex({ld_addr_reg,ld_data_inc_addr})
			2'b00: next_addr = addr_cache_to_sdram;
			2'b1?: next_addr = translated_addr;
			2'b01: next_addr = addr_cache_to_sdram + 1'b1;
		endcase
	end
	ff_ar #(.W(25)) addr_reg(.clk, .rst, .q(addr_cache_to_sdram), .d(next_addr));

	/**************** address counter ****************/

	logic clr_addr_cnt;
	logic [$clog2(NUM_REQ)-1:0] addr_cnt, next_addr_cnt;
	always_comb begin
		casex({ld_data_inc_addr,clr_addr_cnt})
			2'b00: next_addr_cnt = addr_cnt;
			2'b?1: next_addr_cnt = 'b0;
			2'b10: next_addr_cnt = addr_cnt + 1'b1;
		endcase
	end
	ff_ar #(.W($clog2(NUM_REQ))) addr_counter(.q(addr_cnt), .d(next_addr_cnt), .clk, .rst);

	/**************** data register ****************/

	logic [0:NUM_REQ-1][31:0] next_from_mh_data;
	always_comb begin
		next_from_mh_data = from_mh_data;
		if(ld_data_inc_addr)
			next_from_mh_data[addr_cnt] = readData;
	end
	ff_ar #(.W(LINE_W)) data_reg(.clk, .rst, .q(from_mh_data), .d(next_from_mh_data));

	/**************** state machine ****************/

	enum logic [1:0] {A, B, C, D} cs, ns;

	always_comb begin
		unique case(cs)
			A: ns = to_mh_valid ? B : A;
			B: ns = C;
			C: ns = doneRead ? (to_mh_stall ? D : A) : C;
			D: ns = to_mh_stall ? D : A;
			default: ns = A;
		endcase
	end

	always_ff @(posedge clk, posedge rst) begin
		if(rst) cs <= A;
		else    cs <= ns;
	end

	assign ld_addr_reg = (cs == A) && (to_mh_valid);
	assign ld_data_inc_addr = (cs == C) && (readValid_out);
	assign readReq = (cs == B) || (cs == C);
	assign clr_addr_cnt = (cs == B);
	assign from_mh_valid = doneRead || (cs == D);
	assign from_mh_stall = ~(from_mh_valid & ~ to_mh_stall);

endmodule
