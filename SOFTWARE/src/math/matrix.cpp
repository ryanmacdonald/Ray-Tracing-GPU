/**
 * @file matrix.cpp
 * @brief Matrix classes.
 *
 * @author Eric Butler (edbutler)
 * @author Zeyang Li (zeyangl)
 */

#include "math/matrix.hpp"
#include "math/quaternion.hpp"

#include <cstring>

namespace _462 {

const Matrix3 Matrix3::Identity = Matrix3( 1, 0, 0,
                                           0, 1, 0,
                                           0, 0, 1 );

const Matrix3 Matrix3::Zero = Matrix3( 0, 0, 0,
                                       0, 0, 0,
                                       0, 0, 0 );


Matrix3::Matrix3( real_t r[SIZE] )
{
    memcpy( m, r, sizeof r );
}

Matrix3::Matrix3( real_t m00, real_t m10, real_t m20,
                  real_t m01, real_t m11, real_t m21,
                  real_t m02, real_t m12, real_t m22 )
{
    _m[0][0] = m00;
    _m[1][0] = m10;
    _m[2][0] = m20;
    _m[0][1] = m01;
    _m[1][1] = m11;
    _m[2][1] = m21;
    _m[0][2] = m02;
    _m[1][2] = m12;
    _m[2][2] = m22;
}

Matrix3 Matrix3::operator+( const Matrix3& rhs ) const
{
    Matrix3 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] + rhs.m[i];
    return rv;
}

Matrix3& Matrix3::operator+=( const Matrix3& rhs )
{
    for ( int i = 0; i < SIZE; i++ )
        m[i] += rhs.m[i];
    return *this;
}

Matrix3 Matrix3::operator-( const Matrix3& rhs ) const
{
    Matrix3 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] - rhs.m[i];
    return rv;
}

Matrix3& Matrix3::operator-=( const Matrix3& rhs )
{
    for ( int i = 0; i < SIZE; i++ )
        m[i] -= rhs.m[i];
    return *this;
}

Matrix3 Matrix3::operator*( const Matrix3& rhs ) const
{
    Matrix3 product;
    for ( int i = 0; i < DIM; ++i )
        for ( int j = 0; j < DIM; ++j )
            product._m[i][j] =
                _m[0][j] * rhs._m[i][0] + _m[1][j] * rhs._m[i][1] +
                _m[2][j] * rhs._m[i][2];
    return product;
}

Vector3 Matrix3::operator*( const Vector3& v ) const
{
    return Vector3( _m[0][0]*v.x + _m[1][0]*v.y + _m[2][0]*v.z,
                    _m[0][1]*v.x + _m[1][1]*v.y + _m[2][1]*v.z,
                    _m[0][2]*v.x + _m[1][2]*v.y + _m[2][2]*v.z );
}

Matrix3& Matrix3::operator*=( const Matrix3& rhs )
{
    return *this = operator*( rhs );
}

Matrix3 Matrix3::operator*( real_t r ) const
{
    Matrix3 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] * r;
    return rv;
}

Matrix3& Matrix3::operator*=( real_t r )
{
    for ( int i = 0; i < SIZE; i++ )
        m[i] *= r;
    return *this;
}

Matrix3 Matrix3::operator/( real_t r ) const
{
    Matrix3 rv;
    real_t inv = 1 / r;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] * inv;
    return rv;
}

Matrix3& Matrix3::operator/=( real_t r )
{
    real_t inv = 1 / r;
    for ( int i = 0; i < SIZE; i++ )
        m[i] *= inv;
    return *this;
}

Matrix3 Matrix3::operator-() const
{
    Matrix3 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = -m[i];
    return rv;
}

bool Matrix3::operator==( const Matrix3& rhs ) const
{
    return memcmp( m, rhs.m, sizeof m ) == 0;
}

bool Matrix3::operator!=( const Matrix3& rhs ) const
{
    return !operator==( rhs );
}

void transpose( Matrix3* rv, const Matrix3& m )
{
    rv->_m[0][0] = m._m[0][0];
    rv->_m[0][1] = m._m[1][0];
    rv->_m[0][2] = m._m[2][0];
    rv->_m[1][0] = m._m[0][1];
    rv->_m[1][1] = m._m[1][1];
    rv->_m[1][2] = m._m[2][1];
    rv->_m[2][0] = m._m[0][2];
    rv->_m[2][1] = m._m[1][2];
    rv->_m[2][2] = m._m[2][2];
}

