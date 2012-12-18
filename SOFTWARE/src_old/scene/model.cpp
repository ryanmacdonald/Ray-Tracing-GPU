/**
 * @file model.cpp
 * @brief Model class
 *
 * @author Eric Butler (edbutler)
 * @author Zeyang Li (zeyangl)
 */

#include "scene/model.hpp"
#include "scene/box.hpp"
#include "scene/material.hpp"
#include <GL/gl.h>
#include <iostream>
#include <cstring>
#include <string>
#include <fstream>
#include <sstream>


namespace _462 {

Model::Model() : mesh( 0 ), material( 0 ) { calculated_matrices = false; }
Model::~Model() { }

void Model::render() const
{
    if ( !mesh )
        return;
    if ( material )
        material->set_gl_state();
    mesh->render();
    if ( material )
        material->reset_gl_state();
}

IntersectionData Model::intersection_test(Vector3 ray_position, Vector3 ray_direction)
{
    const MeshTriangle * triangles = mesh->get_triangles();
    const MeshVertex * vertices = mesh->get_vertices();

    real_t gamma = 0.0;
    real_t beta = 0.0;
    real_t alpha = 0.0;

    if(!box.calculated_collision_box) // if we haven't already calculated the collision box
        box.create(vertices, mesh->num_vertices() ); // do so now (this function sets the boolean to true)

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

    IntersectionData closest_intersection;
    closest_intersection.was_intersection = false; // assume no intersection until one is found

    IntersectionData box_intersection = box.intersection_test(ray_position_local, ray_direction_local);
    if( !box_intersection.was_intersection ) // if it didn't collide with the bounding box
        return closest_intersection;         // then it didn't collide with the object

    for(size_t tri = 0; tri < mesh->num_triangles(); tri++) // iterate through the triangles and check for collision with each
    {
        Vector3 v1 = vertices[triangles[tri].vertices[0]].position;
        Vector3 v2 = vertices[triangles[tri].vertices[1]].position;
        Vector3 v3 = vertices[triangles[tri].vertices[2]].position;

        // calculations from Shirley text

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

        if(t<0) // collision occurred before beginning of ray
            continue;

        gamma = (i*(a*k - j*b) + h*(j*c - a*l) + g*(b*l - k*c))/M;
        if(gamma < 0 or gamma > 1)
            continue;
        beta = (j*(e*i - h*f) + k*(g*f - d*i) + l*(d*h - e*g))/M;
        if(beta < 0 or beta > 1 - gamma)
            continue;
        alpha = 1 - beta - gamma;
        if(!closest_intersection.was_intersection or t < closest_intersection.time) // we found a new closest intersection
        {
            closest_intersection.was_intersection = true;

            Vector3 v1n = vertices[triangles[tri].vertices[0]].normal;
            Vector3 v2n = vertices[triangles[tri].vertices[1]].normal;
            Vector3 v3n = vertices[triangles[tri].vertices[2]].normal;

            Vector2 v1t = vertices[triangles[tri].vertices[0]].tex_coord;
            Vector2 v2t = vertices[triangles[tri].vertices[1]].tex_coord;
            Vector2 v3t = vertices[triangles[tri].vertices[2]].tex_coord;

            int tex_width, tex_height;
            material->get_texture_size(&tex_width, &tex_height);

            v1t.x *= tex_width;
            v2t.x *= tex_width;
            v3t.x *= tex_width;

            v1t.y *= tex_height;
            v2t.y *= tex_height;
            v3t.y *= tex_height;

            closest_intersection.time = t;
            closest_intersection.ambient = material->ambient;
            closest_intersection.diffuse = material->diffuse;
            closest_intersection.specular = material->specular;
            closest_intersection.refractive_index = material->refractive_index;
            Vector2 tex_coord = v1t*alpha + v2t*beta + v3t*gamma;
            Vector3 normal_local = v1n*alpha + v2n*beta + v3n*gamma;

            closest_intersection.texture_pixel = material->get_texture_pixel((int)tex_coord.x, (int)tex_coord.y);

            closest_intersection.normal = normal_matrix * normal_local;
            closest_intersection.normal = normalize(closest_intersection.normal);
        }
    }
    return closest_intersection;
}

} /* _462 */

