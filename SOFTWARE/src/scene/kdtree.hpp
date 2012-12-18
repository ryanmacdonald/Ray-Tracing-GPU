#ifndef _462_KDTREE_HPP_
#define _462_KDTREE_HPP_

#include "scene/scene.hpp"
#include "scene/triangle.hpp"
#include "scene/model.hpp"
#include "scene/mesh.hpp"
#include "scene/pbrt.h"
#include "scene/bbox.hpp"
#include "math/matrix.hpp"
#include <string.h>
#include <iostream>
#include <vector>

namespace _462 {

struct MailboxPrim {
	MailboxPrim(const Triangle &p) {
		primitive = p;
		lastMailboxId = -1;
	}
	Triangle primitive;
	int lastMailboxId;
};

extern int max_num_tri_in_leaf;
extern int sum_leaf_node_tri;

struct KdtreeNode {
	// KdAccelNode Methods
	void initLeaf(int *primNums, int np,
			MailboxPrim *mailboxPrims, MemoryArena &arena) {
		// Update kd leaf node allocation statistics
		//maxDepth.Max(depth);
		if(np > max_num_tri_in_leaf)
			max_num_tri_in_leaf = np;
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
		// 545
		list_index = sum_leaf_node_tri;
		sum_leaf_node_tri += np;
		primNumbers = (int*) malloc(sizeof(int)*np);
		for(int i=0; i<np; i++)
			primNumbers[i] = primNums[i];
	}
	void initInterior(int axis, float s, int n0, int n1, bool sah) {
		split = s;
		flags &= ~3;
		flags |= axis;
		rchild_empty = (n1 == 0) ? true : false; // 545
		lchild_empty = (n0 == 0) ? true : false; // 545
		sah_flip = sah;
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

	bool rchild_empty; // 545
	bool lchild_empty; // 545
	bool sah_flip; // 545
	long list_index; // 545
	int * primNumbers;
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
			return (int)type > (int)e.type; // NOTE! HEY! WHOA! AWOOOGA! CHANGED FROM <
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

	void add_kdtree_triangle( Triangle * g );
	Triangle* const* get_kdtree_triangles() const; // 545
	size_t num_kdtree_triangles() const;

	void dump_to_file(FILE * kd_bin, FILE * kd_txt);
	void dump_kdtree(FILE* kd_bin, FILE * kd_txt, long & byte_cnt, int nodeNum, int depth);
	void dump_lists(FILE * kd_bin, FILE * kd_txt, long & byte_cnt);
	void dump_uttm(FILE * kd_bin, FILE * kd_txt, long & byte_cnt);
	void dump_colors_and_normals(FILE * kd_bin, FILE * kd_txt, long & byte_cnt);
	void dump_aabb(FILE * kd_bin, FILE * kd_txt, long & byte_cnt);

	void init_kdtree(
//	 const std::vector<Triangle * > &p,
		int icost, int tcost,
		float ebonus, int maxt, int maxDepth);

	void load_scene(Scene & scene);
	void create_tree(int nodeNum,
    const BBox &nodeBounds,
	const std::vector<BBox> &allPrimBounds, int *primNums,
	int nPrims, int depth, BoundEdge *edges[3],
	int *prims0, int *prims1, int badRefines = 0);

	// perhaps should be private...
	BBox bounds;
	KdtreeNode *nodes;
	int nAllocedNodes, nextFreeNode;

private:

	std::vector <Triangle *> kdtree_triangles;
	std::vector <int_cacheline_t *> int_cachelines;

	int isectCost, traversalCost, maxTriangles;
	float emptyBonus;
	u_int nMailboxes;
	MailboxPrim *mailboxPrims;
	mutable int curMailboxId;
//	int nAllocedNodes, nextFreeNode;
	MemoryArena arena;

	int nMax, nnMax;
};


} /* _462 */

#endif /* _462_SCENE_SCENE_HPP_ */
