#include "scene/kdtree.hpp"

namespace _462 {

int max_num_tri_in_leaf = 0;
int sum_leaf_node_tri = 0;

Kdtree::Kdtree()
{
	maxTriangles = 0; // TODO: is this the best thing to do?
}

Kdtree::~Kdtree() { }

void Kdtree::init_kdtree(
//const std::vector<Triangle *> &p,
		int icost, int tcost,
		float ebonus, int maxt, int maxDepth)
{
	isectCost = icost;
	traversalCost = tcost;
	maxTriangles = maxt;
	emptyBonus = ebonus;

	nMax = 0;
	nnMax = 0;

	std::vector<Triangle > prims;
	for(size_t i=0; i < kdtree_triangles.size(); i++)
		prims.push_back(*kdtree_triangles[i]);

	// TODO: figure out what to do for FullyRefine
/*	for (u_int i = 0; i < p.size(); ++i)
		p[i]->FullyRefine(prims); */
	// Initialize mailboxes for _KdTreeAccel_
	curMailboxId = 0;
	nMailboxes = prims.size();
	mailboxPrims = (MailboxPrim *) malloc(nMailboxes *
		sizeof(MailboxPrim));
	for (u_int i = 0; i < nMailboxes; ++i)
		new (&mailboxPrims[i]) MailboxPrim(prims[i]);
	// Build kd-tree for accelerator
	nextFreeNode = nAllocedNodes = 0;
	if (maxDepth <= 0)
		maxDepth =
//		    Round2Int(8 + 1.3f * Log2Int(float(prims.size())));
		    round(8 + 1.3f * log2(float(prims.size())));
	// Compute bounds for kd-tree construction
	std::vector<BBox> primBounds;
	primBounds.reserve(prims.size());
	for (u_int i = 0; i < prims.size(); ++i) {
		BBox b = prims[i].WorldBound();
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

	std::cout << "KDTREE STATS" << std::endl;
	std::cout << "========================" << std::endl;
	std::cout << "maxDepth: " << maxDepth << std::endl;
	std::cout << "num triangles: " << kdtree_triangles.size() << std::endl;
	std::cout << "num of leaf nodes: " << nextFreeNode << std::endl;
	std::cout << "sum of leaf node triangles:" << sum_leaf_node_tri << std::endl;
	std::cout << "max triangles in any leaf node: " << max_num_tri_in_leaf << std::endl;
	std::cout << "nMax: " << nMax << std::endl;
	std::cout << "nnMax: " << nnMax << std::endl;
	std::cout << "========================" << std::endl;

	FILE * kd_bin = fopen("kdtree.bin", "w");
	FILE * kd_txt = fopen("kdtree.txt", "w");
	dump_to_file(kd_bin, kd_txt);
	fclose(kd_bin);
	fclose(kd_txt);

	// Moved freeing down here so that the primNums array is available
	// while dumping to a file
	// Free working memory for kd-tree construction
	delete[] primNums;
	for (int i = 0; i < 3; ++i)
		delete[] edges[i];
	delete[] prims0;
	delete[] prims1;

}

void print_int(FILE * kd_bin, int num, long & byte_cnt) {
	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&num)+(3-i)));
	byte_cnt += 4;
}

void pad_to_4_bytes(FILE * kd_bin, long & byte_cnt) {
	while(byte_cnt % 4 != 0) {
		fprintf(kd_bin,"%c",0);
		(byte_cnt)++;
	}
}

