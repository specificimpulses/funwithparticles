/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// OpenGL ES 2.0 code

#include <jni.h>
#include <android/log.h>

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <android/sensor.h>
#include "SOIL.h"
#include <android/asset_manager.h>
#include <android/asset_manager_jni.h>
#include <android/bitmap.h>

#define  LOG_TAG    "libgl2jni"
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)

extern "C" float fortran_color();
extern "C" void setup_particle_engine(int,int);
extern "C" void update_particle_engine();
extern "C" void update_accel(float,float,int);
extern "C" void update_nparticles(int,int);
extern "C" void update_touch(float,float,int);
extern "C" void enable_gravity(bool);
extern "C" void enable_touch(bool);
extern "C" float *c_pointxy, *c_pointcolor;
extern "C" void set_gravity(float);
extern "C" void set_attract(float);
JNIEnv* jEnv;
int useSystemBackground;
AAssetManager* pAssetManager;
GLuint createProgram(const char*, GLint, const char*, GLint);
void fillBackgroundBuffer();
float xOffset, yOffset, xStep, yStep;
int xPixels, yPixels;
int width, height;
float pScale;
int checkParticleNum, checkParticleSize;

#define PI 3.14159265
#define d2r PI/180.0
int nParticles;
int particleSize;
int screenRotation = 0;
float opacity = 1.0;
// prototype for the drawArrow function
void drawArrow(float,float,float,float,int);
void drawParticles();
void drawBackground();
jobject theBitmap;
int wpWidth, wpHeight;
float wpAspect, screenAspect;

typedef struct
{
	float r,g,b;
}rgbcolor;

static rgbcolor bcolor;


static void printGLString(const char *name, GLenum s) {
    const char *v = (const char *) glGetString(s);
    LOGI("GL %s = %s\n", name, v);
}

static void checkGlError(const char* op) {
    for (GLint error = glGetError(); error; error
            = glGetError()) {
        LOGI("after %s() glError (0x%x)\n", op, error);
    }
}

GLuint loadShader(GLenum shaderType, const char* pSource, GLint sLen) {
    GLuint shader = glCreateShader(shaderType);
    if (shader) {
        glShaderSource(shader, 1, &pSource, &sLen);
        glCompileShader(shader);
        GLint compiled = 0;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
            if (infoLen) {
                char* buf = (char*) malloc(infoLen);
                if (buf) {
                    glGetShaderInfoLog(shader, infoLen, NULL, buf);
                    LOGE("Could not compile shader %d:\n%s\n",
                            shaderType, buf);
                    free(buf);
                }
                glDeleteShader(shader);
                shader = 0;
            }
        }
    }
    return shader;
}

GLuint shaderFromAsset(const char* vAsset, const char* fAsset)
{
	AAsset* asset;
	long vsize, fsize;

    asset = AAssetManager_open(pAssetManager, vAsset, AASSET_MODE_UNKNOWN);
    vsize = AAsset_getLength(asset);
    char* vShader = (char*) calloc (sizeof(char),vsize);
    //char* vShaderNull = (char*) malloc (sizeof(char)*(size+1));
    AAsset_read (asset,vShader,vsize);
    //strncpy(vShaderNull,vShader,size);
    //vShaderNull[size+1] = "\0";
    AAsset_close(asset);

    asset = AAssetManager_open(pAssetManager, fAsset, AASSET_MODE_UNKNOWN);
    fsize = AAsset_getLength(asset);
    char* fShader = (char*) calloc (sizeof(char),fsize);
    AAsset_read (asset,fShader,fsize);
    AAsset_close(asset);
    GLuint program = createProgram(vShader,vsize,fShader,fsize);
    return program;
}

