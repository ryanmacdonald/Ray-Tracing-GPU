/* file to hold all the structs that are contained within the shader */

typedef struct packed {
  rayID_t rayID;
  logic is_shadow;
  logic is_miss;
} shadow_or_miss_t ;

typedef struct packed {
  rayID_t rayID;
  vector_t p_int;
  vector_t normal;
  vector_t light;
} scache_to_sendshadow_t;

typedef struct packed {
  rayID_t rayID;
  triID_t triID;
  logic is_miss;
  logic is_shadow;
  logic is_last;
} triidstate_to_scache;

typedef struct packed {
  rayID_t rayID;
  vector24_t normal;
  float24_color_t f_color;
  logic is_miss;
  logic is_shadow;
  logic is_last;

} scache_to_dirpint_t;


typedef struct packed {
  rayID_t rayID;
  vector_t dir;
  vector_t p_int; 
  vector_t normal;
} dirpint_to_sendreflect_t;


typedef struct packed {
  rayID_t rayID;
  
} dirpint_to_calcdirect;



typedef struct packed{
  rayID_t rayID;
  vector_t p_int;
} sr_pvs_entry_t;



typedef struct packed {
  rayID_t rayID;

} calcdirect_to_BMstore;


typedef struct packed {
  rayID_t rayID;
  float_color_t f_color;
} raydone_t;


typedef struct packed {
  pixelID_t pixelID;
  float_color_t f_color;

} pixstore_to_cc_t;

