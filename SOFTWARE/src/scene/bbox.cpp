#include "scene/bbox.hpp"


BBox Union(const BBox &b, const Point &p) {
	BBox ret = b;
	ret.pMin.x = MIN(b.pMin.x, p.x);
	ret.pMin.y = MIN(b.pMin.y, p.y);
	ret.pMin.z = MIN(b.pMin.z, p.z);
	ret.pMax.x = MAX(b.pMax.x, p.x);
	ret.pMax.y = MAX(b.pMax.y, p.y);
	ret.pMax.z = MAX(b.pMax.z, p.z);
	return ret;
}
BBox Union(const BBox &b, const BBox &b2) {
	BBox ret;
	ret.pMin.x = MIN(b.pMin.x, b2.pMin.x);
	ret.pMin.y = MIN(b.pMin.y, b2.pMin.y);
	ret.pMin.z = MIN(b.pMin.z, b2.pMin.z);
	ret.pMax.x = MAX(b.pMax.x, b2.pMax.x);
	ret.pMax.y = MAX(b.pMax.y, b2.pMax.y);
	ret.pMax.z = MAX(b.pMax.z, b2.pMax.z);
	return ret;
}