void Kdtree::dump_to_file(FILE * kd_bin, FILE * kd_txt)
{
	long byte_cnt = 0;

	// print scene bounding box to text file
	fprintf(kd_txt,"Min: %f %f %f\n",bounds.pMin.x,bounds.pMin.y,bounds.pMin.z);
	fprintf(kd_txt,"Max: %f %f %f\n",bounds.pMax.x,bounds.pMax.y,bounds.pMax.z);

	// first print the number of nodes in the tree
	long kdtree_size = (nextFreeNode * 1.5) + (nextFreeNode%2);
	print_int(kd_bin, kdtree_size, byte_cnt);
	dump_kdtree(kd_bin, kd_txt, byte_cnt, 0, 0); // then print the tree itself
	pad_to_4_bytes(kd_bin,byte_cnt);
	
	// first print the total number of triangle IDs across all the lists
	long lists_size = (sum_leaf_node_tri * 0.5) + (sum_leaf_node_tri%2);
	print_int(kd_bin, lists_size, byte_cnt);
	fprintf(kd_txt,"sum_leaf_node_tri: %d\n",sum_leaf_node_tri);
	dump_lists(kd_bin, kd_txt, byte_cnt);

	long uttm_size = int_cachelines.size() * 9; // each cacheline is 9 reads
	print_int(kd_bin, uttm_size, byte_cnt);
	dump_uttm(kd_bin, kd_txt, byte_cnt);

	// TODO: uncomment the code below when ready for normals and colors
	long colors_size = kdtree_triangles.size() * 5; // each triangle has 5 reads associated with it
	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&colors_size)+(3-i)));
	byte_cnt += 4;
	dump_colors_and_normals(kd_bin, kd_txt, byte_cnt);

	long aabb_size = 6; // the scene bounding box has 6 32-bit numbers
	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&aabb_size)+(3-i)));
	byte_cnt += 4;
	dump_aabb(kd_bin, kd_txt, byte_cnt);

}

void Kdtree::dump_kdtree(FILE * kd_bin, FILE * kd_txt, long & byte_cnt, int nodeNum, int depth) {

	long flags = nodes[nodeNum].flags;
	flags = flags & 0x3;

	long numTri = nodes[nodeNum].nPrims;
	numTri = numTri >> 2;

	long list_index = nodes[nodeNum].list_index;

	for(int i=0; i < depth; i++)
		fprintf(kd_txt," ");

	unsigned long data = 0;

	if(flags == 0x3) {
		data |= ((flags << 46)     & 0xc00000000000);
		data |= ((list_index << 30) & 0x3fffc0000000);
		data |= ((numTri << 24)     & 0x00003f000000);

		fprintf(kd_txt, "nodeNum: %d leaf. list_index: %ld numTri: %ld (byte_cnt: %ld=0x%lx)\n", nodeNum, list_index, numTri, byte_cnt,byte_cnt);
/*		for(int i=0; i < depth; i++)
			fprintf(kd_txt," ");
		fprintf(kd_txt, "leaf: {leaf node flag: 11, list index: TODO, num triangles: %ld} ", numTri); */
//		fprintf(kd_txt, "%12.12lx",data);
//		fprintf(kd_txt, "\n");

		for(int j = 0; j < 6; j++)
			fprintf(kd_bin,"%c",*(((char*)(&data)+(5-j)))); // most significant byte first!
		byte_cnt += 6;

	}
	else {

		float split = nodes[nodeNum].split;
		int rempty = nodes[nodeNum].rchild_empty ? 1 : 0;
		int lempty = nodes[nodeNum].lchild_empty ? 1 : 0;
		long aboveChild = nodes[nodeNum].aboveChild;

		long split_int = *((int*)(&split));
		long split_28 = split_int >> 4;

		// attempting to make coordinate systems consistent
		if(flags == 0x0)
			flags = 0x1;
		else if(flags == 0x1)
			flags = 0x0;

		data |= ((flags << 46) &     0xc00000000000);
		data |= ((split_28 << 18) &  0x3ffffffc0000);
		data |= ((aboveChild << 2) & 0x00000003fffc);
		data |= ((lempty << 1) &     0x000000000002);
		data |= (rempty &            0x000000000001);

		fprintf(kd_txt, "nodeNum: %d axis: %ld split: %f rempty: %d lempty: %d rnum: %ld (byte_cnt: %ld=0x%lx)\n", nodeNum, flags, split, rempty, lempty, aboveChild, byte_cnt, byte_cnt);
	//	for(int i=0; i < depth; i++)
	//		fprintf(kd_txt," ");
	//	fprintf(kd_txt, "interior: {axis: %ld, split: %f, rchild: %ld, lempty: %d, rempty: %d} ",flags, split, aboveChild, lempty, rempty);
	//	fprintf(kd_txt, "%12.12lx", data);
	//	fprintf(kd_txt, "\n");

		for(int j = 0; j < 6; j++)
			fprintf(kd_bin,"%c",*(((char*)(&data)+(5-j)))); // most significant byte first!
		byte_cnt += 6;


		dump_kdtree(kd_bin, kd_txt, byte_cnt, nodeNum+1, depth+1);
		dump_kdtree(kd_bin, kd_txt, byte_cnt, aboveChild, depth+1);
	}

}