GLuint createProgram(const char* pVertexSource, GLint vLen, const char* pFragmentSource, GLint fLen) {
    //LOGI("... calling vertex loadShader \n%s\n",pVertexSource);
    GLuint vertexShader = loadShader(GL_VERTEX_SHADER, pVertexSource, vLen);
    if (!vertexShader) {
        return 0;
    }
    //LOGI("... calling fragment loadShader \n%s\n",pFragmentSource);
    GLuint pixelShader = loadShader(GL_FRAGMENT_SHADER, pFragmentSource, fLen);
    if (!pixelShader) {
        return 0;
    }

    GLuint program = glCreateProgram();
    if (program) {
        glAttachShader(program, vertexShader);
        checkGlError("glAttachShader");
        glAttachShader(program, pixelShader);
        checkGlError("glAttachShader");
        glLinkProgram(program);
        GLint linkStatus = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
            GLint bufLength = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufLength);
            if (bufLength) {
                char* buf = (char*) malloc(bufLength);
                if (buf) {
                    glGetProgramInfoLog(program, bufLength, NULL, buf);
                    LOGE("Could not link program:\n%s\n", buf);
                    free(buf);
                }
            }
            glDeleteProgram(program);
            program = 0;
        }
    }
    LOGI("Shader Program %d Ready!",program);
    return program;
}

GLuint textureFromAsset(const char *assetName)
{
    //AAssetManager* mgr = AAssetManager_fromJava(jEnv, jAssetManager);
    AAsset* asset = AAssetManager_open(pAssetManager, assetName, AASSET_MODE_UNKNOWN);
    if (NULL == asset) {
        //__android_log_print(ANDROID_LOG_ERROR, "gl_code.cpp", "_ASSET_NOT_FOUND_");
        return JNI_FALSE;
    }
    long size = AAsset_getLength(asset);
    char* buffer = (char*) malloc (sizeof(char)*size);
    AAsset_read (asset,buffer,size);
    //__android_log_print(ANDROID_LOG_ERROR, "gl_code.cpp", buffer);
    LOGI("..portraitTexture size = %d\n",size);
    AAsset_close(asset);
	GLuint tex_2d_from_RAM = SOIL_load_OGL_texture_from_memory
	(
		(const unsigned char*)buffer,
		size,
		SOIL_LOAD_AUTO,
		SOIL_CREATE_NEW_ID,
		SOIL_FLAG_MIPMAPS | SOIL_FLAG_INVERT_Y | SOIL_FLAG_COMPRESS_TO_DXT
	);
    return tex_2d_from_RAM;
}

GLuint gProgram;
GLuint gvPositionHandle;
GLuint pProg, bProg;
GLuint pProgPosition;
GLuint pProgColor;
GLuint pProgSize;
GLuint pProgOpacity;
GLuint portraitTexture;
GLuint landscapeTexture;
GLuint backgroundBuffer[1];
GLuint bProgPosition;
GLuint bProgTexture;
GLuint bProgOffset;
GLuint bProgSwipeScale;
GLuint bProgSwipeOverlap;
GLuint wallpaperTexture[1];
GLfloat backgroundVerts[8];
int setupGL = 0;