void inverse( Matrix3* rv, const Matrix3& m )
{
    rv->_m[0][0] = m._m[1][1] * m._m[2][2] - m._m[1][2] * m._m[2][1];
    rv->_m[0][1] = m._m[0][2] * m._m[2][1] - m._m[0][1] * m._m[2][2];
    rv->_m[0][2] = m._m[0][1] * m._m[1][2] - m._m[0][2] * m._m[1][1];
    rv->_m[1][0] = m._m[1][2] * m._m[2][0] - m._m[1][0] * m._m[2][2];
    rv->_m[1][1] = m._m[0][0] * m._m[2][2] - m._m[0][2] * m._m[2][0];
    rv->_m[1][2] = m._m[0][2] * m._m[1][0] - m._m[0][0] * m._m[1][2];
    rv->_m[2][0] = m._m[1][0] * m._m[2][1] - m._m[1][1] * m._m[2][0];
    rv->_m[2][1] = m._m[0][1] * m._m[2][0] - m._m[0][0] * m._m[2][1];
    rv->_m[2][2] = m._m[0][0] * m._m[1][1] - m._m[0][1] * m._m[1][0];

    real_t det = m._m[0][0] * rv->_m[0][0] +
                 m._m[0][1] * rv->_m[1][0] +
                 m._m[0][2] * rv->_m[2][0];

    real_t invdet = 1.0 / det;
    for ( int i = 0; i < Matrix3::SIZE; i++ )
        rv->m[i] *= invdet;
}

const Matrix4 Matrix4::Identity = Matrix4( 1, 0, 0, 0,
                                           0, 1, 0, 0,
                                           0, 0, 1, 0,
                                           0, 0 , 0, 1 );

const Matrix4 Matrix4::Zero = Matrix4( 0, 0, 0, 0,
                                       0, 0, 0, 0,
                                       0, 0, 0, 0,
                                       0, 0, 0, 0 );

Matrix4::Matrix4( real_t r[SIZE] )
{
    memcpy( m , r, sizeof r );
}

Matrix4::Matrix4( real_t m00, real_t m10, real_t m20, real_t m30,
                  real_t m01, real_t m11, real_t m21, real_t m31,
                  real_t m02, real_t m12, real_t m22, real_t m32,
                  real_t m03, real_t m13, real_t m23, real_t m33 )
{
    _m[0][0] = m00;
    _m[1][0] = m10;
    _m[2][0] = m20;
    _m[3][0] = m30;
    _m[0][1] = m01;
    _m[1][1] = m11;
    _m[2][1] = m21;
    _m[3][1] = m31;
    _m[0][2] = m02;
    _m[1][2] = m12;
    _m[2][2] = m22;
    _m[3][2] = m32;
    _m[0][3] = m03;
    _m[1][3] = m13;
    _m[2][3] = m23;
    _m[3][3] = m33;
}


Matrix4 Matrix4::operator+( const Matrix4& rhs ) const
{
    Matrix4 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] + rhs.m[i];
    return rv;
}

Matrix4& Matrix4::operator+=( const Matrix4& rhs )
{
    for ( int i = 0; i < SIZE; i++ )
        m[i] += rhs.m[i];
    return *this;
}

Matrix4 Matrix4::operator-( const Matrix4& rhs ) const
{
    Matrix4 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] - rhs.m[i];
    return rv;
}

Matrix4& Matrix4::operator-=( const Matrix4& rhs )
{
    for ( int i = 0; i < SIZE; i++ )
        m[i] -= rhs.m[i];
    return *this;
}

Matrix4 Matrix4::operator*( const Matrix4& rhs ) const
{
    Matrix4 product;
    for ( int i = 0; i < DIM; ++i )
        for ( int j = 0; j < DIM; ++j )
            product._m[i][j] =
                _m[0][j] * rhs._m[i][0] + _m[1][j] * rhs._m[i][1] +
                _m[2][j] * rhs._m[i][2] + _m[3][j] * rhs._m[i][3];
    return product;
}

Vector4 Matrix4::operator*( const Vector4& v ) const
{
    return Vector4( _m[0][0]*v.x + _m[1][0]*v.y + _m[2][0]*v.z + _m[3][0]*v.w,
                    _m[0][1]*v.x + _m[1][1]*v.y + _m[2][1]*v.z + _m[3][1]*v.w,
                    _m[0][2]*v.x + _m[1][2]*v.y + _m[2][2]*v.z + _m[3][2]*v.w,
                    _m[0][3]*v.x + _m[1][3]*v.y + _m[2][3]*v.z + _m[3][3]*v.w );
}

Matrix4& Matrix4::operator*=( const Matrix4& rhs )
{
    return *this = operator*( rhs );
}

Matrix4 Matrix4::operator*( real_t r ) const
{
    Matrix4 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] * r;
    return rv;
}

Matrix4& Matrix4::operator*=( real_t r )
{
    for ( int i = 0; i < SIZE; i++ )
        m[i] *= r;
    return *this;
}

