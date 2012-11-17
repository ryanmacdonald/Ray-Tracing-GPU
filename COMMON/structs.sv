`default_nettype none
// uncomment the following line when synthesizing to board
// `define SYNTH

`ifdef SYNTH
	`define DC 'h0
`else
	`define DC 'hx
`endif

`define FP_1 32'h3F80_0000
`define FP_0 32'h0

// Number of caches and max read size for memory interface
`define numcaches 4
`define maxTrans 64

// Number of primary rays for PRG
`define num_rays 307200

// Epsilon = 10^-20 for now?
`define EPSILON 32'h1E3C_E508

////////////////////// Defines for XMODEM //////////////////////
`define CLK_FREQ        50000000
//`define BAUD_RATE       115200
`ifdef SYNTH
    `define XM_CYC_PER_BIT     9'd434 // TODO: define in terms of CLK_FREQ and BAUD
`else
    `define XM_CYC_PER_BIT     9'd30 // TODO: define in terms of CLK_FREQ and BAUD
`endif

`define XM_NUM_SAMPLES     4'd10

`define XM_MAX_RETRY       4'd10
`define XM_NUM_CYC_TIMEOUT (10*`CLK_FREQ)

`define SOH 8'h01
`define EOT 8'h04

`define ACK 8'h06
`define NAK 8'h15
////////////////////// End of Defines for XMODEM //////////////////////


////////////////////// Defines for VGA //////////////////////
`ifdef SYNTH
	`define VGA_NUM_ROWS        10'd480
	`define VGA_NUM_COLS        10'd640
`else // use a very low resolution in simulation
	`define VGA_NUM_ROWS        10'd9
	`define VGA_NUM_COLS        10'd12
`endif

// following in terms of 25 MHz clock
`define VGA_HS_TDISP        `VGA_NUM_COLS
`define VGA_HS_TPW          10'd96
`define VGA_HS_TFP          10'd16
`define VGA_HS_TBP          10'd48
`define VGA_HS_OFFSET      (`VGA_HS_TPW + `VGA_HS_TBP)
`define VGA_HS_TS           (`VGA_HS_OFFSET+`VGA_HS_TDISP+`VGA_HS_TFP)

// following in terms of lines
`define VGA_VS_TDISP        `VGA_NUM_ROWS
`define VGA_VS_TPW          10'd2
`define VGA_VS_TFP          10'd10
`define VGA_VS_TBP          10'd29
`define VGA_VS_OFFSET      (`VGA_VS_TPW + `VGA_VS_TBP)
`define VGA_VS_TS           (`VGA_VS_OFFSET+`VGA_VS_TDISP+`VGA_VS_TFP)

