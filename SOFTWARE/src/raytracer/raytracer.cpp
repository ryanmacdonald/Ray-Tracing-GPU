/**
 * @file raytacer.cpp
 * @brief Raytracer class
 *
 * Implement these functions for project 2.
 *
 * @author H. Q. Bovik (hqbovik)
 * @bug Unimplemented
 */

#include "raytracer.hpp"
#include "scene/scene.hpp"

#include <SDL/SDL_timer.h>
#include <iostream>
#include <stack>


namespace _462 {

Raytracer::Raytracer()
    : scene( 0 ), width( 0 ), height( 0 ), depth( 0 ) { }

Raytracer::~Raytracer() { }

/**
 * Initializes the raytracer for the given scene. Overrides any previous
 * initializations. May be invoked before a previous raytrace completes.
 * @param scene The scene to raytrace.
 * @param width The width of the image being raytraced.
 * @param height The height of the image being raytraced.
 * @param depth The recursion depth.
 * @return true on success, false on error. The raytrace will abort if
 *  false is returned.
 */
bool Raytracer::initialize( Scene* scene, size_t width, size_t height, int depth, int samples )
{
    this->scene = scene;
    this->width = width;
    this->height = height;
    this->depth = depth;
    this->samples = samples;

    current_row = 0;

    return true;
}

/**
 * Determines the nearest intersection in the scene with the given ray by iterating through the geometries
 * and calling their intersect test functions.
 * @param scene The scene into which to cast a ray.
 * @param ray_position The initial position of the ray being cast.
 * @param ray_direction The direction of the ray being cast.
 * @return The data structure containing the intersection data.
 */
static IntersectionData intersection_test(const Scene * scene, Vector3 ray_position, Vector3 ray_direction)
{
    Geometry * const * geometries = scene->get_geometries();
    size_t num_geometries = scene->num_geometries();

    IntersectionData closest_intersection, intersection;
    closest_intersection.was_intersection = false; // assume no intersections until finding one

    for(size_t g=0; g<num_geometries; g++)
    {
        intersection = geometries[g]->intersection_test(ray_position, ray_direction);
        // if there was an intersection with geometry g,
        // and it either is the first intersection or occurred closer than the current closest recorded intersection,
        // then it is the newest closet recorded intersection
        if( intersection.was_intersection && (!closest_intersection.was_intersection or intersection.time <= closest_intersection.time) )
            closest_intersection = intersection;
    }
    return closest_intersection;
}

/**
 * Calculates the lighting due to direct illumination at the specified point of intersection.
 * @param scene The scene which contains lighting information.
 * @param ray_position The initial position of the ray being cast.
 * @param ray_direction The direction of the ray being cast.
 * @param intersection The data of intersection. Includes the normal, as well as the ambient, diffuse, and specular components.
 * @param epsilon The small distance from which to start shadow rays away from the surface.
 * @return The color at the point of intersection due to direct lighting.
 */
static Color3 direct_illumination(const Scene * scene, Vector3 ray_position, Vector3 ray_direction, IntersectionData intersection, real_t epsilon)
{
    Vector3 p = ray_position + intersection.time*ray_direction; // point of nearest intersection in world coordinates
    Vector3 V = ray_direction; // viewer ray direction
    Vector3 N = intersection.normal; // normal vector on nearest intersected object at point of intersection

    Color3 sum_diffuse_terms = Color3(0.0,0.0,0.0); // start out at 0 in all colors and accumulate light in for loop
    size_t num_lights = scene->num_lights();
    const PointLight* lights = scene->get_lights();

    Color3 k_a = intersection.ambient; // ambient color at point of intersection
    Color3 k_d = intersection.diffuse; // diffuse color at point of intersection

    for(size_t l = 0; l < num_lights; l++) // iterate through all of the lights calculating the contribution from each
    {
        Color3 c = lights[l].color;
        Vector3 L = lights[l].position - p; // vector pointing from p to the light l
        real_t d = length(L); // distance to light l from point of intersection
        L = normalize(L); // needed to make N_dot_L equal to cos theta

        bool b_l = true; // assume we can see the light from here until we intersect with an object
        IntersectionData shadow = intersection_test(scene, p + epsilon * N, L); // shadow ray (start a little bit away from the surface)
        if(shadow.was_intersection && shadow.time < d) // there was an intersection with an object closer than light l
            b_l = false;
        if(!b_l) // the light l is obstructed
            continue; // move onto the next light; there is no contribution from this one
        real_t N_dot_L = dot(N,L); // dot normal with light vector
        if(N_dot_L < 0) // the surface is facing away (add no diffuse term for this light)
           continue;

        real_t a_c = lights[l].attenuation.constant;
        real_t a_l = lights[l].attenuation.linear;
        real_t a_q = lights[l].attenuation.quadratic;

        Color3 c_l = c * (1.0/(a_c + d*a_l + d*d*a_q)); // from handout

        Color3 diffuse_term = c_l * k_d * N_dot_L; // from handout
        sum_diffuse_terms += diffuse_term; // keep a running total of the diffuse terms
    }

    Color3 t_p = intersection.texture_pixel;
    Color3 c_a = scene->ambient_light;

    Color3 c_p = t_p*(c_a*k_a + sum_diffuse_terms); // direct illumination color at point of intersection -- from handout
    return c_p;
}

/*
 * This is just a small function for calculating R in Schlick's approximation
 */
static real_t calc_R(real_t n_t, real_t d_dot_N)
{
    real_t R0_root = (n_t - 1.0)/(n_t + 1.0);
    real_t R0 = R0_root * R0_root;
    real_t R = R0;
    if(d_dot_N > 0) // ray is exiting the dielectric
        R += (1.0-R0)*pow(1.0-d_dot_N,5);
    else            // ray is entering the dielectric
        R += (1.0-R0)*pow(1.0+d_dot_N,5);
    return R;
}

/**
 * Casts a ray out into the scene and returns the color of the 
 * object it intersects with (which in turn requires a call to itself).
 * @param scene The scene into which to cast a ray.
 * @param ray_position The initial position of the ray being cast.
 * @param ray_direction The direction of the ray being cast.
 * @param depth The recursion depth to take.
 * @return The color of the surface intersected by the ray (or background color if no intersection).
 */
static Color3 cast_ray(const Scene * scene, Vector3 ray_position, Vector3 ray_direction, int depth)
{
    IntersectionData closest_intersection = intersection_test(scene, ray_position, ray_direction); // find the closest intersection this ray makes

    if(!closest_intersection.was_intersection) // no intersection occurred with any of the geometries
        return scene->background_color;

    Vector3 p = ray_position + closest_intersection.time*ray_direction; // calculate the point of nearest intersection in world coordinates
    Vector3 V = ray_direction; // viewer ray direction
    Vector3 N = closest_intersection.normal; // normal vector on nearest intersected object at point of intersection

    real_t epsilon = 0.001; // the slop factor
    real_t n_t = closest_intersection.refractive_index;
    Color3 color;
    if(n_t == 0) // only calculate the direct illumination if the object is opaque
        color = direct_illumination(scene, ray_position, ray_direction, closest_intersection, epsilon);

    if(depth == 0) // we're at the end of recursion so just return the color
    {
        if(n_t != 0) // for transparent objects, just return black (they don't have a color, and black adds nothing)
            return Color3::Black;
        else
            return color;
    }

    // beginning code for reflection
    Vector3 reflected_ray_direction = V - 2*(dot(V,N)*N);
    Vector3 reflected_ray_position = p + reflected_ray_direction * epsilon;
    Color3 reflected_color;
    if(closest_intersection.specular == Color3::Black) // if there is no specularity, don't bother sending off a reflected ray
        reflected_color = Color3::Black;
    else  // otherwise, cast a reflected ray and get the color there
        reflected_color  = cast_ray(scene, reflected_ray_position, reflected_ray_direction, depth-1);
    Color3 t_p = closest_intersection.texture_pixel;
    reflected_color *= closest_intersection.specular * t_p;
    // end of code for reflection

    if(n_t == 0) // if the object is opaque, don't bother with calculating refraction
        return color + reflected_color;

    // beginning of refraction code
    Vector3 d = ray_direction;
    real_t n = scene->refractive_index;

    real_t d_dot_N = dot(d,N);
    bool entering = d_dot_N < 0; // true if entering dielectric, false otherwise

    if(!entering) // ray is exiting; swap refractive indices
    {
        n = n_t;
        n_t = scene->refractive_index;
    }

    real_t sqrt_term = 1.0-n*n*(1.0- d_dot_N*d_dot_N)/(n_t*n_t); // term under the radical in the calculation of the refraction vector
    if(sqrt_term < 0) // total internal reflection
        return reflected_color;

    Vector3 refracted_ray_direction;
    if(entering)    // ray is entering dielectric
        refracted_ray_direction = n*(d - N*d_dot_N)/n_t - N*sqrt(sqrt_term);
    else            // ray is exiting dielectric (negate the normal)
        refracted_ray_direction = n*(d + N*-d_dot_N)/n_t + N*sqrt(sqrt_term);

    Vector3 refracted_ray_position = p + refracted_ray_direction * epsilon;
    Color3 refracted_color = cast_ray(scene, refracted_ray_position, refracted_ray_direction, depth-1); // cast a ray into or out from the dielectric
    refracted_color *= closest_intersection.specular * t_p;

    real_t R = calc_R(n_t, d_dot_N);
    color = R*reflected_color + (1.0-R)*refracted_color; // Schlick approximation -- from handout
    return color;
}

/**
 * Performs a raytrace on the given pixel on the current scene.
 * The pixel is relative to the bottom-left corner of the image.
 * @param scene The scene to trace.
 * @param x The x-coordinate of the pixel to trace.
 * @param y The y-coordinate of the pixel to trace.
 * @param width The width of the screen in pixels.
 * @param height The height of the screen in pixels.
 * @param depth The recursion depth.
 * @return The color of that pixel in the final image.
 */

// 545 stuff
Color3 * color_matrix;
bool * pixel_done;

static Color3 trace_pixel( const Scene* scene, size_t x, size_t y, size_t width, size_t height, int depth, int samples )
{
    assert( 0 <= x && x < width );
    assert( 0 <= y && y < height );

	static bool color_matrix_initialized = false;

    // 545
    int xs = width/20;
    int ys = height/15;
//    x = xs*(x/xs); // + xs/2;
//    y = ys*(y/ys); // + ys/2;

	if(!color_matrix_initialized) {
		color_matrix = (Color3*) malloc(sizeof(Color3)*width*height);
		pixel_done =(bool *) malloc(sizeof(bool)*width*height);
		for(size_t i=0; i<height; i++) {
			for(size_t j=0; j<width; j++)
				pixel_done[i*width + j] = false;
		}
		color_matrix_initialized = true;
	}

	if(pixel_done[y*width + x]) {
		return color_matrix[y*width+ x];
	}

    // the camera basis vectors
    Vector3 w = scene->camera.get_direction();
    Vector3 v = scene->camera.get_up();
    Vector3 u = cross(w,v);

    // get some camera variables
    real_t near_plane_distance = scene->camera.get_near_clip();
    real_t fov_radians = scene->camera.get_fov_radians();
    real_t aspect_ratio = scene->camera.get_aspect_ratio();

    // calculate the size of near plane in world units
    real_t near_plane_height = 2*near_plane_distance*tan(fov_radians/2);
    real_t near_plane_width = near_plane_height * aspect_ratio;

    Vector3 ray_position = scene->camera.get_position(); // initial position of ray

    Color3 color = Color3::Black;

    int n = samples;

    for(int p=0; p < n; p++)
    {
        for(int q=0; q < n; q++)
        {
            // calculate how far across and up the screen the pixel x,y is
            real_t percent_up_screen = (y+(real_t)p/n)/height;
            real_t percent_across_screen = (x+(real_t)q/n)/width;

            // these vectors are in the plane of the near plane. we need to add them to the camera direction to get the
            // direction of the ray passing from camera position through the pixel x,y
            Vector3 horizontal_screen_component = near_plane_width * (percent_across_screen - 0.5) * u;
            Vector3 vertical_screen_component = near_plane_height * (percent_up_screen - 0.5) * v;

            Vector3 ray_direction = near_plane_distance * w;
            ray_direction += horizontal_screen_component;
            ray_direction += vertical_screen_component;
            ray_direction = normalize (ray_direction);

            color += cast_ray(scene, ray_position, ray_direction, depth);
        }
    }

    color_matrix[y*width + x] = color * (1.0/(n*n)); // 545
    pixel_done[y*width + x] = true; // 545

    return color * (1.0/(n*n));
}

/**
 * Raytraces some portion of the scene. Should raytrace for about
 * max_time duration and then return, even if the raytrace is not copmlete.
 * The results should be placed in the given buffer.
 * @param buffer The buffer into which to place the color data. It is
 *  32-bit RGBA (4 bytes per pixel), in row-major order.
 * @param max_time, If non-null, the maximum suggested time this
 *  function raytrace before returning, in seconds. If null, the raytrace
 *  should run to completion.
 * @return true if the raytrace is complete, false if there is more
 *  work to be done.
 */
bool Raytracer::raytrace( unsigned char *buffer, real_t* max_time )
{
    // TODO Add any modifications to this algorithm, if needed.

    static const size_t PRINT_INTERVAL = 64;

    // the time in milliseconds that we should stop
    unsigned int end_time = 0;
    bool is_done;

    if ( max_time ) {
        // convert duration to milliseconds
        unsigned int duration = (unsigned int) ( *max_time * 1000 );
        end_time = SDL_GetTicks() + duration;
    }

    // until time is up, run the raytrace. we render an entire row at once
    // for simplicity and efficiency.
    for ( ; !max_time || end_time > SDL_GetTicks(); ++current_row ) {

        if ( current_row % PRINT_INTERVAL == 0 ) {
            printf( "Raytracing (row %u)...\n", current_row );
        }

        // we're done if we finish the last row
        is_done = current_row == height;
        // break if we finish
        if ( is_done )
            break;

        for ( size_t x = 0; x < width; ++x ) {
            // trace a pixel
            Color3 color = trace_pixel( scene, x, current_row, width, height, depth, samples );
            // write the result to the buffer, always use 1.0 as the alpha
            color.to_array( &buffer[4 * ( current_row * width + x )] );
        }
    }

    if ( is_done ) {
        printf( "Done raytracing!\n" );
    }

    return is_done;
}

} /* _462 */

