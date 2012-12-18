/**
 * @file main_rayracer.cpp
 * @brief Raytracer entry
 *
 * @author Eric Butler (edbutler)
 */


#include "application/application.hpp"
#include "application/camera_roam.hpp"
#include "application/imageio.hpp"
#include "application/scene_loader.hpp"
#include "application/opengl.hpp"
#include "scene/scene.hpp"
#include "scene/bbox.hpp"
#include "scene/pbrt.h"
#include "raytracer/raytracer.hpp"
#include "scene/kdtree.hpp"

#include <iostream>
#include <cstring>

namespace _462 {

#define DEFAULT_WIDTH 800
#define DEFAULT_HEIGHT 600

#define DEPTH 3
#define SAMPLES 2

#define BUFFER_SIZE(w,h) ( (size_t) ( 4 * (w) * (h) ) )

#define KEY_PRINT_ORI SDLK_p // 545
#define KEY_NORMAL SDLK_t // 545

#define KEY_RAYTRACE SDLK_r
#define KEY_SCREENSHOT SDLK_f

#define KEY_TOGGLE_PARAM SDLK_n
#define NUM_PARAMS 5  
	
#define KEY_ASCEND			SDLK_i
#define KEY_DESCEND			SDLK_k
#define KEY_TOGGLE_CHILD	SDLK_l


bool g_normal_render = false;

int g_child = 0;
int g_depth = 0;

int icost = 80;
int tcost = 1;
int ebonus_percent = 10;
int maxt = 2;
int maxDepth = -1; // let init_tree choose this

int param_sel = 0;
char param_names[][20] = {"intersection cost", "traversal cost", "empty bonus", "max triangles", "max depth"};
int * params[] = {&icost, &tcost, &ebonus_percent, &maxt, &maxDepth};

// pretty sure these are sequential, but use an array just in case
static const GLenum LightConstants[] = {
    GL_LIGHT0, GL_LIGHT1, GL_LIGHT2, GL_LIGHT3,
    GL_LIGHT4, GL_LIGHT5, GL_LIGHT6, GL_LIGHT7
};
static const size_t NUM_GL_LIGHTS = 8;

// renders a scene using opengl
static void render_scene( const Scene& scene , const Kdtree & kdtree);

/**
 * Struct of the program options.
 */
struct Options
{
    // whether to open a window or just render without one
    bool open_window;
    // not allocated, pointed it to something static
    const char* input_filename;
    // not allocated, pointed it to something static
    const char* output_filename;
    // window dimensions
    int width, height;
    // recursion depth
    int depth;
    // n*n samples are used for antialiasing
    int samples;
};

void renderSplit(const Kdtree & kdtree, int nodeNum, Point pMin, Point pMax, int depth);

class RaytracerApplication : public Application
{
public:

    RaytracerApplication( const Options& opt )
        : options( opt ), buffer( 0 ), buf_width( 0 ), buf_height( 0 ), raytracing( false ) { }
    virtual ~RaytracerApplication() { free( buffer ); }

    virtual bool initialize();
    virtual void destroy();
    virtual void update( real_t );
    virtual void render();
    virtual void handle_event( const SDL_Event& event );

    // flips raytracing, does any necessary initialization
    void toggle_raytracing( int width, int height, int depth, int samples );
    // writes the current raytrace buffer to the output file
    void output_image();

    Raytracer raytracer;

    // the scene to render
    Scene scene;

    // the kd tree for 545
    Kdtree kdtree;

    // options
    Options options;

    // the camera
    CameraRoamControl camera_control;