`define VGA_CYC25_PER_SCREEN  1*(`VGA_VS_TS * `VGA_HS_TS) // 1* to cast as 32 bit integer
////////////////////// End of Defines for VGA //////////////////////

typedef struct packed {
  logic sign;
  logic [7:0] exp;
  logic [22:0] man;
} float_t;

typedef struct packed {
  logic sign;
  logic [7:0] exp;
  logic [14:0] man;
} float24_t;

typedef struct packed {
  logic sign;
  logic [7:0] exp;
  logic [18:0] man;
} float28_t;

typedef struct packed {
  float_t x;
  float_t y;
  float_t z;

} vector_t;

typedef struct packed {
  float24_t x;
  float24_t y;
  float24_t z;

} vector24_t;

typedef struct packed {
  logic [15:0] ID;
} triID_t;

typedef struct packed {
  logic [8:0] ID;
} rayID_t;


typedef struct packed {
  logic is_shadow;
  logic [1:0] ss_wptr;
  logic [2:0] ss_num;
  rayID_t rayID;
} ray_info_t;

typedef struct packed {
  logic [15:0] ID;
} nodeID_t;

typedef struct packed{
  logic[18:0] pixelID;
} pixelID_t;

typedef struct packed{
  pixelID_t pixelID;
  vector_t origin;
  vector_t dir;
} prg_ray_t;

typedef struct packed {
  ray_info_t ray_info;
  vector_t origin;
  vector_t dir;
} ray_t;

typedef struct packed {
  vector_t origin;
  vector_t dir;
} ray_vec_t;

typedef struct packed {
  logic [7:0] red;
  logic [7:0] green;
  logic [7:0] blue;
} color_t ;

typedef struct packed {
  color_t color;
  pixelID_t pixelID;
} pixel_buffer_entry_t;

typedef struct packed {
  float_t u;
  float_t v;
} bari_uv_t;



typedef struct packed {
  float24_t m11;
  float24_t m12;
  float24_t m13;
  float24_t m21;
  float24_t m22;
  float24_t m23;
  float24_t m31;
  float24_t m32;
  float24_t m33;

} m3x3_t;

typedef struct packed {
  m3x3_t matrix;
  vector24_t translate;

} int_cacheline_t;

// for each key, key[0] is the press pulse and key[1] is release pulse
typedef struct packed {
  logic [1:0] q;
  logic [1:0] w;
  logic [1:0] e;
  logic [1:0] a;
  logic [1:0] s;
  logic [1:0] d;
  logic pressed;
  logic released;
} keys_t;


// type containting leaf node triangle info
typedef struct packed {
  logic [12:0] lindex; // current index
  logic [4:0] lnum_left; // number of triangles left
} ln_tri_t;


typedef struct packed {
  logic [1:0] node_type;
  ln_tri_t ln_tri;
  logic [27:0] reserve0;
  
} leaf_node_t;

typedef struct packed {
  logic [1:0] node_type;
  float28_t split; // probably needs to be 25 bits
  nodeID_t right_ID;
  logic low_empty;
  logic high_empty;
//  logic reserve;

} norm_node_t;

// sint_to_rs_t   (This will write ray_vec to raystore
typedef struct packed { // TODO make it go to both ss and rs
  ray_info_t ray_info;
  ray_vec_t ray_vec;
  float_t t_max_scene;
} sint_to_rs_t ;


// tarb_t // Traversal Arbiter
typedef struct packed {
  ray_info_t ray_info;
  nodeID_t nodeID;
  logic restnode_search; // set if still have not found restart node
  float_t t_max;
  float_t t_min;
} tarb_t ;


// tcache_to_trav_t
typedef struct packed {
  ray_info_t ray_info;
  nodeID_t nodeID;
  logic restnode_search;
  float_t t_max;
  float_t t_min;
  norm_node_t tree_node; // cant have a damn struct bitch altera

} tcache_to_trav_t ;


// trav_to_rs_t
typedef struct packed {
  ray_info_t ray_info;
  nodeID_t nodeID;
  norm_node_t node;
  logic restnode_search;
  float_t t_max;
  float_t t_min;

} trav_to_rs_t ;


// rs_to_trav_t  // DO not need to get the scene max since intersection path has got it covered
typedef struct packed {
  ray_info_t ray_info;
  nodeID_t nodeID;
  norm_node_t node;
  logic restnode_search;
  float_t t_max;
  float_t t_min;
  float_t origin;
  float_t dir;
} rs_to_trav_t ;


// trav_to_ss_t   (This sends either a push request or an update request)
typedef struct packed {
  ray_info_t ray_info;
  logic push_req; // 1 == push, 0 == update restnode
  nodeID_t push_node_ID;
  logic update_restnode_req;
  nodeID_t rest_node_ID;
  float_t t_max;
  logic pop_req;
} trav_to_ss_t ;

typedef struct packed {
  rayID_t rayID;
  float_t t_max_leaf;
} trav_to_list_t ;


// Used on the following interfacese
  // trav -> larb
  // larb -> mailbox
  // mailbox -> larb
  // mailbox -> lcache
  // int -> larb

typedef struct packed {
  ray_info_t ray_info;
 // float_t t_max_leaf;
  ln_tri_t ln_tri;
} leaf_info_t;

    
// lcache_to_rs
typedef struct packed {
  ray_info_t ray_info;
//  float_t t_max_leaf;
  ln_tri_t ln_tri;
  triID_t triID;
} lcache_to_rs_t;


// rs_to_icache_t
typedef struct packed {
  ray_info_t ray_info;
//  float_t t_max_leaf;
  ln_tri_t ln_tri;
  triID_t triID;
  ray_vec_t ray_vec;

} rs_to_icache_t ;


// icache_to_int_t
typedef struct packed {
  ray_info_t ray_info;
//  float_t t_max_leaf;
  ln_tri_t ln_tri;
  triID_t triID;
  ray_vec_t ray_vec;
  int_cacheline_t tri_cacheline;

} icache_to_int_t ;

typedef struct packed {
    ray_vec_t ray_vec;
} pcalc_to_rs_t;


// int_to_list_t
typedef struct packed {
  ray_info_t ray_info;
  triID_t triID;
  logic hit;
  logic is_last;
  float_t t_int;
  bari_uv_t uv;

} int_to_list_t ;

typedef struct packed {
  rayID_t rayID;
  bari_uv_t uv;
  float_t t_int;
  triID_t triID;
} list_to_rs_t;

typedef struct packed {
	ray_info_t ray_info;
  float_t t_max_leaf;
} list_to_ss_t;

// Represents misses
typedef struct packed {
	rayID_t rayID;
  logic is_shadow;
} ss_to_shader_t;

typedef struct packed {
    rayID_t rayID;
    ray_vec_t ray_vec;
} rs_to_pcalc_t;

/*
// int_to_mailbox // sends to mailbox if triangle was greater than t_max_leaf
typedef struct packed {
  ray_info_t ray_info;
  triID_t triID;

} int_to_mailbox;
*/


