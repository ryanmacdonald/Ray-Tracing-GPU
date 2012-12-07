/* file to hold all the structs that are contained within the shader */

typedef struct packed{
  rayID_t rayID;
  vector_t p_int;
} sr_pvs_entry_t;


typedef struct packed {
  rayID_t rayID;
  logic is_shadow;
  logic is_miss;
} shadow_or_miss_t ;


typedef struct packed {
  rayID_t rayID;
  triID_t triID;
  logic is_miss;
  logic is_shadow;
  logic is_last;
} triidstate_to_scache;


typedef struct packed {
  rayID_t rayID;
  vector_t dir;
  vector_t p_int; 
  vector_t normal;
} dirpint_to_sendreflect_t;


typedef struct packed {
  rayID_t rayID;
  float_color_t color;
  float16_t spec; // RYAN ADD THIS
  logic is_last;

} calc_direct_to_BM_t;


typedef struct packed {
  rayID_t rayID;
  float16_t spec;
  logic is_last;
} calc_dir_pvs_entry_t;



typedef struct packed {
  rayID_t rayID;
  float_color_t K; // color of triangle
  logic is_shadow;
  logic is_miss;
  logic is_last;
  vector_t N; // Normal
  vector_t p_int;  // point of intersection
  vector_t L; // Light Position  // TODO get rid of this vector and do the L calculation within directcalc
  float16_t spec;
} dirpint_to_calc_direct_t;



typedef struct packed {
  rayID_t rayID;
  float_color_t f_color;
} raydone_t;


typedef struct packed {
  pixelID_t pixelID;
  float_color_t f_color;
} pixstore_to_cc_t;

