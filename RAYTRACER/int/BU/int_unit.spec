This is the spec for a generic intersection unit.

Inputs:
  Ray
  TriID

Outputs:
  no_intersection
  Tintersect
  bari_u
  bari_v




function Intersection(Ray r, TriID)

  //Get from memory Matrix M (3x3)
  //translation Tr (3x1);
  //triangle Normal N

  new_origin = (M x r.origin) + N;
  new_dir = (M x r.dir);

  Tintersect =  - new_origin.z / new_dir.z;
  bari_u = new_origin.x + Tintersect * new_dir.x;
  bari_v = new_origin.y + Tintersect * new_dir.y;
  
  if(bari_u > 0 && bari_v > 0 && bari_u + bari_v < 1)
    no_intersection = 0;
  else no_intersection = 1;

  Return 



endfunction



