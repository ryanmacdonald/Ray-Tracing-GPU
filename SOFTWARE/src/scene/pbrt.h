#ifndef _PBRT_H_
#define _PBRT_H_

#include <vector>
#include <malloc.h>
#include <assert.h>
#include <math.h>
#include <iostream>

// Global Constants
#ifdef WIN32
#define alloca _alloca
#endif
#ifdef M_PI
#undef M_PI
#endif
#define M_PI           3.14159265358979323846f
#define INV_PI  0.31830988618379067154f
#define INV_TWOPI  0.15915494309189533577f
#ifndef INFINITY
#define INFINITY FLT_MAX
#endif
#define PBRT_VERSION 1.0
#define RAY_EPSILON 1e-3f
#define COLOR_SAMPLES 3

#define MIN(X, Y) ((X) < (Y)) ? (X) : (Y)
#define MAX(X, Y) ((X) > (Y)) ? (X) : (Y)

class Point;
class Normal;
class Vector;
class Ray;

typedef unsigned int u_int;

class MemoryArena {
public:
	// MemoryArena Public Methods
	MemoryArena(u_int bs = 32768) {
		blockSize = bs;
		curBlockPos = 0;
		currentBlock = (char *)malloc(blockSize);
	}
	~MemoryArena() {
		free(currentBlock);
		for (u_int i = 0; i < usedBlocks.size(); ++i)
			free(usedBlocks[i]);
		for (u_int i = 0; i < availableBlocks.size(); ++i)
			free(availableBlocks[i]);
	}
	void *Alloc(u_int sz) {
		// Round up _sz_ to minimum machine alignment
		sz = ((sz + 7) & (~7));
		if (curBlockPos + sz > blockSize) {
			// Get new block of memory for _MemoryArena_
			usedBlocks.push_back(currentBlock);
			if (availableBlocks.size() && sz <= blockSize) {
				currentBlock = availableBlocks.back();
				availableBlocks.pop_back();
			}
			else
				currentBlock = (char *)malloc(MAX(sz, blockSize));
			curBlockPos = 0;
		}
		void *ret = currentBlock + curBlockPos;
		curBlockPos += sz;
		return ret;
	}
	void FreeAll() {
		curBlockPos = 0;
		while (usedBlocks.size()) {
			availableBlocks.push_back(usedBlocks.back());
			usedBlocks.pop_back();
		}
	}
private:
	// MemoryArena Private Data
	u_int curBlockPos, blockSize;
	char *currentBlock;
	std::vector<char *> usedBlocks, availableBlocks;
};


template <class T> class Reference {
public:
	// Reference Public Methods
	Reference(T *p = NULL) {
		ptr = p;
		if (ptr) ++ptr->nReferences;
	}
	Reference(const Reference<T> &r) {
		ptr = r.ptr;
		if (ptr) ++ptr->nReferences;
	}
	Reference &operator=(const Reference<T> &r) {
		if (r.ptr) r.ptr->nReferences++;
		if (ptr && --ptr->nReferences == 0) delete ptr;
		ptr = r.ptr;
		return *this;
	}
	Reference &operator=(T *p) {
		if (p) p->nReferences++;
		if (ptr && --ptr->nReferences == 0) delete ptr;
		ptr = p;
		return *this;
	}
	~Reference() {
		if (ptr && --ptr->nReferences == 0)
			delete ptr;
	}
	T *operator->() { return ptr; }
	const T *operator->() const { return ptr; }
	operator bool() const { return ptr != NULL; }
	bool operator<(const Reference<T> &t2) const {
		return ptr < t2.ptr;
	}
private:
	T *ptr;
};


class Vector {
public:
	// Vector Public Methods
	Vector(float _x=0, float _y=0, float _z=0)
		: x(_x), y(_y), z(_z) {
	}
	explicit Vector(const Point &p);
	Vector operator+(const Vector &v) const {
		return Vector(x + v.x, y + v.y, z + v.z);
	}
	
	Vector& operator+=(const Vector &v) {
		x += v.x; y += v.y; z += v.z;
		return *this;
	}
	Vector operator-(const Vector &v) const {
		return Vector(x - v.x, y - v.y, z - v.z);
	}
	
	Vector& operator-=(const Vector &v) {
		x -= v.x; y -= v.y; z -= v.z;
		return *this;
	}
	bool operator==(const Vector &v) const {
		return x == v.x && y == v.y && z == v.z;
	}
	Vector operator*(float f) const {
		return Vector(f*x, f*y, f*z);
	}
	
