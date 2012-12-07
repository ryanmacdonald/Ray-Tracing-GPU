`default_nettype none

`ifndef FUCKING_STRUCTS
`define FUCKING_STRUCTS

typedef struct packed {
  logic sign;
  logic [7:0] exp;
  logic [22:0] man;
} float_t;

typedef struct packed {
  logic sign;
  logic [7:0] exp;
  logic [14:0] man;
} float16_t;

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


`ifndef SINT_DEMO
typedef struct packed {
  logic [8:0] ID;
} rayID_t;
`else
typedef struct packed {
  logic[18:0] ID;
} rayID_t;
`endif

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
  logic [4:0] red;
  logic [5:0] green;
  logic [4:0] blue;
} color_t;

typedef struct packed {
  float_t red;
  float_t green;
  float_t blue;
} float_color_t;

typedef struct packed {
  float24_t red;
  float24_t green;
  float24_t blue;
} float24_color_t;

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
  logic [1:0] u;
  logic [1:0] j;
  logic [1:0] i;
  logic [1:0] k;
  logic [1:0] o;
  logic [1:0] l;

  logic [1:0] n1;
  logic [1:0] n2;
  logic [1:0] n3;
  logic [1:0] n4;
  logic [1:0] n5;
  logic [1:0] n6;

  logic [1:0] n7;
  logic [1:0] n8;
  logic [1:0] n9;
  logic [1:0] n0;

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
  float28_t split;
  nodeID_t right_ID;
  logic low_empty;
  logic high_empty;

} norm_node_t;

typedef struct packed {
  rayID_t rayID;
  vector24_t normal;
  float24_color_t f_color;

  float16_t spec;
  
  vector_t p_int;

  logic is_miss;
  logic is_shadow;
  logic is_last;

} shader_to_scache_t;

typedef struct packed {
  rayID_t rayID;
  
  vector_t p_int;

  logic is_miss;
  logic is_shadow;
  logic is_last;

} scache_to_shader_t;


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
	logic is_shadow;
	rayID_t rayID;
} sint_pvs_entry_t;


typedef struct packed{
  rayID_t rayID;
  float_t tmin;
  float_t tmax;
  logic is_shadow;
  logic miss;
} sint_entry_t;

typedef struct packed{
  rayID_t rayID;
  logic is_shadow;
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

typedef struct packed {
  rayID_t rayID;
  vector_t p_int;
  vector_t dir;
  triID_t triID;
} pcalc_to_shader_t;

/*
// int_to_mailbox // sends to mailbox if triangle was greater than t_max_leaf
typedef struct packed {
  ray_info_t ray_info;
  triID_t triID;

} int_to_mailbox;
*/

`endif