bool setupGraphics(int w, int h) {
    //printGLString("Version", GL_VERSION);
    //printGLString("Vendor", GL_VENDOR);
    //printGLString("Renderer", GL_RENDERER);
    //printGLString("Extensions", GL_EXTENSIONS);
    LOGI("setupGraphics(%d, %d)", w, h);
    width = w;
    height = h;
    screenAspect = (float)width/(float)height;
    int minwh;
    if(width > height)
    {
    	minwh = height;
    }
    else
    {
    	minwh = width;
    }
    int tmpsize = minwh/4;
    particleSize = pScale*tmpsize;
    if (setupGL == 1)
    {
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        if(!glIsProgram(pProg)){
    		pProg = shaderFromAsset("pointshader.v.glsl","pointshader.f.glsl");
        }
		//bProgPosition = glGetAttribLocation(bProg,"position");
        if(!glIsProgram(bProg)){
    		bProg = shaderFromAsset("background.v.glsl","background.f.glsl");
        }
		if(!glIsTexture(portraitTexture)){
	        LOGI("Loading portrait background texture...");
			portraitTexture = textureFromAsset("sellers_12_portrait.jpg");
			LOGI("... portraitTexture id = %d",portraitTexture);
		}
		if(!glIsTexture(landscapeTexture)){
	        LOGI("Loading landscape background texture...");
			landscapeTexture = textureFromAsset("sellers_12_landscape.jpg");
			LOGI("... landscapeTexture id = %d",landscapeTexture);
		}
        if(!glIsBuffer(backgroundBuffer[0]))
        {
        	glGenBuffers(1,backgroundBuffer);
        	LOGI("... backgroundBuffer id = %d",backgroundBuffer[0]);
        }
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
		// particle program
		pProgPosition = glGetAttribLocation(pProg,"position");
		checkGlError("glGetAttribLocation");
//		LOGI("glGetAttribLocation(\"position\") = %d\n",
//				pProgPosition);
		pProgColor = glGetAttribLocation(pProg,"pcolor");
		checkGlError("glGetAttribLocation");
//		LOGI("glGetAttribLocation(\"color\") = %d\n",
//				pProgColor);
		pProgSize = glGetUniformLocation(pProg,"psize");
		checkGlError("glGetUniformLocation");
//		LOGI("glGetUniformLocation(\"psize\") = %d\n",
//				pProgSize);
		pProgOpacity = glGetUniformLocation(pProg,"popacity");
		checkGlError("glGetUniformLocation");
//		LOGI("glGetUniformLocation(\"popacity\") = %d\n",
//				pProgOpacity);
		// background program
		bProgPosition = glGetAttribLocation(bProg,"position");
		checkGlError("glGetAttribLocation");
//		LOGI("glGetAttribLocation(\"position\") = %d\n",
//				bProgPosition);
		bProgTexture = glGetUniformLocation(bProg,"textures[0]");
		checkGlError("glGetUniformLocation");
//		LOGI("glGetUniformLocation(\"textures[0]\") = %d\n",
//				bProgTexture);
		bProgOffset = glGetUniformLocation(bProg,"offset");
		checkGlError("glGetUniformLocation");
//		LOGI("glGetUniformLocation(\"offset\") = %d\n",
//				bProgOffset);
		bProgSwipeScale = glGetUniformLocation(bProg,"swipescale");
		checkGlError("glGetUniformLocation");
//		LOGI("glGetUniformLocation(\"swipescale\") = %d\n",
//				bProgSwipeScale);
		bProgSwipeOverlap = glGetUniformLocation(bProg,"swipeoverlap");
		checkGlError("glGetUniformLocation");
//		LOGI("glGetUniformLocation(\"swipeoverlap\") = %d\n",
//				bProgSwipeOverlap);
		fillBackgroundBuffer();
		setupGL = 0;
		bcolor.r = 16./256.;
		bcolor.g = 12./256.;
		bcolor.b = 28./256.;
		update_nparticles(nParticles,particleSize);
    }
	glViewport(0, 0, w, h);
    checkGlError("glViewport");
    LOGI("..setupGraphics called setup_particle_engine..\n");
//	if(nParticles != checkParticleNum)
//	{
//		LOGI("..JNI setupGraphics calling update_nparticles(%d)\n",nParticles);
//		LOGI("checkParticleNum = %d checkParticleSize = %d",checkParticleNum,checkParticleSize);
//		LOGI("nParticles = %d particleSize = %d",nParticles,particleSize);
//		update_nparticles(nParticles,particleSize);
//		checkParticleNum = nParticles;
//		checkParticleSize = particleSize;
//	}
    if(width > 0 && height > 0)
    {
    	setup_particle_engine(w,h);
    }
    return true;
}

void fillBackgroundBuffer()
{
    float x0 = -1.0;
    float x1 = 1.0;
    float y0 = -1.0;
    float y1 = 1.0;
    backgroundVerts[0] = x0;
    backgroundVerts[1] = y0;
    backgroundVerts[2] = x0;
    backgroundVerts[3] = y1;
    backgroundVerts[4] = x1;
    backgroundVerts[5] = y0;
    backgroundVerts[6] = x1;
    backgroundVerts[7] = y1;
	glBindBuffer(GL_ARRAY_BUFFER, backgroundBuffer[0]);
    checkGlError("glClearColor");
	glBufferData(GL_ARRAY_BUFFER, sizeof(backgroundVerts), &backgroundVerts, GL_STATIC_DRAW);
    checkGlError("glClearColor");
	glBindBuffer(GL_ARRAY_BUFFER,0);
    checkGlError("glClearColor");

}
//const GLfloat gTriangleVertices[] = { 0.0f, 0.5f, -0.5f, -0.5f,
//        0.5f, -0.5f };

