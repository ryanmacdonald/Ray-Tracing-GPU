`default_nettype none
// uncomment the following line when synthesizing to board
// `define SYNTH

`define FP_1 32'h3F80_0000
`define FP_0 32'h0

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
  float_t x;
  float_t y;
  float_t z;

} vector_t;

typedef struct packed {
  logic [19:0] ID;
} triID_t;

 // maximum of 512 rays at a time in the pipeline TODO ?? 
typedef struct packed {
  logic [8:0] ID;
} rayID_t;

typedef struct packed {
  logic [18:0] ID;
} nodeID_t;

typedef struct packed {
  rayID_t rayID;
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
  rayID_t rayID;
} pixel_buffer_entry_t;

typedef struct packed {
  float_t u;
  float_t v;
} bari_uv_t;

typedef struct packed {
  triID_t triID;
  float_t t_int; // time intersection
  bari_uv_t uv; // uv of baricentric coordinates

} intersection_t;


typedef struct packed {
  float_t m11;
  float_t m12;
  float_t m13;
  float_t m21;
  float_t m22;
  float_t m23;
  float_t m31;
  float_t m32;
  float_t m33;

} m3x3_t;

typedef struct packed {
  m3x3_t matrix;
  vector_t translate;

} int_cacheline_t;

typedef struct packed {
  logic tri1_valid;
  float_t t_max;
  triID_t tri0_ID;
  triID_t tri1_ID;
  rayID_t rayID;
} int_pipe1_t;


typedef struct packed {
  float_t t_int0;
  float_t t_int1;
  logic t_sel; // triangle value that has smaller tint
  logic t_val0;
  logic t_val1;
  triID_t tri0_ID;
  triID_t tri1_ID;
  rayID_t rayID;
} int_pipe2_t;


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
  logic [1:0] node_type;
  triID_t tri0_ID;
  triID_t tri1_ID;
  logic tri1_valid;
  logic [4:0] reserve0;

} leaf_node_t;

typedef struct packed {
  logic [1:0] node_type;
  float24_t split;
  nodeID_t right_ID;
  logic left_empty;
  logic right_empty;
  logic SAH_flip; 

} norm_node_t;

/*
typedef struct packed {
  ray_vec_t ray_vec;
  float_t tMax;
  float_t tMin;

} raystore_t;


typedef struct packed {
  int_cacheline_t tri0_cacheline;
  int_cacheline_t tri1_cacheline;
  float_t t_max;
  triID_t tri0_ID;
  triID_t tri1_ID;
  logic tri1_valid;
  ray_vec_t ray_vec;

} raystore_to_int_t;
*/
// ss == shortstack
// rs = raystore
// sint = scene intersecter

/* shade_to_sint_t 
typedef struct packed {

} shade_to_sint_t;
*/

// sint_to_rs_t   (This will write ray_vec to raystore
typedef struct packed {
  rayID_t rayID;
  ray_vec_t ray_vec;
  float_t t_max_scene;
} sint_to_rs_t ;


// tarb_t // Traversal Arbiter
typedef struct packed {
  rayID_t rayID;
  nodeID_t nodeID;
  logic restnode_search; // set if still have not found restart node
  float_t t_max;
  float_t t_min;
} tarb_t ;


// tcache_to_trav_t
typedef struct packed {
  rayID_t rayID;
  nodeID_t nodeID;
  logic restnode_search;
  float_t t_max;
  float_t t_min;
  union packed {
    leaf_node_t leaf_node;
    norm_node_t norm_node;
  } tree_node;

} tcache_to_trav_t ;


// trav_to_rs_t
typedef struct packed {
  rayID_t rayID;
  nodeID_t nodeID;
  norm_node_t node;
  logic restnode_search;
  float_t t_max;
  float_t t_min;

} trav_to_rs_t ;


// rs_to_trav_t  // DO not need to get the scene max since intersection path has got it covered
typedef struct packed {
  rayID_t rayID;
  nodeID_t nodeID;
  norm_node_t node;
  logic restnode_search;
  float_t t_max;
  float_t t_min;
  ray_vec_t ray_vec;
} rs_to_trav_t ;


// trav_to_ss_t   (This sends either a push request or an update request)
typedef struct packed {
  rayID_t rayID;
  logic push_req; // 1 == push, 0 == update restnode
  nodeID_t push_node;
  logic update_restnode_req;
  nodeID_t rest_node;
  float_t t_max;
  float_t t_min;
} trav_to_ss_t ;


// iarb_t
typedef struct packed {
  rayID_t rayID;
  float_t t_max;
  triID_t tri0_ID;
  triID_t tri1_ID;
  logic tri1_valid;

} iarb_t ;


// rs_to_icache_t
typedef struct packed {
  rayID_t rayID;
  float_t t_max;
  triID_t tri0_ID;
  triID_t tri1_ID;
  logic tri1_valid;
  logic last_leaf;  // Determine if last leaf by comparing t_max_scene to t_max
  ray_vec_t ray_vec;

} rs_to_icache_t ;


// icache_to_int_t
typedef struct packed {
  rayID_t rayID;
  float_t t_max;
  triID_t tri0_ID;
  triID_t tri1_ID;
  logic tri1_valid;
  logic last_leaf;
  ray_vec_t ray_vec;
  int_cacheline_t tri0_cacheline;
  int_cacheline_t tri1_cacheline;

} icache_to_int_t ;


// int_to_ss_t
typedef struct packed {
  rayID_t rayID;
  logic req; // 1 = clear, 0 = miss (pop)

} int_to_ss_t ;


// int_to_shade_t
typedef struct packed {
  rayID_t rayID;

} int_to_shade_t ;




