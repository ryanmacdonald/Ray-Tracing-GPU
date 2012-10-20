`ifndef STRUCTS_SV
`define STRUCTS_SV

`define FP_1 32'h3F80_0000
`define FP_0 32'h0

typedef struct packed {
  logic sign;
  logic [7:0] exp;
  logic [22:0] man;
} float_t;

typedef struct packed {
  float_t x;
  float_t y;
  float_t z;

} vector_t;

typedef struct packed {
  logic [19:0] ID;
} triID_t;

typedef struct packed {
  logic [7:0] ID;
} rayID_t;

typedef struct packed {
  rayID_t rayID;
  vector_t origin;
  vector_t dir;
} ray_t;

typedef struct packed {
  float_t u;
  float_t v;
} bari_uv_t;

typedef struct packed {
  triID_t triID;
  float_t t_int; // time intersection
  vector_t p_int; // Point of intersection
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
  float_t t_min;
  triID_t tri0_ID;
  triID_t tri1_ID;
  ray_t ray;
} int_pipe1_t;


typedef struct packed {
  float_t t_int;
  logic t_hit;
  logic t_sel;
  triID_t triID;
  float_t t_max;
  float_t t_min;
  ray_t ray;
} int_pipe2_t;




`endif