    // the image buffer for raytracing
    unsigned char* buffer;
    // width and height of the buffer
    int buf_width, buf_height;
// true if we are in raytrace mode.
    // if so, we raytrace and display the raytrace.
    // if false, we use normal gl rendering
    bool raytracing;
    // false if there is more raytracing to do
    bool raytrace_finished;
};

bool RaytracerApplication::initialize()
{
    // copy camera into camera control so it can be moved via mouse
    camera_control.camera = scene.camera;
    bool load_gl = options.open_window;

    try {

        Material* const* materials = scene.get_materials();
        Mesh* const* meshes = scene.get_meshes();

        // load all textures
        for ( size_t i = 0; i < scene.num_materials(); ++i ) {
            if ( !materials[i]->load() || ( load_gl && !materials[i]->create_gl_data() ) ) {
                std::cout << "Error loading texture, aborting.\n";
                return false;
            }
        }

        // load all meshes
        for ( size_t i = 0; i < scene.num_meshes(); ++i ) {
            if ( !meshes[i]->load() || ( load_gl && !meshes[i]->create_gl_data() ) ) {
                std::cout << "Error loading mesh, aborting.\n";
                return false;
            }
        }

    } catch ( std::bad_alloc const& ) {
        std::cout << "Out of memory error while initializing scene\n.";
        return false;
    }

	// TODO: move this to some place reasonable
   	kdtree.load_scene(this->scene); // 545: moved to here

   	float ebonus = ebonus_percent / 100.0;
   	kdtree.init_kdtree(icost, tcost,ebonus, maxt, maxDepth);

    // set the gl state
    if ( load_gl ) {
        float arr[4];
        arr[3] = 1.0; // alpha is always 1

        glClearColor(
            scene.background_color.r,
            scene.background_color.g,
            scene.background_color.b,
            1.0f );

        scene.ambient_light.to_array( arr );
        glLightModelfv( GL_LIGHT_MODEL_AMBIENT, arr );

        const PointLight* lights = scene.get_lights();

        for ( size_t i = 0; i < NUM_GL_LIGHTS && i < scene.num_lights(); i++ ) {
            const PointLight& light = lights[i];
            glEnable( LightConstants[i] );
            light.color.to_array( arr );
            glLightfv( LightConstants[i], GL_DIFFUSE, arr );
            glLightfv( LightConstants[i], GL_SPECULAR, arr );
            glLightf( LightConstants[i], GL_CONSTANT_ATTENUATION, light.attenuation.constant );
            glLightf( LightConstants[i], GL_LINEAR_ATTENUATION, light.attenuation.linear );
            glLightf( LightConstants[i], GL_QUADRATIC_ATTENUATION, light.attenuation.quadratic );
        }

        glLightModeli( GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE );
    }

    return true;
}

void RaytracerApplication::destroy()
{

}

void RaytracerApplication::update( real_t delta_time )
{
    if ( raytracing ) {
        // do part of the raytrace
        if ( !raytrace_finished ) {
            assert( buffer );
            raytrace_finished = raytracer.raytrace( buffer, &delta_time );
        }
    } else {
        // copy camera over from camera control (if not raytracing)
        camera_control.update( delta_time );
        scene.camera = camera_control.camera;
    }
}

void RaytracerApplication::render()
{
    int width, height;

    // query current window size, resize viewport
    get_dimension( &width, &height );
    glViewport( 0, 0, width, height );

    // fix camera aspect
    Camera& camera = scene.camera;
    camera.aspect = real_t( width ) / real_t( height );

    // clear buffer
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    // reset matrices
    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();

    if ( raytracing ) {
        // if raytracing, just display the buffer
        assert( buffer );
        glColor4d( 1.0, 1.0, 1.0, 1.0 );
        glRasterPos2f( -1.0f, -1.0f );
        glDrawPixels( buf_width, buf_height, GL_RGBA, GL_UNSIGNED_BYTE, &buffer[0] );

    } else {
        // else, render the scene using opengl
        glPushAttrib( GL_ALL_ATTRIB_BITS );
        render_scene( scene, kdtree );
        glPopAttrib();
    }
}

void RaytracerApplication::handle_event( const SDL_Event& event )
{
    int width, height;

    if ( !raytracing ) {
        camera_control.handle_event( this, event );
    }

//    float ebonus;

	// 545 variables
 	Quaternion q = scene.camera.orientation;
 	Vector3 cam_pos = scene.camera.position;
  	Vector3 v;
	real_t a;
	q.to_axis_angle(&v,&a);

    switch ( event.type )
    {
    case SDL_KEYDOWN:
        switch ( event.key.keysym.sym )
        {
        case KEY_PRINT_ORI:
        	printf("w: %f x: %f y: %f z: %f\n", q.w, q.x, q.y, q.z);
        	printf("a: %f v.x: %f v.y: %f v.z: %f\n",a,v.x,v.y,v.z);
        	printf("x: %f y: %f z: %f\n",cam_pos.x, cam_pos.y, cam_pos.z);
			break;
        case KEY_RAYTRACE:
            get_dimension( &width, &height );
            toggle_raytracing( width, height, options.depth, options.samples );
            break;
        case KEY_NORMAL:
        	g_normal_render = !g_normal_render;
            break;
        case KEY_SCREENSHOT:
            output_image();
            break;
        case KEY_TOGGLE_PARAM:
/*        	param_sel = (param_sel+1) % NUM_PARAMS;
			std::cout << param_names[param_sel] << ": " << *params[param_sel] << std::endl;
			std::cin >> *params[param_sel];
			ebonus = ebonus_percent/100.0;
   			kdtree.init_kdtree(icost, tcost,ebonus, maxt, maxDepth); */
        	break;
        case KEY_DESCEND:
        	g_depth++;
        	break;
        case KEY_ASCEND:
        	if(g_depth > 0)
	        	g_depth--;
        	break;
        case KEY_TOGGLE_CHILD:
        	g_child = 1 - g_child;
        	break;
        default:
            break;
        }
    default:
        break;
    }
}

void RaytracerApplication::toggle_raytracing( int width, int height, int depth, int samples )
{
    assert( width > 0 && height > 0 );

    // do setup if starting a new raytrace
    if ( !raytracing ) {

        // only re-allocate if the dimensions changed
        if ( buf_width != width || buf_height != height ) {
            free( buffer );
            buffer = (unsigned char*) malloc( BUFFER_SIZE( width, height ) );
            if ( !buffer ) {
                std::cout << "Unable to allocate buffer.\n";
                return; // leave untoggled since we have no buffer.
            }
            buf_width = width;
            buf_height = height;
        }

        // initialize the raytracer (first make sure camera aspect is correct)
        scene.camera.aspect = real_t( width ) / real_t( height );

        if ( !raytracer.initialize( &scene, width, height, depth, samples ) ) {
            std::cout << "Raytracer initialization failed.\n";
            return; // leave untoggled since initialization failed.
        }

        // reset flag that says we are done
        raytrace_finished = false;
    }

    raytracing = !raytracing;
}

void RaytracerApplication::output_image()
{
    static const size_t MAX_LEN = 256;
    const char* filename;
    char buf[MAX_LEN];

    if ( !buffer ) {
        std::cout << "No image to output.\n";
        return;
    }

    assert( buf_width > 0 && buf_height > 0 );

    filename = options.output_filename;

    // if we weren't given a file, use a default name
    if ( !filename ) {
        imageio_gen_name( buf, MAX_LEN );
        filename = buf;
    }

    if ( imageio_save_image( filename, buffer, buf_width, buf_height ) ) {
        std::cout << "Saved raytraced image to '" << filename << "'.\n";
    } else {
        std::cout << "Error saving raytraced image to '" << filename << "'.\n";
    }
}


static void render_scene( const Scene& scene, const Kdtree & kdtree )
{
    // backup state so it doesn't mess up raytrace image rendering
    glPushAttrib( GL_ALL_ATTRIB_BITS );
    glPushClientAttrib( GL_CLIENT_ALL_ATTRIB_BITS );

    glClearColor(
        scene.background_color.r,
        scene.background_color.g,
        scene.background_color.b,
        1.0f );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

    glEnable( GL_NORMALIZE );
    glEnable( GL_DEPTH_TEST );
    glEnable( GL_LIGHTING );
    glEnable( GL_TEXTURE_2D );

    // set camera transform

    const Camera& camera = scene.camera;

    glMatrixMode( GL_PROJECTION );
    glLoadIdentity();
    gluPerspective( camera.get_fov_degrees(),
                    camera.get_aspect_ratio(),
                    camera.get_near_clip(),
                    camera.get_far_clip() );

    const Vector3& campos = camera.get_position();
    const Vector3 camref = camera.get_direction() + campos;
    const Vector3& camup = camera.get_up();

    glMatrixMode( GL_MODELVIEW );
    glLoadIdentity();
    gluLookAt( campos.x, campos.y, campos.z,
               camref.x, camref.y, camref.z,
               camup.x,  camup.y,  camup.z );
    // set light data
    float arr[4];
    arr[3] = 1.0; // w is always 1

    scene.ambient_light.to_array( arr );
    glLightModelfv( GL_LIGHT_MODEL_AMBIENT, arr );

    glLightModeli( GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE );

    const PointLight* lights = scene.get_lights();

    for ( size_t i = 0; i < NUM_GL_LIGHTS && i < scene.num_lights(); i++ ) {
        const PointLight& light = lights[i];
        glEnable( LightConstants[i] );
        light.color.to_array( arr );
        glLightfv( LightConstants[i], GL_DIFFUSE, arr );
        glLightfv( LightConstants[i], GL_SPECULAR, arr );
        glLightf( LightConstants[i], GL_CONSTANT_ATTENUATION, light.attenuation.constant );
        glLightf( LightConstants[i], GL_LINEAR_ATTENUATION, light.attenuation.linear );
        glLightf( LightConstants[i], GL_QUADRATIC_ATTENUATION, light.attenuation.quadratic );
        light.position.to_array( arr );
        glLightfv( LightConstants[i], GL_POSITION, arr );
    }

    // render each object

	if(g_normal_render) {
		BBox bounds = kdtree.bounds;
		Point pMin = bounds.pMin;
		Point pMax = bounds.pMax;

		/* Render top level bounding box */

		double p0[3] = {pMin.x, pMin.y, pMin.z};
		double p1[3] = {pMin.x, pMin.y, pMax.z};
		double p2[3] = {pMin.x, pMax.y, pMin.z};
		double p3[3] = {pMin.x, pMax.y, pMax.z};

		double p4[3] = {pMax.x, pMin.y, pMin.z};
		double p5[3] = {pMax.x, pMin.y, pMax.z};
		double p6[3] = {pMax.x, pMax.y, pMin.z};
		double p7[3] = {pMax.x, pMax.y, pMax.z};

		GLenum AABB_render_mode = GL_LINE_LOOP;
	//    GLenum AABB_render_mode = GL_POLYGON;

		glBegin(AABB_render_mode);
			glVertex3dv(p0);
			glVertex3dv(p1);
			glVertex3dv(p3);
			glVertex3dv(p2);
		glEnd();

		glBegin(AABB_render_mode);
			glVertex3dv(p4);
			glVertex3dv(p5);
			glVertex3dv(p7);
			glVertex3dv(p6);
		glEnd();

		glBegin(AABB_render_mode);
			glVertex3dv(p0);
			glVertex3dv(p1);
			glVertex3dv(p5);
			glVertex3dv(p4);
		glEnd();

		glBegin(AABB_render_mode);
			glVertex3dv(p2);
			glVertex3dv(p3);
			glVertex3dv(p7);
			glVertex3dv(p6);
		glEnd();

		renderSplit(kdtree, 0, pMin, pMax, 0);

		Triangle* const* kdtree_triangles = kdtree.get_kdtree_triangles();

		for(size_t i = 0; i < kdtree.num_kdtree_triangles() ; i++) {
			const Triangle& geom = *kdtree_triangles[i];
			geom.render();
		}

		glPointSize(10.0f);
		glBegin(GL_POINTS);
    		for ( size_t i = 0; i < NUM_GL_LIGHTS && i < scene.num_lights(); i++ ) {
	        const PointLight& light = lights[i];
        		light.position.to_array( arr );
				glVertex3f(arr[0], arr[1], arr[2]);
			}
		glEnd();
	}
	else {
		Geometry* const* geometries = scene.get_geometries();

		for ( size_t i = 0; i < scene.num_geometries(); ++i ) {
			const Geometry& geom = *geometries[i];
			Vector3 axis;
			real_t angle;

			glPushMatrix();

			glTranslated( geom.position.x, geom.position.y, geom.position.z );
			geom.orientation.to_axis_angle( &axis, &angle );
			glRotated( angle * ( 180.0 / PI ), axis.x, axis.y, axis.z );
			glScaled( geom.scale.x, geom.scale.y, geom.scale.z );

			geom.render();

			glPopMatrix();
		}
	}

    glPopClientAttrib();
    glPopAttrib();
}


/* render splitting planes*/
void renderSplit(const Kdtree & kdtree, int nodeNum, Point pMin, Point pMax, int depth) {

	float hl[4] = {1.0, 0.0, 0.0, 1.0};
	float no_hl[4] = {0.0, 0.0, 0.0, 1.0};
	if(g_depth == depth)
	    glMaterialfv( GL_FRONT_AND_BACK, GL_AMBIENT,  hl);
	else
	    glMaterialfv( GL_FRONT_AND_BACK, GL_AMBIENT,  no_hl);

    double split = kdtree.nodes[nodeNum].split;
    int flags = kdtree.nodes[nodeNum].flags;

    if((flags & 0x3) == 0x3)
    	return;

    int axis = flags & 0x3;
    int oA0 = (axis+1)%3;
    int oA1 = (axis+2)%3;

	double s0[3], s1[3], s2[3], s3[3];

	s0[axis] = s1[axis] = s2[axis] = s3[axis] = split;

	s0[oA0] = *(&pMin.x + oA0);
	s0[oA1] = *(&pMin.x + oA1);

	s1[oA0] = *(&pMin.x + oA0);
	s1[oA1] = *(&pMax.x + oA1);

	s2[oA0] = *(&pMax.x + oA0);
	s2[oA1] = *(&pMin.x + oA1);

	s3[oA0] = *(&pMax.x + oA0);
	s3[oA1] = *(&pMax.x + oA1);

//	if(g_depth == depth) {
    glBegin(GL_LINE_LOOP);
    	glVertex3dv(s0);
    	glVertex3dv(s1);
    	glVertex3dv(s3);
    	glVertex3dv(s2);
    glEnd();
//	}

	u_int aboveChild = kdtree.nodes[nodeNum].aboveChild;

	bool SAH_flip = kdtree.nodes[nodeNum].sah_flip; // FUCK IT

	float old_pMax = *(&pMax.x + axis);

	*(&pMax.x + axis) = split;
	renderSplit(kdtree, nodeNum+1, pMin, pMax, depth+1);

	*(&pMax.x + axis) = old_pMax;
	*(&pMin.x + axis) = split;
	renderSplit(kdtree, aboveChild, pMin, pMax, depth+1);
}

} /* _462 */

