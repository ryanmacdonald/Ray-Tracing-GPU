/**
 * @file vector.cpp
 * @brief Vector classes.
 *
 * @author Eric Butler (edbutler)
 */

#include "math/vector.hpp"

namespace _462 {

const Vector2 Vector2::Zero = Vector2( 0, 0 );
const Vector2 Vector2::Ones = Vector2( 1, 1 );
const Vector2 Vector2::UnitX = Vector2( 1, 0 );
const Vector2 Vector2::UnitY = Vector2( 0, 1 );

std::ostream& operator<<( std::ostream& os, const Vector2& v )
{
    return os << '(' << v.x << ',' << v.y << ')';
}

const Vector3 Vector3::Zero = Vector3( 0, 0, 0 );
const Vector3 Vector3::Ones = Vector3( 1, 1, 1 );
const Vector3 Vector3::UnitX = Vector3( 1, 0, 0 );
const Vector3 Vector3::UnitY = Vector3( 0, 1, 0 );
const Vector3 Vector3::UnitZ = Vector3( 0, 0, 1 );

std::ostream& operator<<( std::ostream& os, const Vector3& v )
{
    return os << '(' << v.x << ',' << v.y << ',' << v.z << ')';
}

const Vector4 Vector4::Zero = Vector4( 0, 0, 0, 0 );
const Vector4 Vector4::Ones = Vector4( 1, 1, 1, 1 );
const Vector4 Vector4::UnitX = Vector4( 1, 0, 0, 0 );
const Vector4 Vector4::UnitY = Vector4( 0, 1, 0, 0 );
const Vector4 Vector4::UnitZ = Vector4( 0, 0, 1, 0 );
const Vector4 Vector4::UnitW = Vector4( 0, 0, 0, 1 );

std::ostream& operator<<( std::ostream& os, const Vector4& v )
{
    return os << '(' << v.x << ',' << v.y << ',' << v.z << ',' << v.w << ')';
}

} /* _462 */

