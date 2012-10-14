This is the shader unit.  This is responsible for computing the color of a pixel given a primary ray from the ray generator.
It will need to
  do complex color computations based off of triangleIDs and points of intersections and lights.
  Generate new rays based off of point of intersection and normals.



"Data structures"
intersection {
  no_intersection,
  triID.
  is_specular
  P
  alpha
  beta
}  



"Globals"
Max_reflect

function Get_pixel_color(Primary_ray,pixID) 
  Constant = 0;
  Multiplier = 1;
  cur_intersection = traverse(Primary_ray,~is_shadow);
  if(cur_intersection.is_hit == FALSE) {
    return background_color
  }

  for(int i=0; i<max_reflect; i++) {
    shade_info = Shade_ray(cur_intersection)
    reflect_intersection = shade_info.reflect_intersection;
    Constant += Multiplier*shade_info.Diffuse_color;
    Multiplier *= shade_info.Reflect_constant;
    if(reflect_intersection.is_hit == FALSE) {
      return Constant + Multiplier * Background_color;
    }
  }
  return Constant + Multiplier

endfunction





"Globals"
Background Color
Number of lights
Lights( position,diffuse color) (Stored in light data structure??)
Ambient Light

function Shade_ray(Intersection intersect)
  
  // Do the following things in parallel
  //   Light Rays
  //   Reflective Ray
  //   Get Texture Color


  ///////////////////// Light Rays ///////////////////

  Direct_illum = ambient_light * ambient_material;
  Diffuse_color = calc_diffuse_color(intersection);

  Foreach Light {// SHOULD BE DONE AS PARALELL AS POSSIBLE
    light_dir = Light - intersect.P;
    if(dot(Normal, light_dir) > 0) {
      Light_ray.dir = light_dir;
      Light_ray.origin = intersect.P + epsilon * light_dir;
      L_intersect = traverse(Light_ray, is_shadow) // inherently uses Tmax =1, Tmin=0
      if(!L_intersect.no_intersection){ // there was an intersection
        Direct_illum += Light.color * Diffuse_color;
      }
    }

  }
  
  
  ///////////////// Reflective Ray //////////////
  //Calculate Normal at point of intersection
  //This could be either the Triangle''s normal or interpelated normal
  
  if(intersection.is_specular)
    Normal = get_Normal(intersect.P);
    Reflect_ray.dir = reflect(radience_ray.dir, Normal);
    Reflect_ray.orig = intersect.P + epsilon * Reflect_ray.dir;
    reflect_intersection = traverse(Reflect_ray, ~is_shadow) // inherently uses Scene Tmax/Tmin


  ///////////////////// Texture ////////////////////
  Get the freakin texture color at this point
  Texture_color;
  Probably a good deal of effort needs to be done to get this working properly


  /////////////////////////////////////////////
  // ALl the parallel things should be done. //
  Diffuse_color *= Texture_color
  Reflect_constant = Texture_color * Triangle.Specularity;

  //Return these values as shade_info:
    reflect_intersection
    Diffuse_color
    Reflect_constant

endfunction