void Kdtree::dump_lists(FILE * kd_bin, FILE * kd_txt, long & byte_cnt) {

	// first print triangle ID table (doing ID by color...)
	fprintf(kd_txt,"triangle table:\n");
	for(unsigned i=0; i<kdtree_triangles.size(); i++) {
		fprintf(kd_txt,"%d: ",i);
		for(size_t j=0; j<3; j++) {
			float amb = (float) kdtree_triangles[i]->vertices[0].material->diffuse[j];
			fprintf(kd_txt,"%f ",amb);
		}
		fprintf(kd_txt,"\n");
	}

	fprintf(kd_txt,"lists:\n");

	// 3 bytes per floating point number (i.e. 24 bits)
	// 12 floating point numbers per triangle

	u_int tri_cnt = 0;
	for(int i=0; i<nextFreeNode; i++) {
		if((nodes[i].flags&0x3) != 0x3) // skip over non-leaf nodes
			continue;

		u_int np = nodes[i].nPrimitives();
		int * primNums = nodes[i].primNumbers;
		fprintf(kd_txt,"node: %d np: %u (bc: %ld=%lx) ",i,np,byte_cnt, byte_cnt);
		for(u_int j=0; j<np; j++) {
			fprintf(kd_txt,"%d ",primNums[j]);
			assert(primNums[j] < (2<<16));
			fprintf(kd_bin,"%c",*((char*)(&(primNums[j]))+1)); // most significant byte first
			fprintf(kd_bin,"%c",*((char*)(&(primNums[j]))+0));
			byte_cnt += 2;
		}
		tri_cnt += np;
		fprintf(kd_txt,"\n");
	}
	assert(tri_cnt == (u_int) sum_leaf_node_tri);

	while(byte_cnt % 4 != 0) {
		fprintf(kd_bin,"%c",0);
		byte_cnt++;
	}
}

