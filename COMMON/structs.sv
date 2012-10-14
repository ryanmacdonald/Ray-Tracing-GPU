/*Defines and struct definitions for ray tracer
Some terminology...
FP = Fixed Point Width (or floating point width)
SHADE = Shader 
TRAV = Traversal 
LNT = Leaf Node Test 
INT = Intersection test

*/
`define MAX_TRIANGLES 200000
`define TRIID_W $clog2(`MAX_TRIANGLES)

`define NUM_LIGHTS 1023
// NUM_RAYIDS = NUM_LIGHTS + 1 (reflective) + 1(refractive)
`define NUM_RAYIDS (`NUM_LIGHTS + 1)
`define RAYID_W $clog2(`NUM_RAYIDS)

`define ADDR_W 32


`define SHADE_NUM 10
`define SHADE_NUM_W $clog2(`SHADE_NUM)

`define TRAV_NUM 10

`define LNT_NUM 5

`define INT_NUM 5



typedef packed struct {
  logic [31:0] num
} FP;

// A Vector
typedef packed struct {
  FP x;
  FP y;
  FP z;
} Vector;

// A Generic Ray (might need inv direction)
typdef packed struct {
  Vector origin; // Origin of ray
  Vector dir; //Direction of ray
  logic shadow_ray; // 1 if a shadow ray, 0 if radiance ray
  logic [`LOG_SHADE_NUM-1:0] shaderID;
  logic [`LOG_NUM_RAYIDS-1:0] rayID;
} Ray;

/* SHADE -> TRAV
Ray,
ShaderID
rayID
*/
typedef packed struct {
  Ray ray;
} SHADE_to_TRAV;


/* TRAV -> LNT
Ray,
Tmax, Tmin
node Addr
*/
typedef packed struct {
  Ray ray;
  FP TMax;
  FP Tmin;
  logic [`ADDR_W-1:0] Leaf
} TRAV_to_LNT;

/* LNT -> TRAV
hit
*/
typedef packed struct {
  logic is_hit; // 1 if hit a triangle in leaf, (implies a traversal flush and free)
                // 0 if missed all triangles in leaf
} LNT_to_TRAV;


/* LNT -> INT
  Ray,
  Tmin, Tmax
  Triangle index
*/
typedef packed struct {
  Ray ray;
  FP Tmax;
  FP Tmin;
  logic [`TRIID_W-1:0] triID;
}


/* INT -> LNT
  is_hit
  Intersection intersection
*/
typedef packed struct {
  logic is_hit;
  logic [`TRIID_W:0] triID;
  FP Tintersect;
  FP bari_u;
  FP bari_v;
} INT_to_LNT;



/* LNT -> SHADE
  is_hit
  intersection2
*/
typedef packed struct {
  logic is_hit;
  logic [`TRIID_W-1:0] triID;
  Vector Pintersect;
  FP bari_u;
  FP bari_v;
}
