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

} scache_to_dirpint_t;

typedef struct packed {
  rayID_t rayID;
  vector_t dir;
  vector_t p_int; 
  vector_t normal;
} dirpint_to_sendreflect_t;

typedef struct packed{
  rayID_t rayID;
  vector_t p_int;
} sr_pvs_entry_t;



typedef struct packed {
  rayID_t rayID;

} dirpint_to_calcdirect;


typedef struct packed {
  rayID_t rayID;

} calcdirect_to_BMstore;

typedef struct packed {
  rayID_t rayID;
  
} raydone_t;

typedef struct packed {
  logic wut;
} pix_store_to_calc_final_t;