	Vector &operator*=(float f) {
		x *= f; y *= f; z *= f;
		return *this;
	}
	Vector operator/(float f) const {
		assert(f!=0);
		float inv = 1.f / f;
		return Vector(x * inv, y * inv, z * inv);
	}
	
	Vector &operator/=(float f) {
		assert(f!=0);
		float inv = 1.f / f;
		x *= inv; y *= inv; z *= inv;
		return *this;
	}
	Vector operator-() const {
		return Vector(-x, -y, -z);
	}
	float operator[](int i) const {
		assert(i >= 0 && i <= 2);
		return (&x)[i];
	}
	
	float &operator[](int i) {
		assert(i >= 0 && i <= 2);
		return (&x)[i];
	}
	float LengthSquared() const { return x*x + y*y + z*z; }
	float Length() const { return sqrtf(LengthSquared()); }
	explicit Vector(const Normal &n);
	// Vector Public Data
	float x, y, z;
};


class Normal {
public:
	// Normal Methods
	Normal(float _x=0, float _y=0, float _z=0)
		: x(_x), y(_y), z(_z) {}
	Normal operator-() const {
		return Normal(-x, -y, -z);
	}
	Normal operator+ (const Normal &v) const {
		return Normal(x + v.x, y + v.y, z + v.z);
	}
	
	Normal& operator+=(const Normal &v) {
		x += v.x; y += v.y; z += v.z;
		return *this;
	}
	Normal operator- (const Normal &v) const {
		return Normal(x - v.x, y - v.y, z - v.z);
	}
	
	Normal& operator-=(const Normal &v) {
		x -= v.x; y -= v.y; z -= v.z;
		return *this;
	}
	Normal operator* (float f) const {
		return Normal(f*x, f*y, f*z);
	}
	
	Normal &operator*=(float f) {
		x *= f; y *= f; z *= f;
		return *this;
	}
	Normal operator/ (float f) const {
		float inv = 1.f/f;
		return Normal(x * inv, y * inv, z * inv);
	}
	
	Normal &operator/=(float f) {
		float inv = 1.f/f;
		x *= inv; y *= inv; z *= inv;
		return *this;
	}
	float LengthSquared() const { return x*x + y*y + z*z; }
	float Length() const        { return sqrtf(LengthSquared()); }
	
	explicit Normal(const Vector &v)
	  : x(v.x), y(v.y), z(v.z) {}
	float operator[](int i) const { return (&x)[i]; }
	float &operator[](int i) { return (&x)[i]; }
	// Normal Public Data
	float x,y,z;
};


class Point {
public:
	// Point Methods
	Point(float _x=0, float _y=0, float _z=0)
		: x(_x), y(_y), z(_z) {
	}
	Point operator+(const Vector &v) const {
		return Point(x + v.x, y + v.y, z + v.z);
	}
	
	Point &operator+=(const Vector &v) {
		x += v.x; y += v.y; z += v.z;
		return *this;
	}
	Vector operator-(const Point &p) const {
		return Vector(x - p.x, y - p.y, z - p.z);
	}
	
	Point operator-(const Vector &v) const {
		return Point(x - v.x, y - v.y, z - v.z);
	}
	
	Point &operator-=(const Vector &v) {
		x -= v.x; y -= v.y; z -= v.z;
		return *this;
	}
	Point &operator+=(const Point &p) {
		x += p.x; y += p.y; z += p.z;
		return *this;
	}
	Point operator+(const Point &p) {
		return Point(x + p.x, y + p.y, z + p.z);
	}
	Point operator* (float f) const {
		return Point(f*x, f*y, f*z);
	}
	Point &operator*=(float f) {
		x *= f; y *= f; z *= f;
		return *this;
	}
	Point operator/ (float f) const {
		float inv = 1.f/f;
		return Point(inv*x, inv*y, inv*z);
	}
	Point &operator/=(float f) {
		float inv = 1.f/f;
		x *= inv; y *= inv; z *= inv;
		return *this;
	}
	float operator[](int i) const { return (&x)[i]; }
	float &operator[](int i) { return (&x)[i]; }
	// Point Public Data
	float x,y,z;
};

class Ray {
public:
	// Ray Public Methods
	Ray(): mint(RAY_EPSILON), maxt(INFINITY), time(0.f) {}
	Ray(const Point &origin, const Vector &direction,
		float start = RAY_EPSILON, float end = INFINITY, float t = 0.f)
		: o(origin), d(direction), mint(start), maxt(end), time(t) { }
	Point operator()(float t) const { return o + d * t; }
	// Ray Public Data
	Point o;
	Vector d;
	mutable float mint, maxt;
	float time;
};


#endif
