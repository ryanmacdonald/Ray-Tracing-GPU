`default_nettype none
// uncomment the following line when synthesizing to board
//`define SYNTH
`ifndef FUCKING_STRUCTS
  `define FUCKING_STRUCTS

`ifdef SYNTH
	`define DC 'h0
`else
	`define DC 'hx
`endif

`define FP_2 32'h4000_0000
`define FP_1 32'h3F80_0000
`define FP_0 32'h0

// Defs for camera initialization
`ifdef SYNTH
	`define INIT_CAM_X 32'h40800000
	`define INIT_CAM_Y 32'h40400000
	`define INIT_CAM_Z 32'hC1200000
`else
	`define INIT_CAM_X $shortrealtobits(1.125)
	`define INIT_CAM_Y $shortrealtobits(1.125)
	`define INIT_CAM_Z $shortrealtobits(-1.25)
`endif


`ifndef SYNTH
	`define move_scale 32'h3F800000
`else
	`define move_scale 32'h32ABCC77 
`endif

// Number of caches and max read size for memory interface
//`define numcaches 3 // TODO: change back to 4 later
`define numcaches 4 // TODO: change back to 4 later
`define maxTrans 64

// Number of primary rays for PRG

`ifndef SYNTH
	`define PW_REAL 0.25 // TODO: make this considerably smaller
`else
	`define PW_REAL 1.0