void Kdtree::dump_uttm(FILE * kd_bin, FILE * kd_txt, long & byte_cnt) {

	for(unsigned i=0; i < int_cachelines.size(); i++) {
		int_cacheline_t * icl = int_cachelines[i];
		Matrix3 m = icl->matrix;
		Vector3 t = icl->translate;

		// ASCII friendly
		fprintf(kd_txt,"bc: %ld=%lx\n",byte_cnt,byte_cnt);
		fprintf(kd_txt,"%f %f %f %f\n",m._m[0][0], m._m[0][1], m._m[0][2], t.x); 
		fprintf(kd_txt,"%f %f %f %f\n",m._m[1][0], m._m[1][1], m._m[1][2], t.y); 
		fprintf(kd_txt,"%f %f %f %f\n\n",m._m[2][0], m._m[2][1], m._m[2][2], t.x);

/*		if(i==0) {
			printf("%f %f %f %f\n",m._m[0][0], m._m[0][1], m._m[0][2], t.x); 
			printf("%f %f %f %f\n",m._m[1][0], m._m[1][1], m._m[1][2], t.y); 
			printf("%f %f %f %f\n\n",m._m[2][0], m._m[2][1], m._m[2][2], t.x);
		} */

		float m00, m01, m02,
			  m10, m11, m12,
			  m20, m21, m22,
			  tx,  ty,  tz;

		int   m00i, m01i, m02i,
			  m10i, m11i, m12i,
			  m20i, m21i, m22i,
		      txi,  tyi,  tzi;

		m00 = m._m[0][0];  m00i = *((int*)&m00);
		m01 = m._m[0][1];  m01i = *((int*)&m01);
		m02 = m._m[0][2];  m02i = *((int*)&m02);
		m10 = m._m[1][0];  m10i = *((int*)&m10);
		m11 = m._m[1][1];  m11i = *((int*)&m11);
		m12 = m._m[1][2];  m12i = *((int*)&m12);
		m20 = m._m[2][0];  m20i = *((int*)&m20);
		m21 = m._m[2][1];  m21i = *((int*)&m21);
		m22 = m._m[2][2];  m22i = *((int*)&m22);

		tx  = t.x; txi = *((int*)&tx);
		ty  = t.y; tyi = *((int*)&ty);
		tz  = t.z; tzi = *((int*)&tz);

		int a[9];

		a[0] = (m00i & 0xffffff00) | ((m01i >> 24) & 0xff);
		a[1] = ((m01i << 8) & 0xffff0000) | ((m02i >> 16) & 0xffff);
		a[2] = ((m02i << 16) & 0xff000000) | ((m10i >> 8) & 0xffffff);

		a[3] = (m11i & 0xffffff00) | ((m12i >> 24) & 0xff);
		a[4] = ((m12i << 8) & 0xffff0000) | ((m20i >> 16) & 0xffff);
		a[5] = ((m20i << 16) & 0xff000000) | ((m21i >> 8) & 0xffffff);

		a[6] = (m22i & 0xffffff00) | ((txi >> 24) & 0xff);
		a[7] = ((txi << 8) & 0xffff0000) | ((tyi >> 16) & 0xffff);
		a[8] = ((tyi << 16) & 0xff000000) | ((tzi >> 8) & 0xffffff);

		// FUCKING LITTLE ENDIAN
		// oh wait, it's because of hexdump
		// TODO: make sure these bytes are being sent in the right order
		// currently being sent most significant byte first
		for(int j = 0; j < 9; j++) {
			fprintf(kd_bin,"%c",*((((char*)(&a[j]))+3)));
			fprintf(kd_bin,"%c",*((((char*)(&a[j]))+2)));
			fprintf(kd_bin,"%c",*((((char*)(&a[j]))+1)));
			fprintf(kd_bin,"%c",*((((char*)(&a[j]))+0)));
			byte_cnt += 4;
		}

/*		if(i==0) {
			printf("m00: %f\n",m00);
			printf("m00i: %x\n",m00i);
		} */
	}

	while(byte_cnt % 4 != 0) {
		fprintf(kd_bin,"%c",0);
		byte_cnt++;
	}
}

void Kdtree::dump_colors_and_normals(FILE * kd_bin, FILE * kd_txt, long & byte_cnt){

	for(unsigned i=0; i < kdtree_triangles.size(); i++) {
		fprintf(kd_txt,"t%d: (bc: %ld=%lx)\n", i, byte_cnt, byte_cnt);


		for(int j=0; j<3; j++) {
			float amb = (float) kdtree_triangles[i]->vertices[0].material->ambient[j];
			fprintf(kd_txt,"%f ",amb);
			for(int k = 0; k < 3; k++)
				fprintf(kd_bin,"%c",*((char*)(&amb)+3-k));
			byte_cnt += 3;
		}
		fprintf(kd_txt,"\n");

		const unsigned NUM_NORM_PER_TRI = 1; // NOTE: only doing one normal per triangle for now...
		for(unsigned v=0; v < NUM_NORM_PER_TRI; v++) {
			Vector3 norm = kdtree_triangles[i]->vertices[v].normal;
			float xc = (float) norm.x;
			float yc = (float) norm.y;
			float zc = (float) norm.z;
			fprintf(kd_txt,"%f %f %f\n",xc,yc,zc);
			for(int k = 0; k < 3; k++)
				fprintf(kd_bin,"%c",*((char*)(&xc)+3-k));
			for(int k = 0; k < 3; k++)
				fprintf(kd_bin,"%c",*((char*)(&yc)+3-k));
			for(int k = 0; k < 3; k++)
				fprintf(kd_bin,"%c",*((char*)(&zc)+3-k));
			byte_cnt += 9;
		}

		float spec = (float) kdtree_triangles[i]->vertices[0].material->specular[0]; // only doing one component
		for(int k = 0; k < 2; k++)
			fprintf(kd_bin,"%c",*((char*)(&spec)+3-k));
		byte_cnt += 2;
	}

	while(byte_cnt % 4 != 0) {
		fprintf(kd_bin,"%c",0);
		byte_cnt++;
	}
}

