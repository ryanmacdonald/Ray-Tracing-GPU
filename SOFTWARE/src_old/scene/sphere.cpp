/**
 * @file sphere.cpp
 * @brief Function defnitions for the Sphere class.
 *
 * @author Kristin Siu (kasiu)
 * @author Eric Butler (edbutler)
 */

#include "scene/sphere.hpp"
#include "application/opengl.hpp"

namespace _462 {

#define SPHERE_NUM_LAT 80
#define SPHERE_NUM_LON 100

#define SPHERE_NUM_VERTICES ( ( SPHERE_NUM_LAT + 1 ) * ( SPHERE_NUM_LON + 1 ) )
#define SPHERE_NUM_INDICES ( 6 * SPHERE_NUM_LAT * SPHERE_NUM_LON )
// index of the x,y sphere where x is lat and y is lon
#define SINDEX(x,y) ((x) * (SPHERE_NUM_LON + 1) + (y))
#define VERTEX_SIZE 8
#define TCOORD_OFFSET 0
#define NORMAL_OFFSET 2
#define VERTEX_OFFSET 5

static unsigned int Indices[SPHERE_NUM_INDICES];
static float Vertices[VERTEX_SIZE * SPHERE_NUM_VERTICES];

static void init_sphere()
{
    static bool initialized = false;
    if ( initialized )
        return;

    for ( int i = 0; i <= SPHERE_NUM_LAT; i++ ) {
        for ( int j = 0; j <= SPHERE_NUM_LON; j++ ) {
            real_t lat = real_t( i ) / SPHERE_NUM_LAT;
            real_t lon = real_t( j ) / SPHERE_NUM_LON;
            float* vptr = &Vertices[VERTEX_SIZE * SINDEX(i,j)];

            vptr[TCOORD_OFFSET + 0] = lon;
            vptr[TCOORD_OFFSET + 1] = 1-lat;

            lat *= PI;
            lon *= 2 * PI;
            real_t sinlat = sin( lat );

            vptr[NORMAL_OFFSET + 0] = vptr[VERTEX_OFFSET + 0] = sinlat * sin( lon );
            vptr[NORMAL_OFFSET + 1] = vptr[VERTEX_OFFSET + 1] = cos( lat ),
            vptr[NORMAL_OFFSET + 2] = vptr[VERTEX_OFFSET + 2] = sinlat * cos( lon );
        }
    }

    for ( int i = 0; i < SPHERE_NUM_LAT; i++ ) {
        for ( int j = 0; j < SPHERE_NUM_LON; j++ ) {
            unsigned int* iptr = &Indices[6 * ( SPHERE_NUM_LON * i + j )];

            unsigned int i00 = SINDEX(i,  j  );
            unsigned int i10 = SINDEX(i+1,j  );
            unsigned int i11 = SINDEX(i+1,j+1);
            unsigned int i01 = SINDEX(i,  j+1);

            iptr[0] = i00;
            iptr[1] = i10;
            iptr[2] = i11;
            iptr[3] = i11;
            iptr[4] = i01;
            iptr[5] = i00;
        }
    }

    initialized = true;
}

Sphere::Sphere()
    : radius(0), material(0) {    calculated_matrices = false; }

Sphere::~Sphere() {}

void Sphere::render() const
{
    // create geometry if we haven't already
    init_sphere();

    if ( material )
        material->set_gl_state();

    // just scale by radius and draw unit sphere
    glPushMatrix();
    glScaled( radius, radius, radius );
    glInterleavedArrays( GL_T2F_N3F_V3F, VERTEX_SIZE * sizeof Vertices[0], Vertices );
    glDrawElements( GL_TRIANGLES, SPHERE_NUM_INDICES, GL_UNSIGNED_INT, Indices );
    glPopMatrix();

    if ( material )
        material->reset_gl_state();
}

/* PMK
 *
 */
IntersectionData Sphere::intersection_test(Vector3 ray_position, Vector3 ray_direction)
{
    if(!calculated_matrices) // if we haven't calculated the matrices, do so now
    {
        make_transformation_matrix(&matrix, position, orientation, scale);
        make_inverse_transformation_matrix(&inverse_matrix, position, orientation, scale);
        make_normal_matrix(&normal_matrix, matrix);
        calculated_matrices = true;
    }

    // transform ray to local coordinates
    Vector3 ray_position_local = inverse_matrix.transform_point( ray_position );
    Vector3 ray_direction_local = inverse_matrix.transform_vector( ray_direction );

    Vector3 e = ray_position_local;
    Vector3 d = ray_direction_local;
    real_t R = radius;

    IntersectionData closest_intersection;
    closest_intersection.was_intersection = false; // assume no collision until we find one

    real_t disc = dot(d, e)*dot(d, e) - dot(d,d)*(dot(e,e)-R*R);
    if(disc < 0) // imaginary roots => no intersection 
        return closest_intersection; // was_intersection is currently false
    real_t t1 = (dot(-d, e) - sqrt(disc))/dot(d,d);
    real_t t2 = (dot(-d, e) + sqrt(disc))/dot(d,d);

    real_t t;
    if(t1 < 0 && t2 > 0) // we're inside the sphere (i.e. refraction)
        t = t2;          // so take the farther time (the nearer one is behind the starting point)
    else if(t1 > 0)      // we're outside 
        t = t1;          // so take the closer time
    else if(t2 < 0)      // both intersections were behind the starting point
        return closest_intersection; // was_intersection is currently false, indicating no intersection

    closest_intersection.was_intersection = true;
    closest_intersection.time = t;
    closest_intersection.ambient = material->ambient;
    closest_intersection.diffuse = material->diffuse;
    closest_intersection.specular = material->specular;
    closest_intersection.refractive_index = material->refractive_index;
    Vector3 p = ray_position_local + t * ray_direction_local;
    Vector3 normal_local = p;
    normal_local = normalize(normal_local);

    // followed instructions from Shirley text
    real_t theta = acos(p.z/R);
    real_t phi = atan2(p.y,p.x);

    if(phi < 0)
        phi += 2*PI;

    Vector2 tex_coord = Vector2(phi/(2*PI), (PI-theta)/PI);
    int tex_width, tex_height;
    material->get_texture_size(&tex_width, &tex_height);
    tex_coord.x *= tex_width;
    tex_coord.y *= tex_height;
    if(tex_width != 0 && tex_height != 0)
        closest_intersection.texture_pixel = material->get_texture_pixel((int)tex_coord.x%tex_width, (int)tex_coord.y%tex_height);
    else
        closest_intersection.texture_pixel = Color3(1.0,1.0,1.0);

    closest_intersection.normal = normal_matrix * normal_local;
    closest_intersection.normal = normalize(closest_intersection.normal);

    return closest_intersection;
}

} /* _462 */

