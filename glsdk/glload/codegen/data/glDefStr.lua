--[[
This file returns a string that represents the standard typedefs that gl.spec does not include.
]]

return [[

#ifndef GLLOAD_BASIC_OPENGL_TYPEDEFS
#define GLLOAD_BASIC_OPENGL_TYPEDEFS

typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef unsigned int GLbitfield;
typedef signed char GLbyte;
typedef short GLshort;
typedef int GLint;
typedef int GLsizei;
typedef unsigned char GLubyte;
typedef unsigned short GLushort;
typedef unsigned int GLuint;
typedef float GLfloat;
typedef float GLclampf;
typedef double GLdouble;
typedef double GLclampd;
#define GLvoid void

#endif //GLLOAD_BASIC_OPENGL_TYPEDEFS
]]
