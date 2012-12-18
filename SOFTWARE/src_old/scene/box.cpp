/**
 * @file box.cpp
 * @brief Collision box class.
 *
 * @author Paul Kennedy (pmkenned)
 */

#include "scene/box.hpp"
#include "scene/material.hpp"
#include "scene/mesh.hpp"
#include <GL/gl.h>
#include <iostream>
#include <cstring>
#include <string>
#include <fstream>
#include <sstream>


namespace _462 {

Box::Box():
    calculated_collision_box( false )
 { }

Box::~Box() { }

void Box::render() const {}

/**
 * Calculates a collision box surrounding the model.
 */
void Box::create(const MeshVertex * vertices, int num_vertices)
{
    min_x = max_x = vertices[0].position.x;
    min_y = max_y = vertices[0].position.y;
    min_z = max_z = vertices[0].position.z;
    for(int i=0; i < num_vertices; i++)
    {
        real_t x = vertices[i].position.x;
        real_t y = vertices[i].position.y;
        real_t z = vertices[i].position.z;
        if(x < min_x)
            min_x = x;
        if(x > max_x)
            max_x = x;
        if(y < min_y)
            min_y = y;
        if(y > max_y)
            max_y = y;
        if(z < min_z)
            min_z = z;
        if(z > max_z)
            max_z = z;
    }

    mesh.create_collision_box(min_x, max_x, min_y, max_y, min_z, max_z);
    calculated_collision_box = true;
}

/* PMK
 *
 */
IntersectionData Box::intersection_test(Vector3 ray_position, Vector3 ray_direction)
{
    const MeshTriangle * triangles = mesh.get_triangles();
    const MeshVertex * vertices = mesh.get_vertices();

    real_t gamma = 0.0;
    real_t beta = 0.0;
    real_t alpha = 0.0;

    IntersectionData closest_intersection;
    closest_intersection.was_intersection = false; // assume no intersection until one is found

    for(size_t tri = 0; tri < mesh.num_triangles(); tri++)
    {
        Vector3 v1 = vertices[triangles[tri].vertices[0]].position;
        Vector3 v2 = vertices[triangles[tri].vertices[1]].position;
        Vector3 v3 = vertices[triangles[tri].vertices[2]].position;

        real_t a = v1.x - v2.x;
        real_t b = v1.y - v2.y;
        real_t c = v1.z - v2.z;

        real_t d = v1.x - v3.x;
        real_t e = v1.y - v3.y;
        real_t f = v1.z - v3.z;

        real_t g = ray_direction.x;
        real_t h = ray_direction.y;
        real_t i = ray_direction.z;

        real_t j = v1.x - ray_position.x;
        real_t k = v1.y - ray_position.y;
        real_t l = v1.z - ray_position.z;

        real_t M = a*(e*i - h*f) + b*(g*f - d*i) + c*(d*h - e*g);
        real_t t = -1*(f*(a*k - j*b) + e*(j*c - a*l) + d*(b*l - k*c))/M;

        if(t<0) // the intersection occurred before the starting point
            continue;

        gamma = (i*(a*k - j*b) + h*(j*c - a*l) + g*(b*l - k*c))/M;
        if(gamma < 0 or gamma > 1)
            continue;
        beta = (j*(e*i - h*f) + k*(g*f - d*i) + l*(d*h - e*g))/M;
        if(beta < 0 or beta > 1 - gamma)
            continue;
        alpha = 1 - beta - gamma;
        if(!closest_intersection.was_intersection or t < closest_intersection.time)
            closest_intersection.was_intersection = true;
    }
    return closest_intersection;
}

} /* _462 */

