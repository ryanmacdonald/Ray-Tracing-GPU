/**
 * @file opengl.hpp
 * @brief Includes the correct opengl header files depending on the
 *  platform. Use this file to include any gl header files.
 */

#ifndef _462_OPENGL_HPP_
#define _462_OPENGL_HPP_

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#endif

#ifdef _462_USING_GLEW
#include <GL/glew.h>
#endif

#define NO_SDL_GLEXT
#include <SDL/SDL_opengl.h>

#endif /* _462_OPENGL_HPP_ */

