/**
 * @file triangle.cpp
 * @brief Function definitions for the Triangle class.
 *
 * @author Eric Butler (edbutler)
 */

#include "scene/triangle.hpp"
#include "application/opengl.hpp"

namespace _462 {

Triangle::Triangle()
{
    vertices[0].material = 0;
    vertices[1].material = 0;
    vertices[2].material = 0;
    calculated_matrices = false;
}

Triangle::~Triangle() { }

//TODO
BBox Triangle::WorldBound() {
	BBox bounds;

	for(int i=0; i<3; i++) {
		float x = vertices[i].position.x;
		float y = vertices[i].position.y;
		float z = vertices[i].position.z;
		Point p(x, y, z);
		bounds = Union(bounds, p);
	}
	return bounds;
}

void Triangle::render() const
{
    bool materials_nonnull = true;
    for ( int i = 0; i < 3; ++i )
        materials_nonnull = materials_nonnull && vertices[i].material;

    // this doesn't interpolate materials. Ah well.
    if ( materials_nonnull )
        vertices[0].material->set_gl_state();

    glBegin(GL_TRIANGLES);
//    glBegin(GL_LINE_LOOP);

    glNormal3dv( &vertices[0].normal.x );
    glTexCoord2dv( &vertices[0].tex_coord.x );
    glVertex3dv( &vertices[0].position.x );

    glNormal3dv( &vertices[1].normal.x );
    glTexCoord2dv( &vertices[1].tex_coord.x );
    glVertex3dv( &vertices[1].position.x);

    glNormal3dv( &vertices[2].normal.x );
    glTexCoord2dv( &vertices[2].tex_coord.x );
    glVertex3dv( &vertices[2].position.x);

    glEnd();

	// 545
/*    glBegin(GL_LINES);
    	const Vertex * v;
    	Vector3 p, n;
		for(int i=0; i<3; i++) {
			v = &vertices[i];
			p = v->position;
			n = v->normal;
			glVertex3f(p.x, p.y, p.z);
			glVertex3f(p.x+n.x, p.y+n.y, p.z+n.z);
		}
    glEnd(); */


    if ( materials_nonnull )
        vertices[0].material->reset_gl_state();
}

/**
 * Test for intersection with triangles and if there is, set the intersection data structure contents
 */
IntersectionData Triangle::intersection_test(Vector3 ray_position, Vector3 ray_direction)
{
    if(!calculated_matrices) // if the matrix calculations haven't been calculated, do so now
    {
        make_transformation_matrix(&matrix, position, orientation, scale);
        make_inverse_transformation_matrix(&inverse_matrix, position, orientation, scale);
        make_normal_matrix(&normal_matrix, matrix);
        calculated_matrices = true; // now they are cached
    }

    // transform the ray into local coordinates
    Vector3 ray_position_local = inverse_matrix.transform_point( ray_position );
    Vector3 ray_direction_local = inverse_matrix.transform_vector( ray_direction );

    Vector3 v1 = vertices[0].position;
    Vector3 v2 = vertices[1].position;
    Vector3 v3 = vertices[2].position;

    // all of the following calculations are based off of the Shirley text

    real_t a = v1.x - v2.x;
    real_t b = v1.y - v2.y;
    real_t c = v1.z - v2.z;

    real_t d = v1.x - v3.x;
    real_t e = v1.y - v3.y;
    real_t f = v1.z - v3.z;

    real_t g = ray_direction_local.x;
    real_t h = ray_direction_local.y;
    real_t i = ray_direction_local.z;

    real_t j = v1.x - ray_position_local.x;
    real_t k = v1.y - ray_position_local.y;
    real_t l = v1.z - ray_position_local.z;

    real_t M = a*(e*i - h*f) + b*(g*f - d*i) + c*(d*h - e*g);
    real_t t = -1*(f*(a*k - j*b) + e*(j*c - a*l) + d*(b*l - k*c))/M;

    IntersectionData intersection;
    intersection.was_intersection = false;

    if(t<0) // there was an intersection, but it occurred before the beginning point of the ray
        return intersection; // was_intersection is currently false, indicating no intersection

    real_t gamma = (i*(a*k - j*b) + h*(j*c - a*l) + g*(b*l - k*c))/M;
    if(gamma < 0 or gamma > 1)
        return intersection;
    real_t beta = (j*(e*i - h*f) + k*(g*f - d*i) + l*(d*h - e*g))/M;
    if(beta < 0 or beta > 1 - gamma)
        return intersection;
    real_t alpha = 1 - beta - gamma;

    intersection.was_intersection = true;

    // retrieve all of the properties of the vertices so we can interpolate them
    Vector3 v1n = vertices[0].normal;
    Vector3 v2n = vertices[1].normal;
    Vector3 v3n = vertices[2].normal;

    Color3 v1d = vertices[0].material->diffuse;
    Color3 v2d = vertices[1].material->diffuse;
    Color3 v3d = vertices[2].material->diffuse;

    Color3 v1a = vertices[0].material->ambient;
    Color3 v2a = vertices[1].material->ambient;
    Color3 v3a = vertices[2].material->ambient;

    Color3 v1s = vertices[0].material->specular;
    Color3 v2s = vertices[1].material->specular;
    Color3 v3s = vertices[2].material->specular;

    real_t v1i = vertices[0].material->refractive_index;
    real_t v2i = vertices[1].material->refractive_index;
    real_t v3i = vertices[2].material->refractive_index;

    Vector2 v1t = vertices[0].tex_coord;
    Vector2 v2t = vertices[1].tex_coord;
    Vector2 v3t = vertices[2].tex_coord;

    int tex_width1, tex_height1, tex_width2, tex_height2, tex_width3, tex_height3;
    vertices[0].material->get_texture_size(&tex_width1, &tex_height1);
    vertices[1].material->get_texture_size(&tex_width2, &tex_height2);
    vertices[2].material->get_texture_size(&tex_width3, &tex_height3);

    intersection.time = t;
    intersection.diffuse = v1d*alpha + v2d*beta + v3d*gamma;
    intersection.ambient = v1a*alpha + v2a*beta + v3a*gamma;
    intersection.specular = v1s*alpha + v2s*beta + v3s*gamma;
    intersection.refractive_index = v1i*alpha + v2i*beta + v3i*gamma;
    Vector2 tex_coord = v1t*alpha + v2t*beta + v3t*gamma;
    Vector3 normal_local = v1n*alpha + v2n*beta + v3n*gamma;
//    Vector3 normal_local = cross(Vector3(v1 - v2), Vector3(v2 - v3));

    // in case there is no texture, default the texture colors to white
    Color3 v1c = Color3(1.0,1.0,1.0);
    Color3 v2c = Color3(1.0,1.0,1.0);
    Color3 v3c = Color3(1.0,1.0,1.0);

    if(tex_width1 != 0 && tex_height1 != 0)
        v1c = vertices[0].material->get_texture_pixel((int)(tex_coord.x*tex_width1)%tex_width1, (int)(tex_coord.y*tex_height1)%tex_height1);
    if(tex_width2 != 0 && tex_height2 != 0)
        v2c = vertices[1].material->get_texture_pixel((int)(tex_coord.x*tex_width2)%tex_width2, (int)(tex_coord.y*tex_height2)%tex_height2);
    if(tex_width3 != 0 && tex_height3 != 0)
        v3c = vertices[2].material->get_texture_pixel((int)(tex_coord.x*tex_width3)%tex_width3, (int)(tex_coord.y*tex_height3)%tex_height3);

    intersection.texture_pixel = v1c*alpha + v2c*beta + v3c*gamma;

    intersection.normal = normal_matrix * normal_local;
    intersection.normal = normalize(intersection.normal); // normals have to be renormalized

    return intersection;
}

} /* _462 */