using namespace _462;

/**
 * Prints program usage.
 */
static void print_usage( const char* progname )
{
    std::cout << "Usage: " << progname << " [-r] [-d width height] input_scene [output_file]\n"
        "\n" \
        "Options:\n" \
        "\n" \
        "\t-r:\n" \
        "\t\tRaytraces the scene and saves to the output file without\n" \
        "\t\tloading a window or creating an opengl context.\n" \
        "\t-d width height\n" \
        "\t\tThe dimensions of image to raytrace (and window if using\n" \
        "\t\tand opengl context. Defaults to width=800, height=600.\n" \
        "\t-D depth\n" \
        "\t\tRaytraces with a level of recursion 'depth'." \
        "\tinput_scene:\n" \
        "\t-A samples\n" \
        "\t\tRaytraces with antialiasing using n*n samples." \
        "\t\tThe scene file to load and raytrace.\n" \
        "\toutput_file:\n" \
        "\t\tThe output file in which to write the rendered images.\n" \
        "\t\tIf not specified, default timestamped filenames are used.\n" \
        "\n" \
        "Instructions:\n" \
        "\n" \
        "\tPress 'r' to raytrace the scene. Press 'r' again to go back to\n" \
        "\tgo back to OpenGL rendering. Press 'f' to dump the most recently\n" \
        "\traytraced image to the output file.\n" \
        "\n" \
        "\tUse the mouse and 'w', 'a', 's', 'd', 'q', and 'e' to move the\n" \
        "\tcamera around. The keys translate the camera, and left and right\n" \
        "\tmouse buttons rotate the camera.\n" \
        "\n" \
        "\tIf not using windowed mode (i.e., -r was specified), then output\n" \
        "\timage will be automatically generated and the program will exit.\n" \
        "\n";
}


