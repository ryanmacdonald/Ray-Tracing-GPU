/**
 * @file material.cpp
 * @brief Material class
 *
 * @author Eric Butler (edbutler)
 */

#include "scene/material.hpp"
#include "application/imageio.hpp"

namespace _462 {

Material::Material():
    ambient( Color3::White ),
    diffuse( Color3::White ),
    specular( Color3::Black ),
    shininess( 10.0 ),
    refractive_index( 0.0 ),
    tex_width( 0 ),
    tex_height( 0 ),
    tex_data( 0 )
{
    tex_handle = 0;
}

Material::~Material()
{
    if ( tex_data ) {
        free( tex_data );
        if ( tex_handle ) {
            glDeleteTextures( 1, &tex_handle );
        }
    }
}

bool Material::load()
{
    // if data has already been loaded, clear old data
    if ( tex_data ) {
        free( tex_data );
        tex_data = 0;
    }

    // if no texture, nothing to do
    if ( texture_filename.empty() )
        return true;

    std::cout << "Loading texture " << texture_filename << "...\n";

    // allocates data with malloc
    tex_data = imageio_load_image( texture_filename.c_str(), &tex_width, &tex_height );
    if ( !tex_data ) {
        std::cerr << "Cannot load texture file " << texture_filename << std::endl;
        return false;
    }

    std::cout << "Finished loading texture" << std::endl;
    return true;
}

const unsigned char* Material::get_texture_data() const
{
    return tex_data;
}

void Material::get_texture_size( int* width, int* height ) const
{
    assert( width && height );
    *width = tex_width;
    *height = tex_height;
}

Color3 Material::get_texture_pixel( int x, int y ) const
{
    return tex_data ? Color3( tex_data + 4 * (x + y * tex_width) ) : Color3::White;
}

bool Material::create_gl_data()
{
    // if no texture, nothing to do
    if ( texture_filename.empty() )
        return true;

    if ( !tex_data ) {
        return false;
    }

    // clean up old texture
    if ( tex_handle ) {
        glDeleteTextures( 1, &tex_handle );
    }

    assert( tex_width > 0 && tex_height > 0 );

    glGenTextures( 1, &tex_handle );
    if ( !tex_handle ) {
        return false;
    }

    glBindTexture( GL_TEXTURE_2D, tex_handle );
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, tex_width, tex_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, tex_data );

    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );

    glBindTexture( GL_TEXTURE_2D, 0 );
    std::cout << "Loaded GL texture" << texture_filename << '\n';
    return true;
}

void Material::set_gl_state() const
{
    float arr[4];
    arr[3] = 1.0; // alpha always 1.0

    // always bind, because if no texture this will set texture to nothing
    glBindTexture( GL_TEXTURE_2D, tex_handle );

    ambient.to_array( arr );
    glMaterialfv( GL_FRONT_AND_BACK, GL_AMBIENT,   arr );
    diffuse.to_array( arr );
    glMaterialfv( GL_FRONT_AND_BACK, GL_DIFFUSE,   arr );
    specular.to_array( arr );
    glMaterialfv( GL_FRONT_AND_BACK, GL_SPECULAR,  arr );
    // make up a shininess term
    glMaterialf( GL_FRONT_AND_BACK, GL_SHININESS, shininess );
}

void Material::reset_gl_state() const
{
    glBindTexture( GL_TEXTURE_2D, 0 );
}

}
