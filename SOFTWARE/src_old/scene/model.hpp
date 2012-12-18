/**
 * @file model.hpp
 * @brief Model class
 *
 * @author Eric Butler (edbutler)
 */

#ifndef _462_SCENE_MODEL_HPP_
#define _462_SCENE_MODEL_HPP_

#include "scene/scene.hpp"
#include "scene/mesh.hpp"
#include "scene/box.hpp"

namespace _462 {

/**
 * A mesh of triangles.
 */
class Model : public Geometry
{
public:

    const Mesh* mesh;
    const Material* material;

    Box box;

    Model();
    virtual ~Model();

    virtual void render() const;
    virtual IntersectionData intersection_test(Vector3 ray_position, Vector3 ray_direction); // PMK

};

} /* _462 */

#endif /* _462_SCENE_MODEL_HPP_ */

