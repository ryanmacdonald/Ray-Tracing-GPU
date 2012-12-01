/* file to hold all the structs that are contained within the shader */


typedef struct packed {
  rayID_t rayID;
  logic is_shadow;
  logic is_miss;
} shadow_or_miss_t ;

typedef struct packed {
  rayID_t rayID;

} scache_to_sendshadow_t;

typedef struct packed {
  rayID_t rayID;

} scache_to_dirpint_t;

typedef struct packed {
  rayID_t rayID;
  vector_t // dir, p_int, normal

} dirpint_to_sendreflect;

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
  

} pix_store_to_calc_final_t