void Kdtree::dump_aabb(FILE * kd_bin, FILE * kd_txt, long & byte_cnt) {

	Point pMin = bounds.pMin;
	Point pMax = bounds.pMax;

	fprintf(kd_txt,"bounding box bc: %ld=%lx\n",byte_cnt,byte_cnt);
	fprintf(kd_txt,"xmin: %f\n",pMin.x);
	fprintf(kd_txt,"ymin: %f\n",pMin.y);
	fprintf(kd_txt,"zmin: %f\n",pMin.z);
	fprintf(kd_txt,"xmax: %f\n",pMax.x);
	fprintf(kd_txt,"ymax: %f\n",pMax.y);
	fprintf(kd_txt,"zmax: %f\n",pMax.z);

	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&pMin.y)+(3-i))); // switching x and y
	byte_cnt += 4;

	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&pMin.x)+(3-i))); // switching x and y
	byte_cnt += 4;

	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&pMin.z)+(3-i)));
	byte_cnt += 4;

	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&pMax.y)+(3-i))); // switching x and y
	byte_cnt += 4;

	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&pMax.x)+(3-i))); // switching x and y
	byte_cnt += 4;

	for(int i=0; i<4; i++)
		fprintf(kd_bin,"%c",*((char*)(&pMax.z)+(3-i)));
	byte_cnt += 4;

	while(byte_cnt % 4 != 0) {
		fprintf(kd_bin,"%c",0);
		byte_cnt++;
	}

}

void Kdtree::load_scene(Scene & scene) {
	Geometry* const * geoms = scene.get_geometries();

    size_t num_geoms = scene.num_geometries();

    // put all triangles into one list and perform translations

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
			Triangle * tri = new Triangle();
			for(int v=0; v<3; v++) {
				tri->vertices[v].position = tp->matrix.transform_point(tp->vertices[v].position);
				tri->vertices[v].normal = tp->matrix.transform_vector(tp->vertices[v].normal);
				tri->vertices[v].material = tp->vertices[v].material; // Is this right?
			}
			add_kdtree_triangle(tri);
		}
		else if(mp != NULL) {

			const MeshTriangle * mesh_triangles = mp->mesh->get_triangles();
			const MeshVertex * mesh_vertices = mp->mesh->get_vertices();

			size_t num_mesh_triangles = mp->mesh->num_triangles();

		    if(num_mesh_triangles > 1023) // place an upper bound for limited block RAM in trtr... :(
		    	num_mesh_triangles = 1023;


			for(size_t ti = 0; ti < num_mesh_triangles; ti++) {
				Triangle * tri = new Triangle();
				for(unsigned int v=0; v<3; v++) {
					unsigned int ver_index = mesh_triangles[ti].vertices[v];
					Vector3 position = mesh_vertices[ver_index].position;
					tri->vertices[v].position = mp->matrix.transform_point(position);
					Vector3 normal = mesh_vertices[ver_index].normal;
					tri->vertices[v].normal = mp->matrix.transform_vector(normal);
					tri->vertices[v].material = mp->material;// Is this right?
				}
				add_kdtree_triangle(tri);
			}

		}
		else {
			std::cout << "Unhandled geometry type" << std::endl;
		}
	}

	// create unit triangle transformation matrices (UTTM)

	for(unsigned i=0; i < kdtree_triangles.size(); i++) {

		Triangle * t = kdtree_triangles[i];

		Vector3 v0p = t->vertices[0].position;
		Vector3	v1p = t->vertices[1].position;
		Vector3	v2p = t->vertices[2].position;

		int_cacheline_t * int_cacheline = new int_cacheline_t(v0p, v1p, v2p);
/*		Matrix3 m = int_cacheline.matrix;
		Vector3 tran = int_cacheline.translate;
		printf("%f %f %f %f\n",m._m[0][0], m._m[0][1], m._m[0][2], tran.x); 
		printf("%f %f %f %f\n",m._m[1][0], m._m[1][1], m._m[1][2], tran.y); 
		printf("%f %f %f %f\n",m._m[2][0], m._m[2][1], m._m[2][2], tran.x); */
		int_cachelines.push_back(int_cacheline);
	}

}

