================================================================================
* Project README                                                               *
================================================================================
* Paul Kennedy                                                                 *
* Ross Daly                                                                    *
* Ryan Macdonald                                                               *
================================================================================

SYNTHESIS INSTRUCTIONS
================================================================================
In order to synthesize correctly, do the following:
* Move COMMON files to top of file list in Quartus
* Uncomment `define SYNTH in structs file
* Add `default_nettype wire to alt_mf.v (make this permanent?)
* Comment out any unions (TODO: figure out another solution to unions)

TODO:
================================================================================
* Change to 16 bit color
* Implement double frame buffer
* Determine the cause of the random wrong pixels for t32
* Write caches and cache miss handlers
* Write arbiters (T-arb, L-arb. others?)
* Continue generating scene file


Byte arrangement in files, serial, and memory
================================================================================

Files:
--------------

B0 B1 B2 B3 ...

i.e. if you do:

	while((i = fgetc()) != EOF) {
		printf("%c",i);
	}

You will see the characters for: B0, B1, B2, ...
Use hexdump as follows for viewing contents as they will be transferred:

hexdump -C foo.bin

XMODEM:
--------------
Time:  00 01 02 03 04 ...
Data:  B0 B1 B2 B3 B4 ...

SDRAM:
--------------
Data bus [31:0]: {B3, B2, B1, B0}

SRAM:
--------------
Data bus [15:0]: {B0, B1}

Addr Data
0000 {B0, B1}
0001 {B2, B3}

Ray Tracing Algorithm Pseudo-Code
================================================================================

void raytrace(Scene* scene) {
	for(row = 0; row < num_rows; row++)
		for(col = 0; col < num_cols; col++)
			trace_pixel(scene, col, row, width, height, depth)
}

Color3 trace_pixel(Scene * scene, int col, int row, int width, int height, int depth) {

	// calculate ray position and direction from screen data
	Vector3 ray_position = ();
	Vector3 ray_direction = ();

	// anti-aliasing can be done here by taking multiple samples per pixel and
	// averaging the colors e.g. put the cast_ray in a double for loop which
	// collects colors from a grid of samples for each pixel
	return cast_ray(scene, ray_position, ray_direction, depth);

}

Color3 cast_ray(Scene * scene, Vector3 ray_position, Vector3 ray_direction, int depth) {

	IntersectionData closest_intersection = intersection_tests(scene, ray_position, ray_direction);
	
	// there may not actually be any intersection at all
	if(!closest_intersection.was_intersection)
		return scene->background_color;

	// find point of intersection in 3d space, and extract ray direction and normal vector
	Vector3 p = ray_position + closest_intersection.time * ray_direction;
	Vector3 V = ray_direction;
	Vector3 N = closest_intersection.normal;

	real_t epsilon = 0.001; // the slop factor -- prevents immediate reintersection

	// extract some data about the intersection
	real_t n_t = closest_intersection.refractive_index;	
	real_t specular = closest_intersection.specular;
	Color3 t_p = closest_intersection.texture_pixel;
	bool opaque = (n_t == 0);

	Color3 direct_color;
	// find the color at point of intersection due to direct illumination
	if(opaque) // if the object is opaque
		direct_color = direct_illumination(scene, ray_position, ray_direction, closest_intersection, epsilon);

	// we are at the bottom of our recursion
	if(depth == 0)
		return (opaque)? direct_color : Color3::Black;

	Vector3 reflected_ray_direction = ();
	Vector3 reflected_ray_position = ();
	Color3 reflected_color;

	if(specular == Color3::Black) // if the object is not shiny, add nothing for reflection
		reflected_color = Color3::Black;
	else
		reflected_color = cast_ray(scene, reflected_ray_position, reflected_ray_direction, depth-1);
	reflected_color *= specular * t_p;

	if(opaque)
		return direct_color + reflected_color;

	// refraction code. Here be Dragons...

}

Color3 direct_illumination() {

	for(l = 0; l < num_lights; l++) {

		c = ;
		L = 
		d = 

		Color3 diffuse_term = c_l * k_d * N_dot_L;
		sum_diffuse_terms += diffuse_term;

	}

	Color3 c_p = t_p*(c_a*k_a _ sum_diffuse_terms);
	return c_p;
}