`endif

// Pixel width
	`define PW $shortrealtobits(`PW_REAL)

// Epsilon = 10^-20 for now?
`define EPSILON 32'h1E3C_E508


////////////////////// Defines for Caches //////////////////////
// parameters for icache
`define I_ADDR_W              16
`define I_BO_W                0
`define I_TAG_W               6
`define I_INDEX_W             10
`define I_LINE_W              288
`define I_NUM_BLK             1
`define I_BLK_W               `I_LINE_W/`I_NUM_BLK
`define I_BASE_ADDR           25'h0_00_00_00
`define I_NUM_LINES           1024

// parameters for tcaches
`define T_ADDR_W              16
`define T_BO_W                3
`define T_TAG_W               4
`define T_INDEX_W             9
`define T_LINE_W              384
`define T_NUM_BLK             8
`define T_BLK_W               `T_LINE_W/`T_NUM_BLK
`define T_BASE_ADDR           25'h0_80_00_00
`define T_NUM_LINES           512

// parameters for lcache
`define L_ADDR_W              16
`define L_BO_W                4
`define L_TAG_W               2
`define L_INDEX_W             10
`define L_LINE_W              256
`define L_NUM_BLK             16
`define L_BLK_W               `L_LINE_W/`L_NUM_BLK
`define L_BASE_ADDR           25'h1_00_00_00
`define L_NUM_LINES           1024

// parameters for icache
`define S_ADDR_W              16
`define S_BO_W                1
`define S_TAG_W               5
`define S_INDEX_W             10
`define S_LINE_W              320
`define S_NUM_BLK             2
`define S_BLK_W               `S_LINE_W/`S_NUM_BLK
`define S_BASE_ADDR           25'h1_80_00_00
`define S_NUM_LINES           1024
////////////////////// End of Defines for Caches //////////////////////

////////////////////// Defines for XMODEM //////////////////////
`define CLK_FREQ        50000000
//`define BAUD_RATE       115200
`ifdef SYNTH
    `define XM_CYC_PER_BIT     9'd434 // TODO: define in terms of CLK_FREQ and BAUD
`else
    `define XM_CYC_PER_BIT     9'd20 // TODO: define in terms of CLK_FREQ and BAUD
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
	`define VGA_NUM_ROWS        10'd50
	`define VGA_NUM_COLS        10'd50

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

////////////////////// Defines for PRG //////////////////////
`define num_rays (`VGA_NUM_ROWS*`VGA_NUM_COLS*1) // 307200
// defines for -w/2 and -h/2 //half width = -4, half height = -3
`ifndef SYNTH
	`define half_screen_width  $shortrealtobits(`PW_REAL*(-(`VGA_NUM_COLS/2.0)))
	`define half_screen_height $shortrealtobits(`PW_REAL*(-(`VGA_NUM_ROWS/2.0)))
	// D = 6 for now
	`define D $shortrealtobits(`PW_REAL*(`VGA_NUM_ROWS/2.0)) // 45 degrees viewing angle
`else
	`define half_screen_width  32'hC080_0000 // -4
	`define half_screen_height 32'hC040_0000 // -3
	// D = 6 for now
	`define SCREEN_DIST 32'h4080_0000 // 4
`endif
////////////////////// End of Defines for PRG //////////////////////

////////////////////// Defines for shader /////////////////////////
`define MISS_COLOR 24'hff_ff_ff
`define TRI_0_COLOR 24'haa_aa_aa
`define TRI_2_COLOR 24'h08_cc_08
`define TRI_1_COLOR 24'h0b_0b_dd
`define TRI_3_COLOR 24'hff_01_01


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

typedef struct packed {
  float_t xmin;
  float_t xmax;
  float_t ymin;
  float_t ymax;
  float_t zmin;
  float_t zmax;
} AABB_t;


typedef struct packed{
  pixelID_t pixelID;
  vector_t origin;
  vector_t dir;
} prg_ray_t;

typedef struct packed{
  float_t tmin;
  float_t tmax;
  logic miss;
  rayID_t rayID;
  vector_t origin;
  vector_t direction;
} scene_int_ray_t;


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

typedef struct packed {
  logic [15:0] ID;
} lindex_t;

// type containting leaf node triangle info
typedef struct packed {
  lindex_t lindex; // current index
  logic [5:0] lnum_left; // number of triangles left
} ln_tri_t;


typedef struct packed {
  logic [1:0] node_type;
  ln_tri_t ln_tri;
  logic [23:0] reserve0;
  
} leaf_node_t;

typedef struct packed {
  logic [1:0] node_type;
  float28_t split; // probably needs to be 25 bits
  nodeID_t right_ID;
  logic low_empty;
  logic high_empty;
//  logic reserve;

} norm_node_t;

// TODO change this to SHADER_to_raystore
// sint_to_rs_t   (This will write ray_vec to raystore)
typedef struct packed { 
  rayID_t rayID;
  ray_vec_t ray_vec;
} sint_to_rs_t ; // DONT USE


typedef struct packed {
  rayID_t rayID;
  logic is_shadow;
  ray_vec_t ray_vec;
} shader_to_sint_t;

typedef struct packed {
	rayID_t rayID;
  float_t t_max_scene;
} sint_to_ss_t;

/*
  RYAN, sint_to_tarb is of type tarb_t.
    ray_info.ss_* = 0;
    nodeID = 0;
    restnode_search = 1;
*/

typedef struct packed{
  rayID_t rayID;
  float_t tmin;
  float_t tmax;
  logic is_shadow;
  logic miss;
} sint_entry_t;

typedef struct packed{
  rayID_t rayID;
} sint_to_shader_t;

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
  logic update_maxscene_req;
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
  ln_tri_t ln_tri;
} leaf_info_t;

    
// lcache_to_icache
typedef struct packed {
  ray_info_t ray_info;
  ln_tri_t ln_tri;
  triID_t triID;
} lcache_to_icache_t;


// icache_to_rs_t
typedef struct packed {
  ray_info_t ray_info;
  ln_tri_t ln_tri;
  triID_t triID;
  int_cacheline_t tri_cacheline;
} icache_to_rs_t ;


// rs_to_int_t
typedef struct packed {
  ray_info_t ray_info;
  ln_tri_t ln_tri;
  triID_t triID;
  ray_vec_t ray_vec;
  int_cacheline_t tri_cacheline;

} rs_to_int_t ;


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
} int_to_shader_t;


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
  bari_uv_t uv;
  float_t t_int;
  triID_t triID;
  ray_vec_t ray_vec;
} rs_to_pcalc_t;

/*
// int_to_mailbox // sends to mailbox if triangle was greater than t_max_leaf
typedef struct packed {
  ray_info_t ray_info;
  triID_t triID;

} int_to_mailbox;
*/

`endif
