/**
 * @file color.hpp
 * @brief Color class
 *
 * @author Eric Butler (edbutler)
 */

#ifndef _462_MATH_COLOR_HPP_
#define _462_MATH_COLOR_HPP_

#include "math/math.hpp"
#include <iostream>
#include <cassert>

namespace _462 {

/**
 * An RGB color.
 */
class Color3
{
public:

    /**
     * The number of dimensions.
     */
    static const size_t DIM = 3;

    static const Color3 Black;
    static const Color3 White;
    static const Color3 Red;
    static const Color3 Green;
    static const Color3 Blue;

    /**
     * Components of this color.
     */
    real_t r, g, b;

    /**
     * Default constructor. Leaves values unitialized.
     */
    Color3() {}

    /**
     * Create a color with the given values.
     */
    Color3( real_t r, real_t g, real_t b )
        : r( r ), g( g ), b( b ) {}

    /**
     * Converts 4-byte RGBA to a color, ignoring alpha.
     */
    Color3( const unsigned char* arr );

    // also uses default copy and assignment

    Color3 operator+( const Color3& rhs ) const {
        return Color3( r + rhs.r, g + rhs.g, b + rhs.b );
    }

    Color3& operator+=( const Color3& rhs ) {
        r += rhs.r;
        g += rhs.g;
        b += rhs.b;
        return *this;
    }

    Color3 operator*( const Color3& rhs ) const {
        return Color3( r * rhs.r, g * rhs.g, b * rhs.b );
    }

    Color3& operator*=( const Color3& rhs ) {
        r *= rhs.r;
        g *= rhs.g;
        b *= rhs.b;
        return *this;
    }

    Color3 operator*( real_t s ) const {
        return Color3( r * s, g * s, b * s );
    }

    Color3& operator*=( real_t s ) {
        r *= s;
        g *= s;
        b *= s;
        return *this;
    }

    bool operator==( const Color3& rhs ) const {
        return r == rhs.r && g == rhs.g && b == rhs.b;
    }

    bool operator!=( const Color3& rhs ) const {
        return !operator==( rhs );
    }

    /**
     * @remark No bounds checking.
     */
    const real_t& operator[]( size_t i ) const {
        // assumes all members are in a contiguous block
        assert( i >= 0 && i < DIM );
        return ( &r )[i];
    }

    /**
     * @remark No bounds checking.
     */
    real_t& operator[]( size_t i ) {
        // assumes all members are in a contiguous block
        assert( i >= 0 && i < DIM );
        return ( &r )[i];
    }

    /**
     * Converts a color to 4-byte RGBA with alpha 1.0.
     */
    void to_array( unsigned char arr[4] ) const;

    /**
     * Puts color in an array of 3 floats.
     */
    void to_array( float arr[DIM] ) const;
};

inline Color3 operator*( real_t s, const Color3& c ) {
    return c * s;
}

Color3 clamp( const Color3& c, real_t min, real_t max );

/**
 * Outputs a color text formatted as "(r,g,b)".
 */
std::ostream& operator<<( std::ostream& os, const Color3& rhs );

} /* _462 */

#endif /* _462_MATH_COLOR_HPP_ */

