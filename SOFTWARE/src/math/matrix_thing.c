#include <stdio.h>
#include <math.h>

typedef struct {
  float x;
  float y;
  float z;
} vector_t;

typedef struct {
  float m11;
  float m12;
  float m13;
  float m21;
  float m22;
  float m23;
  float m31;
  float m32;
  float m33;
} m3x3_t;

typedef struct {
  m3x3_t matrix;
  vector_t translate;
} int_cacheline_t;

vector_t create_vec(float x, float y, float z);
int_cacheline_t create_int_cacheline(vector_t A, vector_t B, vector_t C);

int main() {

    vector_t A0 = create_vec(0.5, 3, 4);
    vector_t B0 = create_vec(3.5, 6, 4);
    vector_t C0 = create_vec(3, 1.5, 4);

	create_int_cacheline(A0,B0,C0);
}

vector_t create_vec(float x, float y, float z)
{
	vector_t vec;
	vec.x = x;
	vec.y = y;
	vec.z = z;
	return vec;
}

int_cacheline_t create_int_cacheline(vector_t A, vector_t B, vector_t C)
{
    float a11, a12, a13, a14;
    float a21, a22, a23, a24;
    float a31, a32, a33, a34;
    float a41, a42, a43, a44;
    float b11, b12, b13, b14;
    float b21, b22, b23, b24;
    float b31, b32, b33, b34;
    float b41, b42, b43, b44;
    float det, inv_det;
    int_cacheline_t c;
    vector_t N;
    float N_norm;
    
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

    printf("%f %f %f %f\n",b11,b12,b13,b14);
    printf("%f %f %f %f\n",b21,b22,b23,b24);
    printf("%f %f %f %f\n",b31,b32,b33,b34);
    printf("%f %f %f %f\n",b41,b42,b43,b44);
  

    c.matrix.m11 = b11;
    c.matrix.m12 = b12;
    c.matrix.m13 = b13;
    c.matrix.m21 = b21;
    c.matrix.m22 = b22;
    c.matrix.m23 = b23;
    c.matrix.m31 = b31;
    c.matrix.m32 = b32;
    c.matrix.m33 = b33;
    c.translate.x = b14;
    c.translate.y = b24;
    c.translate.z = b34;

	int i;
    for(i=0; i<sizeof(int_cacheline_t)/4; i++)
    	printf("%8.8x ",*(((int*)&c)+i));
    printf("\n");

    return c;
}
