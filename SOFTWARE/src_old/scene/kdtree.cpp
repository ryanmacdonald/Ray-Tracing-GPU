#include "scene/kdtree.hpp"

namespace _462 {

Kdtree::Kdtree()
{
}

Kdtree::~Kdtree() { }

void Kdtree::init_kdtree(
	 const vector<Reference<Triangle> > &p,
	int icost, int tcost,
	float ebonus, int maxp, int maxDepth) {

	std::vector<Reference<Triangle > > prims;
	for (u_int i = 0; i < p.size(); ++i)
		p[i]->FullyRefine(prims);
	// Initialize mailboxes for _KdTreeAccel_
	curMailboxId = 0;
	nMailboxes = prims.size();
	mailboxPrims = (MailboxPrim *)AllocAligned(nMailboxes *
		sizeof(MailboxPrim));
	for (u_int i = 0; i < nMailboxes; ++i)
		new (&mailboxPrims[i]) MailboxPrim(prims[i]);
	// Build kd-tree for accelerator
	nextFreeNode = nAllocedNodes = 0;
	if (maxDepth <= 0)
		maxDepth =
		    Round2Int(8 + 1.3f * Log2Int(float(prims.size())));
	// Compute bounds for kd-tree construction
	vector<BBox> primBounds;
	primBounds.reserve(prims.size());
	for (u_int i = 0; i < prims.size(); ++i) {
		BBox b = prims[i]->WorldBound();
		bounds = Union(bounds, b);
		primBounds.push_back(b);
	}
	// Allocate working memory for kd-tree construction
	BoundEdge *edges[3];
	for (int i = 0; i < 3; ++i)
		edges[i] = new BoundEdge[2*prims.size()];
	int *prims0 = new int[prims.size()];
	int *prims1 = new int[(maxDepth+1) * prims.size()];
	// Initialize _primNums_ for kd-tree construction
	int *primNums = new int[prims.size()];
	for (u_int i = 0; i < prims.size(); ++i)
		primNums[i] = i;
	// Start recursive construction of kd-tree
	create_tree(0, bounds, primBounds, primNums,
	          prims.size(), maxDepth, edges,
			  prims0, prims1);
	// Free working memory for kd-tree construction
	delete[] primNums;
	for (int i = 0; i < 3; ++i)
		delete[] edges[i];
	delete[] prims0;
	delete[] prims1;

}

void Kdtree::load_scene(Scene & scene) {
	Geometry* const * geoms = scene.get_geometries();

    size_t num_geoms = scene.num_geometries();

    for(unsigned int i=0; i<num_geoms; i++) {
    	Geometry * gp = geoms[i];

	    if(!gp->calculated_matrices) // if the matrix calculations haven't been calculated, do so now
	    {
			make_transformation_matrix(&gp->matrix, gp->position, gp->orientation, gp->scale);
	        make_inverse_transformation_matrix(&gp->inverse_matrix, gp->position, gp->orientation, gp->scale);
	        make_normal_matrix(&gp->normal_matrix, gp->matrix);
	        gp->calculated_matrices = true; // now they are cached
	    }

		Triangle * tp = dynamic_cast<Triangle*> (geoms[i]);
		Model * mp = dynamic_cast<Model*> (geoms[i]);

		if(tp != NULL) {

			// translate position to global coordinate space
			Vector3 new_position[3];
			Triangle * tri = new Triangle();
			for(int v=0; v<3; v++) {
				new_position[v] = tp->matrix.transform_point(tp->vertices[v].position);
				tri->vertices[v].position = new_position[v];
			}
			add_kdtree_triangle(tri);
		}
		else if(mp != NULL) {

			const MeshTriangle * mesh_triangles = mp->mesh->get_triangles();
			const MeshVertex * mesh_vertices = mp->mesh->get_vertices();

			size_t num_mesh_triangles = mp->mesh->num_triangles();

			for(size_t ti = 0; ti < num_mesh_triangles; ti++) {
				Triangle * tri = new Triangle();
				for(unsigned int v=0; v<3; v++) {
					unsigned int ver_index = mesh_triangles[ti].vertices[v];
					Vector3 position = mesh_vertices[ver_index].position;
					tri->vertices[v].position = mp->matrix.transform_point(position);
				}
				add_kdtree_triangle(tri);
			}

		}
		else {
			std::cout << "Unhandled geometry type";
		}
	}
}


void Kdtree::create_tree(
		int nodeNum,
        const BBox &nodeBounds,
		const std::vector<BBox> &allPrimBounds, int *primNums,
		int nTriangles, int depth, BoundEdge *edges[3],
		int *prims0, int *prims1, int badRefines) {

	// TODO:
	int maxTriangles; // TODO: make private data member of kdtree

	// TODO:
	// write allocation code

	if(nTriangles <= maxTriangles || depth == 0) {
		nodes[nodeNum].initLeaf(primNums, nTriangles,
		                       mailboxPrims, arena); // TODO: define method and specify arguments
		return;
	}

	int bestAxis = -1, bestOffset = -1;
	float bestCost = INFINITY;
	float oldCost = isectCost * float(nTriangles);
	Vector d = nodeBounds.pMax - nodeBounds.pMin; // TODO: decide what to do about Vector
	float totalSA = (2.f * (d.x*d.y + d.x*d.z + d.y*d.z));
	float invTotalSA = 1.f / totalSA;
	
	int axis;
	if(d.x > d.y && d.x > d.z) axis = 0;
	else axis = (d.y > d.z) ? 1 : 2;
	int retries = 0;
	retrySplit:
	// Initialize edges for _axis_
	for (int i = 0; i < nTriangles; ++i) {
		int pn = primNums[i];
		const BBox &bbox = allPrimBounds[pn];
		edges[axis][2*i] =
		    BoundEdge(bbox.pMin[axis], pn, true);
		edges[axis][2*i+1] =
			BoundEdge(bbox.pMax[axis], pn, false);
	}
	std::sort(&edges[axis][0], &edges[axis][2*nTriangles]);
	// Compute cost of all splits for _axis_ to find best
	int nBelow = 0, nAbove = nTriangles;
	for (int i = 0; i < 2*nTriangles; ++i) {
		if (edges[axis][i].type == BoundEdge::END) --nAbove;
		float edget = edges[axis][i].t;
		if (edget > nodeBounds.pMin[axis] &&
			edget < nodeBounds.pMax[axis]) {
			// Compute cost for split at _i_th edge
			int otherAxis[3][2] = { {1,2}, {0,2}, {0,1} };
			int otherAxis0 = otherAxis[axis][0];
			int otherAxis1 = otherAxis[axis][1];
			float belowSA = 2 * (d[otherAxis0] * d[otherAxis1] +
			             		(edget - nodeBounds.pMin[axis]) *
				                (d[otherAxis0] + d[otherAxis1]));
			float aboveSA = 2 * (d[otherAxis0] * d[otherAxis1] +
								(nodeBounds.pMax[axis] - edget) *
								(d[otherAxis0] + d[otherAxis1]));
			float pBelow = belowSA * invTotalSA;
			float pAbove = aboveSA * invTotalSA;
			float eb = (nAbove == 0 || nBelow == 0) ? emptyBonus : 0.f;
			float cost = traversalCost + isectCost * (1.f - eb) *
				(pBelow * nBelow + pAbove * nAbove);
			// Update best split if this is lowest cost so far
			if (cost < bestCost)  {
				bestCost = cost;
				bestAxis = axis;
				bestOffset = i;
			}
		}
		if (edges[axis][i].type == BoundEdge::START) ++nBelow;
	}
	assert(nBelow == nTriangles && nAbove == 0); // NOBOOK
	// Create leaf if no good splits were found
	if (bestAxis == -1 && retries < 2) {
		++retries;
		axis = (axis+1) % 3;
		goto retrySplit;
	}
	if (bestCost > oldCost) ++badRefines;
	if ((bestCost > 4.f * oldCost && nTriangles < 16) ||
		bestAxis == -1 || badRefines == 3) {
		nodes[nodeNum].initLeaf(primNums, nTriangles,
		                     mailboxPrims, arena);
		return;
	}
	// Classify primitives with respect to split
	int n0 = 0, n1 = 0;
	for (int i = 0; i < bestOffset; ++i)
		if (edges[bestAxis][i].type == BoundEdge::START)
			prims0[n0++] = edges[bestAxis][i].primNum;
	for (int i = bestOffset+1; i < 2*nTriangles; ++i)
		if (edges[bestAxis][i].type == BoundEdge::END)
			prims1[n1++] = edges[bestAxis][i].primNum;
	// Recursively initialize children nodes
	float tsplit = edges[bestAxis][bestOffset].t;
	nodes[nodeNum].initInterior(bestAxis, tsplit);
	BBox bounds0 = nodeBounds, bounds1 = nodeBounds;
	bounds0.pMax[bestAxis] = bounds1.pMin[bestAxis] = tsplit;
	create_tree(nodeNum+1, bounds0,
		allPrimBounds, prims0, n0, depth-1, edges,
		prims0, prims1 + nTriangles, badRefines);
	nodes[nodeNum].aboveChild = nextFreeNode;
	create_tree(nodes[nodeNum].aboveChild, bounds1, allPrimBounds,
		prims1, n1, depth-1, edges,
		prims0, prims1 + nTriangles, badRefines);


}

void Kdtree::add_kdtree_triangle( Geometry* g )
{
    kdtree_triangles.push_back( g );
}

Geometry* const* Kdtree::get_kdtree_triangles() const // 545
{
	return kdtree_triangles.empty() ? NULL : &kdtree_triangles[0];
}

size_t Kdtree::num_kdtree_triangles() const
{
    return kdtree_triangles.size();
}

} /* _462 */
