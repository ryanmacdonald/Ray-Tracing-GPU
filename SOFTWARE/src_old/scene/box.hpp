/**
 * @file box.hpp
 * @brief Box class
 *
 * @author Paul Kennedy (pmkenned)
 */

#ifndef _462_SCENE_BOX_HPP_
#define _462_SCENE_BOX_HPP_

#include "scene/scene.hpp"
#include "scene/mesh.hpp"

namespace _462 {

/**
 * A mesh of triangles.
 */
class Box : public Geometry
{
public:

    Mesh mesh;
    real_t min_x, max_x, min_y, max_y, min_z, max_z;

    Box();
    virtual ~Box();

    // create the collision box by searching for minimum and maximum coordinates in vertices list
    void create(const MeshVertex * vertices, int num_vertices);
    bool calculated_collision_box;

    virtual void render() const;
    virtual IntersectionData intersection_test(Vector3 ray_position, Vector3 ray_direction);

};

} /* _462 */

#endif /* _462_SCENE_BOX_HPP_ */