Matrix4 Matrix4::operator/( real_t r ) const
{
    Matrix4 rv;
    real_t inv = 1 / r;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = m[i] * inv;
    return rv;
}

Matrix4& Matrix4::operator/=( real_t r )
{
    real_t inv = 1 / r;
    for ( int i = 0; i < SIZE; i++ )
        m[i] *= inv;
    return *this;
}

Matrix4 Matrix4::operator-() const
{
    Matrix4 rv;
    for ( int i = 0; i < SIZE; i++ )
        rv.m[i] = -m[i];
    return rv;
}

bool Matrix4::operator==( const Matrix4& rhs ) const
{
    return memcmp( m, rhs.m, sizeof m ) == 0;
}

bool Matrix4::operator!=( const Matrix4& rhs ) const
{
    return !operator==( rhs );
}

static void make_translation_matrix( Matrix4* mat, const Vector3& pos )
{
    *mat = Matrix4(
        1.0, 0.0, 0.0, pos.x,
        0.0, 1.0, 0.0, pos.y,
        0.0, 0.0, 1.0, pos.z,
        0.0, 0.0, 0.0, 1.0 );
}

static void make_scaling_matrix( Matrix4* mat, const Vector3& scl )
{
    *mat = Matrix4(
        scl.x, 0.0,   0.0,   0.0,
        0.0,   scl.y, 0.0,   0.0,
        0.0,   0.0,   scl.z, 0.0,
        0.0,   0.0,   0.0,   1.0 );
}


void make_transformation_matrix(
    Matrix4* mat, const Vector3& pos, const Quaternion& ori, const Vector3& scl )
{
    Matrix4 sclmat, orimat;
    ori.to_matrix( &orimat );
    make_scaling_matrix( &sclmat, scl );
    *mat = orimat * sclmat;
    // don't need to actually do the multiplication, can take shortcut
    // since we're multiplying translation by a linear matrix
    mat->m[12] = pos.x;
    mat->m[13] = pos.y;
    mat->m[14] = pos.z;
}

void make_inverse_transformation_matrix(
    Matrix4* mat, const Vector3& pos, const Quaternion& ori, const Vector3& scl )
{
    // assumes orientation is normalized
    Matrix4 sclmat, orimat, trnmat;

    make_scaling_matrix( &sclmat, Vector3( 1.0 / scl.x, 1.0 / scl.y, 1.0 / scl.z ) );
    conjugate( ori ).to_matrix( &orimat );
    make_translation_matrix( &trnmat, -pos );

    *mat = sclmat * orimat * trnmat;
}

/** algorithm from:  http://www.mathwords.com/c/cofactor.htm **/
void make_normal_matrix( Matrix3* rv, const Matrix4& tmat )
{
    Matrix3 tmp1, tmp2;

    tmp1._m[0][0] = tmat._m[0][0];
    tmp1._m[0][1] = tmat._m[0][1];
    tmp1._m[0][2] = tmat._m[0][2];
    tmp1._m[1][0] = tmat._m[1][0];
    tmp1._m[1][1] = tmat._m[1][1];
    tmp1._m[1][2] = tmat._m[1][2];
    tmp1._m[2][0] = tmat._m[2][0];
    tmp1._m[2][1] = tmat._m[2][1];
    tmp1._m[2][2] = tmat._m[2][2];

    inverse( &tmp2, tmp1 );
    transpose( rv, tmp2 );
}

