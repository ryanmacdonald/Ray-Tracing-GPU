Trav unit spec.
This unit will be instantiated multiple times
Interfaces with Shader(s) from above via an arbiter
Interfaces with LNT units from below via an arbiter

This unit performs the kd traversal with Small stack.

ASSUMPTIONS:
Shadow rays origin is always contained within the scenes bounding box
but the light may be located out the scenes bounding box. 
  This imples that for shadow rays, TmaxRay is min(TsceneMax, 1)
  This implies that TminRay = 0.

Relective Rays:
  T


For the current node  you will have the node's Tmin and Tmax value and the scene's Tmax (Tmaxscene) 
along with the original ray and direction (origin, dir).




Initialization of new ray.
//Find Tmaxscene and Tminscene using a ray/AABB intersection
if(shadow ray)
  Tmaxray = min(TsceneMax, 1);
  Tminray = 0
else if misses scene AABB)
  return no_intersection;
else // primary/reflective ray
  Tmaxray = Tmaxscene;
  Tminray = Max(Tminscene, 0);



--------------------------- Traverse_node(cur_node,Tmax,Tmin)--------------------------

if(not a leaf node)
  do an intersection with the splitting plane and call that value Tmid. 
  Based off of comparisons between Tmid, Tmin, Tmax, (and maybe origin/dir)
  determine how to traverse the children nodes(Ca then Cb or just Ca).  
  if(Ca then Cb) 
    Push Cb onto short-stack (potentially kicking off first element but that is fine)
    Pushing => pushing node addr and tmin/tmax values
  create the new Tmin and Tmax (based off current Tmid, Tmin, Tmax)
  traverse(Ca,Tmax,Tmin)

if(is a leaf node)
  Do intersection tests with all the triangles in the leaf (send to LNT units)
  if(intersection) 
    Clear stack and return point of intersection
  else //missed all triangles in leaf node
    if(Tmax == Tmaxscene)
      Clear stack and return lack of intersection
    else If(stack is not empty)
      pop off node from stack
      Traverse(node,Tmax,Tmin)
    else // stack is empty
      Tmin = Tmax;
      Tmax = Tmaxscene;
      Traverse(top_node,Tmax,Tmin)
--------------------------end traversal function --------------------------------


Some things to note. 
  -This requires lots of memory accsesses, so use the swap bit algorithm for better cache hits
  -Start traversing a node to a leaf node before previous node returns might be a good idea (although bandwidth issues)
  -Every traversal unit will have a LNT unit at its disposal.