void Kdtree::create_tree(
		int nodeNum,
        const BBox &nodeBounds,
		const std::vector<BBox> &allPrimBounds, int *primNums,
		int nTriangles, int depth, BoundEdge *edges[3],
		int *prims0, int *prims1, int badRefines) {

//	std::cout << "in create_tree" << std::endl;

	assert(nodeNum == nextFreeNode); // NOBOOK
	// Get next free node from _nodes_ array
	if (nextFreeNode == nAllocedNodes) {
		int nAlloc = MAX(2 * nAllocedNodes, 512);
		KdtreeNode *n = (KdtreeNode *)malloc(nAlloc *
			sizeof(KdtreeNode));
		if (nAllocedNodes > 0) {
			memcpy(n, nodes,
			       nAllocedNodes * sizeof(KdtreeNode));
			free(nodes);
		}
		nodes = n;
		nAllocedNodes = nAlloc;
	}
	++nextFreeNode;

	if(nTriangles <= maxTriangles || depth == 0) {
		nodes[nodeNum].initLeaf(primNums, nTriangles,
		                       mailboxPrims, arena);
		bool cond1 = (nTriangles <= maxTriangles);
		bool cond2 = (depth == 0);
		if(cond1)
			nMax++;
		else if(cond2)
			nnMax++;
		return;
	}

	int bestAxis = -1, bestOffset = -1;
	float bestCost = INFINITY;
	float oldCost = isectCost * float(nTriangles);
	Vector d = nodeBounds.pMax - nodeBounds.pMin;
	float totalSA = (2.f * (d.x*d.y + d.x*d.z + d.y*d.z));
	float invTotalSA = 1.f / totalSA;

	bool SAH_flip = false;
	
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
			SAH_flip = (aboveSA > belowSA) ? true : false;
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
	if ((bestCost > 4.f * oldCost && nTriangles <= 16) ||
		bestAxis == -1 || badRefines == 3) {
		nodes[nodeNum].initLeaf(primNums, nTriangles,
		                     mailboxPrims, arena);
//		std::cout << "giving up..." << std::endl;
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
	nodes[nodeNum].initInterior(bestAxis, tsplit, n0, n1, SAH_flip);
	BBox bounds0 = nodeBounds, bounds1 = nodeBounds;
	bounds0.pMax[bestAxis] = bounds1.pMin[bestAxis] = tsplit;

	// TODO: use SAH flip... FUCK IT

	create_tree(nodeNum+1, 
		bounds0, allPrimBounds, prims0, n0, depth-1, edges,
		prims0, prims1 + nTriangles, badRefines);
	nodes[nodeNum].aboveChild = nextFreeNode;
	create_tree(nodes[nodeNum].aboveChild,
		bounds1, allPrimBounds, prims1, n1, depth-1, edges,
		prims0, prims1 + nTriangles, badRefines);

}

void Kdtree::add_kdtree_triangle( Triangle* g )
{
    kdtree_triangles.push_back( g );
}

Triangle* const* Kdtree::get_kdtree_triangles() const // 545
{
	return kdtree_triangles.empty() ? NULL : &kdtree_triangles[0];
}

size_t Kdtree::num_kdtree_triangles() const
{
    return kdtree_triangles.size();
}

} /* _462 */