/**
 * Parses args into an Options struct. Returns true on success, false on failure.
 */
static bool parse_args( Options* opt, int argc, char* argv[] )
{
    int input_index = 1;

    if ( argc < 2 ) {
        print_usage( argv[0] );
        return false;
    }

    if ( strcmp( argv[1], "-r" ) == 0 ) {
        opt->open_window = false;
        ++input_index;
    } else {
        opt->open_window = true;
    }

    if ( argc <= input_index ) {
        print_usage( argv[0] );
        return false;
    }

    // check if it's a -d, if so then get window dimensions
    if ( strcmp( argv[input_index], "-d" ) == 0 ) {
        if ( argc <= input_index + 3 ) {
            print_usage( argv[0] );
            return false;
        }

        // parse window dimensions
        opt->width = -1;
        opt->height = -1;
        sscanf( argv[input_index + 1], "%d", &opt->width );
        sscanf( argv[input_index + 2], "%d", &opt->height );
        // check for valid width/height
        if ( opt->width < 1 || opt->height < 1 ) {
            std::cout << "Invalid window dimensions\n";
            return false;
        }

        input_index += 3;
    } else {
        opt->width = DEFAULT_WIDTH;
        opt->height = DEFAULT_HEIGHT;
    }

    // check if it's -R, if so, get recursion depth
    if ( strcmp( argv[input_index], "-R" ) == 0 ) {
        ++input_index;
        if(argc < input_index + 2) {
            print_usage(argv[0]);
            return false;
        }
        else
            opt->depth = atoi(argv[input_index]);
        ++input_index;
    }
    else
        opt->depth = DEPTH;
    // end of recursion depth argument code

    // check if it's -A, if so, get number of samples
    if ( strcmp( argv[input_index], "-A" ) == 0 ) {
        ++input_index;
        if(argc < input_index + 2) {
            print_usage(argv[0]);
            return false;
        }
        else
            opt->samples = atoi(argv[input_index]);
        ++input_index;
    }
    else
        opt->samples = SAMPLES;
    // end of antialiasing argument code

    opt->input_filename = argv[input_index];

    if ( argc > input_index + 1 ) {
        opt->output_filename = argv[input_index + 1];
    } else {
        opt->output_filename = 0;
    }

    if ( argc > input_index + 3 ) {
        std::cout << "Too many arguments.\n";
        return false;
    }

    return true;
}

int main( int argc, char* argv[] )
{
    Options opt;

    Matrix3 mat;
    Matrix4 trn;
    make_transformation_matrix( &trn, Vector3::Zero, Quaternion::Identity, Vector3( 2, 2, 2 ) );

    make_normal_matrix( &mat, trn );

    if ( !parse_args( &opt, argc, argv ) ) {
        return 1;
    }

    RaytracerApplication app( opt );

    // load the given scene
    if ( !load_scene( &app.scene, opt.input_filename ) ) {
        std::cout << "Error loading scene " << opt.input_filename << ". Aborting.\n";
        return 1;
    }


    // either launch a window or do a full raytrace without one, depending on the option
    if ( opt.open_window ) {


        real_t fps = 30.0;
        const char* title = "15462 Project 4 - Raytracer";
        // start a new application
        return Application::start_application( &app, opt.width, opt.height, fps, title );

    } else {

        app.initialize(); // commented out for 545
        app.toggle_raytracing( opt.width, opt.height, opt.depth, opt.samples );


        if ( !app.raytracing ) {
            return 1; // some error occurred
        }
        assert( app.buffer );
        // raytrace until done
        app.raytracer.raytrace( app.buffer, 0 );
        // output result
        app.output_image();
        return 0;

    }
}