// 545
int_cacheline_t::int_cacheline_t(Vector3 A, Vector3 B, Vector3 C)
{
    double a11, a12, a13, a14;
    double a21, a22, a23, a24;
    double a31, a32, a33, a34;
    double a41, a42, a43, a44;
    double b11, b12, b13, b14;
    double b21, b22, b23, b24;
    double b31, b32, b33, b34;
    double b41, b42, b43, b44;
    double det, inv_det;
//    int_cacheline_t c;
    Vector3 N;
    double N_norm;

	// ATTEMPTING TO MAKE COORDINATE SYSTEMS CONSISTENT
	// seems to work....
	double temp = A.x;
	A.x = A.y;
	A.y = temp;
	temp = B.x;
	B.x = B.y;
	B.y = temp;
	temp = C.x;
	C.x = C.y;
	C.y = temp;
	// END OF TRANSLATION
    
    N.x = (C.y - A.y)*(B.z - A.z) - (C.z - A.z)*(B.y - A.y);
    N.y = (C.z - A.z)*(B.x - A.x) - (C.x - A.x)*(B.z - A.z);
    N.z = (C.x - A.x)*(B.y - A.y) - (C.y - A.y)*(B.x - A.x);
    
    N_norm = sqrt(N.x*N.x + N.y*N.y + N.z*N.z);
    N.x = N.x / N_norm;
    N.y = N.y / N_norm;
    N.z = N.z / N_norm;

    a11 = A.x-C.x; a12 = B.x-C.x; a13 = N.x-C.x; a14 = C.x;
    a21 = A.y-C.y; a22 = B.y-C.y; a23 = N.y-C.y; a24 = C.y;
    a31 = A.z-C.z; a32 = B.z-C.z; a33 = N.z-C.z; a34 = C.z;
    a41 = 0; a42 = 0; a43 = 0; a44 = 1;

    det = a11*a22*a33*a44 + a11*a23*a34*a42 + a11*a24*a32*a43 + 
          a12*a21*a34*a43 + a12*a23*a31*a44 + a12*a24*a33*a41 + 
          a13*a21*a32*a44 + a13*a22*a34*a41 + a13*a24*a31*a42 + 
          a14*a21*a33*a42 + a14*a22*a31*a43 + a14*a23*a32*a41 - 
          a11*a22*a34*a43 - a11*a23*a32*a44 - a11*a24*a33*a42 - 
          a12*a21*a33*a44 - a12*a23*a34*a41 - a12*a24*a31*a43 - 
          a13*a21*a34*a42 - a13*a22*a31*a44 - a13*a24*a32*a41 - 
          a14*a21*a32*a43 - a14*a22*a33*a41 - a14*a23*a31*a42 ;
    inv_det = 1.0/det;

		b11 = inv_det * (a22*a33*a44 + a23*a34*a42 + a24*a32*a43 - a22*a34*a43 - a23*a32*a44 - a24*a33*a42) ;
		b12 = inv_det * (a12*a34*a43 + a13*a32*a44 + a14*a33*a42 - a12*a33*a44 - a13*a34*a42 - a14*a32*a43) ;
		b13 = inv_det * (a12*a23*a44 + a13*a24*a42 + a14*a22*a43 - a12*a24*a43 - a13*a22*a44 - a14*a23*a42) ;
		b14 = inv_det * (a12*a24*a33 + a13*a22*a34 + a14*a23*a32 - a12*a23*a34 - a13*a24*a32 - a14*a22*a33) ;
		b21 = inv_det * (a21*a34*a43 + a23*a31*a44 + a24*a33*a41 - a21*a33*a44 - a23*a34*a41 - a24*a31*a43) ;
		b22 = inv_det * (a11*a33*a44 + a13*a34*a41 + a14*a31*a43 - a11*a34*a43 - a13*a31*a44 - a14*a33*a41) ;
		b23 = inv_det * (a11*a24*a43 + a13*a21*a44 + a14*a23*a41 - a11*a23*a44 - a13*a24*a41 - a14*a21*a43) ;
		b24 = inv_det * (a11*a23*a34 + a13*a24*a31 + a14*a21*a33 - a11*a24*a33 - a13*a21*a34 - a14*a23*a31) ;
		b31 = inv_det * (a21*a32*a44 + a22*a34*a41 + a24*a31*a42 - a21*a34*a42 - a22*a31*a44 - a24*a32*a41) ;
		b32 = inv_det * (a11*a34*a42 + a12*a31*a44 + a14*a32*a41 - a11*a32*a44 - a12*a34*a41 - a14*a31*a42) ;
		b33 = inv_det * (a11*a22*a44 + a12*a24*a41 + a14*a21*a42 - a11*a24*a42 - a12*a21*a44 - a14*a22*a41) ;
		b34 = inv_det * (a11*a24*a32 + a12*a21*a34 + a14*a22*a31 - a11*a22*a34 - a12*a24*a31 - a14*a21*a32) ;
    b41 = 0;
    b42 = 0;
    b43 = 0;
    b44 = 1;

/*    printf("%f %f %f %f\n",b11,b12,b13,b14);
    printf("%f %f %f %f\n",b21,b22,b23,b24);
    printf("%f %f %f %f\n",b31,b32,b33,b34);
    printf("%f %f %f %f\n",b41,b42,b43,b44); */

	// TODO: consider using already existing matrix constructor
    matrix._m[0][0] = b11;
    matrix._m[0][1] = b12;
    matrix._m[0][2] = b13;
    matrix._m[1][0] = b21;
    matrix._m[1][1] = b22;
    matrix._m[1][2] = b23;
    matrix._m[2][0] = b31;
    matrix._m[2][1] = b32;
    matrix._m[2][2] = b33;
    translate.x = b14;
    translate.y = b24;
    translate.z = b34;

/*	unsigned i;
    for(i=0; i<sizeof(int_cacheline_t)/4; i++)
    	printf("%8.8x ",*(((int*)this)+i));
    printf("\n");
*/
//    return c;
}

} /* _462 */

