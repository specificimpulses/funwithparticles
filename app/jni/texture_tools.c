#include <GLES2/gl2.h>
#include <android/log.h>
#include <stdlib.h>
#include "util.h"
#include "SOIL.h"
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

GLuint make_texture(const char *filename)
{
    int my_width, my_height;
    void *pixels = read_tga(filename, &my_width, &my_height);
    GLuint texture;

    LOGW("..texture image width = %i",&my_width);
    LOGW("..texture image height = %i",&my_height);

    if (!pixels)
        LOGW("..no pixels read from texture image!");
        return 0;

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE);
    glTexImage2D(
        GL_TEXTURE_2D, 0,           /* target, level */
        GL_RGB,                    /* internal format */
        my_width, my_height, 0,           /* width, height, border */
        GL_RGB, GL_UNSIGNED_BYTE,   /* external format, type */
        pixels                      /* pixels */
    );
    free(pixels);
    return texture;
}

GLuint make_soil_texture(const char *filename)
{
  GLuint texture = SOIL_load_OGL_texture
	(
		filename,
		SOIL_LOAD_AUTO,
		SOIL_CREATE_NEW_ID,
		SOIL_FLAG_INVERT_Y
	);
  return texture;
}

