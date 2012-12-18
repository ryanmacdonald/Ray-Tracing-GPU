#ifndef _462_KDTREE_HPP_
#define _462_KDTREE_HPP_

#include "scene/scene.hpp"
#include "scene/triangle.hpp"
#include "scene/model.hpp"
#include "scene/mesh.hpp"
#include <iostream>
#include <vector>

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

#define min(X, Y) ((X) < (Y)) ? (X) : (Y)
#define max(X, Y) ((X) > (Y)) ? (X) : (Y)

namespace _462 {

class Point;
class Normal;
class Vector;
class Ray;


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
				currentBlock = (char *)malloc(max(sz, blockSize));
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


class BBox {
public:
	// BBox Public Methods
	BBox() {
		pMin = Point( INFINITY,  INFINITY,  INFINITY);
		pMax = Point(-INFINITY, -INFINITY, -INFINITY);
	}
	BBox(const Point &p) : pMin(p), pMax(p) { }
	BBox(const Point &p1, const Point &p2) {
		pMin = Point(min(p1.x, p2.x),
					 min(p1.y, p2.y),
					 min(p1.z, p2.z));
		pMax = Point(max(p1.x, p2.x),
					 max(p1.y, p2.y),
					 max(p1.z, p2.z));
	}
	friend inline std::ostream &
		operator<<(std::ostream &os, const BBox &b);
	friend BBox Union(const BBox &b, const Point &p);
	friend BBox Union(const BBox &b, const BBox &b2);
	bool Overlaps(const BBox &b) const {
		bool x = (pMax.x >= b.pMin.x) && (pMin.x <= b.pMax.x);
		bool y = (pMax.y >= b.pMin.y) && (pMin.y <= b.pMax.y);
		bool z = (pMax.z >= b.pMin.z) && (pMin.z <= b.pMax.z);
		return (x && y && z);
	}
	bool Inside(const Point &pt) const {
		return (pt.x >= pMin.x && pt.x <= pMax.x &&
	            pt.y >= pMin.y && pt.y <= pMax.y &&
	            pt.z >= pMin.z && pt.z <= pMax.z);
	}
	void Expand(float delta) {
		pMin -= Vector(delta, delta, delta);
		pMax += Vector(delta, delta, delta);
	}
	float Volume() const {
		Vector d = pMax - pMin;
		return d.x * d.y * d.z;
	}
	int MaximumExtent() const {
		Vector diag = pMax - pMin;
		if (diag.x > diag.y && diag.x > diag.z)
			return 0;
		else if (diag.y > diag.z)
			return 1;
		else
			return 2;
	}
	void BoundingSphere(Point *c, float *rad) const;
	bool IntersectP(const Ray &ray,
	                float *hitt0 = NULL,
					float *hitt1 = NULL) const;
	// BBox Public Data
	Point pMin, pMax;
};

BBox Union(const BBox &b, const Point &p) {
	BBox ret = b;
	ret.pMin.x = min(b.pMin.x, p.x);
	ret.pMin.y = min(b.pMin.y, p.y);
	ret.pMin.z = min(b.pMin.z, p.z);
	ret.pMax.x = max(b.pMax.x, p.x);
	ret.pMax.y = max(b.pMax.y, p.y);
	ret.pMax.z = max(b.pMax.z, p.z);
	return ret;
}
BBox Union(const BBox &b, const BBox &b2) {
	BBox ret;
	ret.pMin.x = min(b.pMin.x, b2.pMin.x);
	ret.pMin.y = min(b.pMin.y, b2.pMin.y);
	ret.pMin.z = min(b.pMin.z, b2.pMin.z);
	ret.pMax.x = max(b.pMax.x, b2.pMax.x);
	ret.pMax.y = max(b.pMax.y, b2.pMax.y);
	ret.pMax.z = max(b.pMax.z, b2.pMax.z);
	return ret;
}

struct MailboxPrim {
	MailboxPrim(const Reference<Triangle> &p) {
		primitive = p;
		lastMailboxId = -1;
	}
	Reference<Triangle> primitive;
	int lastMailboxId;
};


struct KdtreeNode {
	// KdAccelNode Methods
	void initLeaf(int *primNums, int np,
			MailboxPrim *mailboxPrims, MemoryArena &arena) {
		// Update kd leaf node allocation statistics
		//maxDepth.Max(depth);
		nPrims = np << 2;
		flags |= 3;
		// Store _MailboxPrim *_s for leaf node
		if (np == 0)
			onePrimitive = NULL;
		else if (np == 1)
			onePrimitive = &mailboxPrims[primNums[0]];
		else {
			primitives = (MailboxPrim **)arena.Alloc(np *
				sizeof(MailboxPrim *));
			for (int i = 0; i < np; ++i)
				primitives[i] = &mailboxPrims[primNums[i]];
		}
	}
	void initInterior(int axis, float s) {
		split = s;
		flags &= ~3;
		flags |= axis;
	}
	float SplitPos() const { return split; }
	int nPrimitives() const { return nPrims >> 2; }
	int SplitAxis() const { return flags & 3; }
	bool IsLeaf() const { return (flags & 3) == 3; }
	union {
		u_int flags;   // Both
		float split;   // Interior
		u_int nPrims;  // Leaf
	};
	union {
		u_int aboveChild;           // Interior
		MailboxPrim *onePrimitive;  // Leaf
		MailboxPrim **primitives;   // Leaf
	};
};

struct BoundEdge {
	// BoundEdge Public Methods
	BoundEdge() { }
	BoundEdge(float tt, int pn, bool starting) {
		t = tt;
		primNum = pn;
		type = starting ? START : END;
	}
	bool operator<(const BoundEdge &e) const {
		if (t == e.t)
			return (int)type < (int)e.type;
		else return t < e.t;
	}
	float t;
	int primNum;
	enum { START, END } type;
};


class Kdtree
{
public:
	Kdtree();
	~Kdtree();

	void add_kdtree_triangle( Geometry* g );
	Geometry* const* get_kdtree_triangles() const; // 545
	size_t num_kdtree_triangles() const;

	void init_kdtree();

	void load_scene(Scene & scene);
	void create_tree(int nodeNum,
    const BBox &nodeBounds,
	const std::vector<BBox> &allPrimBounds, int *primNums,
	int nPrims, int depth, BoundEdge *edges[3],
	int *prims0, int *prims1, int badRefines = 0);

private:

	std::vector <Geometry *> kdtree_triangles;

	KdtreeNode *nodes;

	int isectCost, traversalCost, maxTriangles;
	float emptyBonus;
	u_int nMailboxes;
	MailboxPrim *mailboxPrims;
	mutable int curMailboxId;
	int nAllocedNodes, nextFreeNode;
	BBox bounds;
	MemoryArena arena;

};


} /* _462 */

#endif /* _462_SCENE_SCENE_HPP_ */