const GLfloat gTriangleVertices[] = { fortran_color(), 0.5f, -0.5f, -0.5f,
        0.5f, -0.5f };

void renderFrame() {
    glClearColor(bcolor.r, bcolor.g, bcolor.b, 1.0f);
    checkGlError("glClearColor");
    glClear( GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    checkGlError("glClear");

    // glUseProgram(gProgram);
    //checkGlError("glUseProgram");

    //glVertexAttribPointer(gvPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, gTriangleVertices);
    //checkGlError("glVertexAttribPointer");
    //glEnableVertexAttribArray(gvPositionHandle);
    //checkGlError("glEnableVertexAttribArray");
    //glDrawArrays(GL_TRIANGLES, 0, 3);
    //checkGlError("glDrawArrays");
    //drawArrow(0,0,0,0.5,0);
    update_particle_engine();
    if(useSystemBackground)drawBackground();
    drawParticles();
}

void drawArrow(float p1x,float p1y,float angle,float length, int rotation){
    float lhead = length*.7;
    float p2x,p3x,p4x,p5x;
    float p2y,p3y,p4y,p5y;
    float sh = 2.0;
    p2x = p1x + length * cos(angle);
    p2y = p1y + length * sin(angle);
    p3x = p1x + lhead * cos(angle+8.0*d2r);
    p3y = p1y + lhead * sin(angle+8.0*d2r);
    p4x = p1x + lhead * cos(angle-8.0*d2r);
    p4y = p1y + lhead * sin(angle-8.0*d2r);
    p5x = p1x + length * 0.9 * cos(angle);
    p5y = p1y + length * 0.9 * sin(angle);
    GLfloat vertices[] = {p1x,p1y,p2x,p2y,p3x,p3y,p5x,p5y,p4x,p4y,p2x,p2y};
    GLfloat shadow[] = {p1x-sh,p1y-sh,p2x-sh,p2y-sh,p3x-sh,p3y-sh,p5x-sh,
                        p5y-sh,p4x-sh,p4y-sh,p2x-sh,p2y-sh};
    glUseProgram(gProgram);
    checkGlError("glUseProgram");
    glVertexAttribPointer(gvPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    checkGlError("glVertexAttribPointer");
    glEnableVertexAttribArray(gvPositionHandle);
    checkGlError("glEnableVertexAttribArray");
    glDrawArrays(GL_LINE_LOOP, 0, 6);
    checkGlError("glDrawArrays");
}

void drawBackground()
{
    // draw three color test points
    //GLfloat vertices[] = {-0.25,0.0,0.25,0.0,0,0.25};
    //GLfloat colors[] = {1,0,0,1,0,1,0,1,0,0,1,1};
	glBindBuffer(GL_ARRAY_BUFFER, backgroundBuffer[0]);
	glUseProgram(bProg);
	glActiveTexture(GL_TEXTURE0);
	if(useSystemBackground)
	{
		glBindTexture(GL_TEXTURE_2D, wallpaperTexture[0]);
	}
	else
	{
		if(screenRotation == 0 || screenRotation == 2)
		{
			glBindTexture(GL_TEXTURE_2D, portraitTexture);
		}
		else
		{
			glBindTexture(GL_TEXTURE_2D, landscapeTexture);
		}
	}
	glBindTexture(GL_TEXTURE_2D, wallpaperTexture[0]);
//	LOGI("wallpaperTexture = %d",wallpaperTexture);
//	glBindTexture(GL_TEXTURE_2D, wallpaperTexture[0]);
//    LOGE("..wallpaper glBindTexture GLError = %d",glGetError());
	float swipescalex = (float)width/(float)wpWidth;
	float swipescaley = (float)height/(float)wpHeight;
	float swipeoverlapx = (float)(wpWidth-width)/(float)wpWidth;
	float swipeoverlapy = (float)(wpHeight-height)/(float)wpHeight;
	glUniform2f(bProgOffset,xOffset,yOffset);
	glUniform2f(bProgSwipeScale,swipescalex,swipescaley);
	glUniform2f(bProgSwipeOverlap,swipeoverlapx,swipeoverlapy);
	glUniform1i(bProgTexture,0);
	glEnableVertexAttribArray(bProgPosition);
    //checkGlError("glUseProgram");
    // draw dustengine particles
    glVertexAttribPointer(bProgPosition,2,GL_FLOAT, GL_FALSE, 0, NULL);
    //checkGlError("glVertexAttribPointer");
    //checkGlError("glUniform1f");
    glDrawArrays(GL_TRIANGLE_STRIP,0,4);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
}

void drawParticles()
{
    // draw three color test points
    //GLfloat vertices[] = {-0.25,0.0,0.25,0.0,0,0.25};
    //GLfloat colors[] = {1,0,0,1,0,1,0,1,0,0,1,1};
	glUseProgram(pProg);
    //checkGlError("glUseProgram");
    // draw dustengine particles
    glVertexAttribPointer(pProgPosition,2,GL_FLOAT, GL_FALSE, 0, c_pointxy);
    //checkGlError("glVertexAttribPointer");
    glEnableVertexAttribArray(pProgPosition);
    glVertexAttribPointer(pProgColor,4,GL_FLOAT, GL_FALSE, 0, c_pointcolor);
    //checkGlError("glVertexAttribPointer");
    glEnableVertexAttribArray(pProgColor);
    glUniform1f(pProgSize,particleSize);
    glUniform1f(pProgOpacity,opacity);
    //checkGlError("glUniform1f");
    glDrawArrays(GL_POINTS,0,nParticles);
}

void accelerate(float mSensorX,float mSensorY, int mRotation)
{
	update_accel(mSensorX,mSensorY,mRotation);
}


//void setnparticles(int nparticles)
//{
//	LOGI("..Calling update_nparticles(%d)\n",nparticles);
//	update_nparticles(nparticles);
//}

extern "C" {
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_init(JNIEnv * env, jobject obj,  jint width, jint height);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_initGLpipeline(JNIEnv * env, jobject obj, jstring jwpPath, jint theWidth, jint theHeight);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_step(JNIEnv * env, jobject obj);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_accelerate(JNIEnv * env, jobject obj, jfloat jSensorX, jfloat jSensorY, jint jRotation);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setnparticles(JNIEnv * env, jobject obj, jint nparticles, jint jparticleSize);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_updateTouch(JNIEnv * env, jobject obj, jfloat touchX, jfloat touchY, jint touchAction);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_enableGravity(JNIEnv * env, jobject obj, jboolean gravityOn);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_enableTouch(JNIEnv * env, jobject obj, jboolean touchOn);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setOpacity(JNIEnv * env, jobject obj, jint jOpacity);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setGravity(JNIEnv * env, jobject obj, jint jGravity);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setAttract(JNIEnv * env, jobject obj, jint jAttract);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setJavaEnv(JNIEnv * env, void* reserverd, jobject jAssetManager);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setBackground(JNIEnv * env, jobject obj, jboolean juseSystemBackground);
    JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_offsetChanged(JNIEnv * env, jobject obj, jfloat jxOffset,jfloat jyOffset,
    		                                                                             jfloat jxStep,jfloat jyStep,jint jxPixels,jint jyPixels);
};

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_offsetChanged(JNIEnv * env, jobject obj, jfloat jxOffset,
		  jfloat jyOffset,jfloat jxStep,jfloat jyStep,jint jxPixels,jint jyPixels)
{
	xOffset = jxOffset;
	yOffset = jyOffset;
	xStep = jxStep;
	yStep = jyStep;
	xPixels = jxPixels;
	yPixels = jyPixels;
//	LOGI("...entering JNI offsetChanged...");
//	glBindBuffer(GL_ARRAY_BUFFER, backgroundBuffer[0]);
//	if(glIsBuffer(backgroundBuffer[0]))
//	{
//		LOGI("...calling fillBackgroundBuffer()...");
		fillBackgroundBuffer();
//	}
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_init(JNIEnv * env, jobject obj,  jint jwidth, jint jheight)
{
	width = jwidth;
	height = jheight;
	if(width > 0 && height > 0)
	{
		setupGraphics(width, height);
	}
}
JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_initGLpipeline(JNIEnv * env, jobject obj, jstring jwpPath, jint theWidth, jint theHeight)
{
	jEnv = env;
	wpWidth = theWidth;
	wpHeight = theHeight;
	wpAspect = (float)wpWidth/(float)wpHeight;

	const char* wallpaperFile = env->GetStringUTFChars(jwpPath, 0);
//	if(strcmp(wallpaperFile, "none") != 0)
//	{
	if(!glIsTexture(wallpaperTexture[0]))
	{
		wallpaperTexture[0] = SOIL_load_OGL_texture
		(
			wallpaperFile,
			SOIL_LOAD_AUTO,
			SOIL_CREATE_NEW_ID,
			SOIL_FLAG_MIPMAPS | SOIL_FLAG_INVERT_Y | SOIL_FLAG_NTSC_SAFE_RGB | SOIL_FLAG_COMPRESS_TO_DXT
		);
	}
//	LOGI("wallpaperTexture ID from filesDir: %d",wallpaperTexture[0]);
    setupGL = 1;
//}
//	else
//	{
//		LOGI("..skipping background texture generation..");
//		LOGI("..wallpaperTexture ID: %d",wallpaperTexture[0]);
//		setupGL = 1;
//	}
//	LOGI("..wallpaperFile = %s",wallpaperFile);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_step(JNIEnv * env, jobject obj)
{
    renderFrame();
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_accelerate(JNIEnv * env, jobject obj, jfloat jSensorX, jfloat jSensorY, jint jRotation)
{
	screenRotation = jRotation;
    accelerate(jSensorX,jSensorY,jRotation);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_updateTouch(JNIEnv * env, jobject obj, jfloat touchX, jfloat touchY, jint touchAction)
{
    update_touch(touchX,touchY,touchAction);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_enableGravity(JNIEnv * env, jobject obj, jboolean gravityOn)
{
    enable_gravity(gravityOn);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_enableTouch(JNIEnv * env, jobject obj, jboolean touchOn)
{
    enable_touch(touchOn);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setOpacity(JNIEnv * env, jobject obj, jint jOpacity)
{
    opacity = 1.0-(float)jOpacity/100.0;
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setGravity(JNIEnv * env, jobject obj, jint jGravity)
{
    float gravity = (float)jGravity;
//    LOGI("..JNI Calling set_gravity(%f) jGravity(%d)\n",gravity,jGravity);
    set_gravity(gravity);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setAttract(JNIEnv * env, jobject obj, jint jAttract)
{
    float attract = ((float)jAttract)/300.0;
//    LOGI("..JNI Calling set_attract(%f) jAttract(%d)\n",attract,jAttract);
    set_attract(attract);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setnparticles(JNIEnv * env, jobject obj, jint jnparticles, jint jparticleSize)
{
    nParticles = jnparticles; //setnparticles(nparticles);
    int minwh;
    if(width > height)
    {
    	minwh = height;
    }
    else
    {
    	minwh = width;
    }
    		/// gnu_stl needs to get built for Fortran apps! std::min(width,height);
    int tmpsize = minwh/4;
    pScale = ((float)jparticleSize/100.0);
    particleSize = pScale*tmpsize;
	if(nParticles != checkParticleNum && width > 0 && height > 0)
	{
//		LOGI("..JNI setnparticles calling update_nparticles(%d)\n",nParticles);
		update_nparticles(nParticles,particleSize);
		checkParticleNum = nParticles;
		checkParticleSize = particleSize;
	}
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setJavaEnv(JNIEnv * env, void* reserverd, jobject assetManager)
{
    //jEnv = env;
    //assetManager = jAssetManager;
    pAssetManager = AAssetManager_fromJava(env, assetManager);
}

JNIEXPORT void JNICALL Java_com_hmmmgames_particlewallpaper_GL2JNILib_setBackground(JNIEnv * env, jobject obj, jboolean juseSystemBackground)
{
    useSystemBackground = juseSystemBackground;
}

