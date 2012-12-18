/**
 * @file math.hpp
 * @brief General math declarations and definitions.
 *
 * @author Eric Butler (edbutler)
 * @author Zeyang Li (zeyangl)
 */

#ifndef _462_MATH_MATH_HPP_
#define _462_MATH_MATH_HPP_

#include <algorithm>
#include <cmath>

namespace _462 {

// floating point precision set by this typedef
typedef double real_t;

class Color3;

// since the standard library happily does not provide one
#define PI 3.141592653589793238

template<typename T>
inline T clamp( T val, T min, T max )
{
    return std::min( max, std::max( min, val ) );
}


} /* _462 */

#endif /* _462_MATH_MATH_HPP_ */

