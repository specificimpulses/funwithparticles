#include <GLES2/gl2.h>
#include <android/log.h>
#include <stdlib.h>
#include "util.h"
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

void printShaderInfoLog(GLuint obj)
{
    int infologLength = 0;
    int charsWritten  = 0;
    char *infoLog;

    glGetShaderiv(obj, GL_INFO_LOG_LENGTH,&infologLength);
    LOGW("shader info log... %i",obj);

    if (infologLength > 0)
    {
        infoLog = (char *)malloc(infologLength);
        glGetShaderInfoLog(obj, infologLength, &charsWritten, infoLog);
	      LOGW("%s\n",infoLog);
        free(infoLog);
    }
}

void printProgramInfoLog(GLuint obj)
{
    int infologLength = 0;
    int charsWritten  = 0;
    char *infoLog;

    glGetProgramiv(obj, GL_INFO_LOG_LENGTH,&infologLength);

    if (infologLength > 0)
    {
        infoLog = (char *)malloc(infologLength);
        glGetProgramInfoLog(obj, infologLength, &charsWritten, infoLog);
	      LOGW("%s\n",infoLog);
        free(infoLog);
    }
}

GLuint make_shader(GLenum type, const char *filename)
{
    GLint length;
    char *source = file_contents(filename, &length);
    GLuint shader;
    GLint shader_ok;
    LOGW("checkpoint 1, filename %s , glErrorCode = %ld",filename,glGetError());

    if (!source)
        return 0;

    LOGW("source:\n%s",source);
    shader = glCreateShader(type);
    LOGW("checkpoint 2, shader =  %i , glErrorCode = %i",shader,glGetError());
    glShaderSource(shader, 1, (const char**)&source, &length);
    free(source);
    LOGW("checkpoint 3, glErrorCode = %ld",glGetError());
    glCompileShader(shader);
    LOGW("checkpoint 4, glErrorCode = %ld",glGetError());

    glGetShaderiv(shader, GL_COMPILE_STATUS, &shader_ok);
    LOGW("checkpoint 4, shader_ok = %i, glErrorCode = %i",shader_ok,glGetError());
    if (!shader_ok) {
        LOGW("Failed to compile %s:\n", filename);
        printShaderInfoLog(shader);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
    //return shader_ok;
}

GLuint make_program(GLuint vertex_shader, GLuint fragment_shader)
{
    GLint program_ok;

    GLuint program = glCreateProgram();

    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    glValidateProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &program_ok);
    LOGW("program = %i, program_ok = %hi, glErrorCode = %i",program,program_ok,glGetError());
    if (!program_ok) {
        LOGW("Failed to link shader program:\n");
        printProgramInfoLog(program);
        glDeleteProgram(program);
        return 0;
    }
    //GLint atpos = glGetAttribLocation(program,"position");
    //LOGW("position attribute : %i, glErrorCode : %i",atpos,glGetError());
    LOGW("shader program linked OK!");
    return program;
}



