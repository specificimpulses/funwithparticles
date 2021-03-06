#include <jni.h>
#include <errno.h>

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

#include <android/sensor.h>
#include <android/log.h>
#include <android_native_app_glue.h>
#include <android/window.h>

// for native asset manager
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

/**
 * Our saved state data.
 */
struct saved_state {
    float angle;
    int32_t x;
    int32_t y;
    float pressure;
};

/**
 * Shared state for our app.
 */
struct engine {
    struct android_app* app;

    ASensorManager* sensorManager;
    const ASensor* accelerometerSensor;
    ASensorEventQueue* sensorEventQueue;

    int animating;
    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    int32_t width;
    int32_t height;
    struct saved_state state;
};

/**
 * Initialize an EGL context for the current display.
 */
static int engine_init_display(struct engine* engine) {
    // initialize OpenGL ES 2.0 and EGL

    /*
     * Here specify the attributes of the desired configuration.
     * Below, we select an EGLConfig with at least 8 bits per color
     * component compatible with on-screen windows
     */
/*    const EGLint attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_RENDERABLE_TYPE,
						EGL_OPENGL_ES2_BIT,
            EGL_NONE
    };*/
    const EGLint attribs[] = {
						EGL_RENDERABLE_TYPE,EGL_OPENGL_ES2_BIT,
            EGL_NONE
    };
    EGLint w, h, dummy, format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
		EGLint contextAttrs[] = {
    		 EGL_CONTEXT_CLIENT_VERSION, 2,
     		 EGL_NONE
		};

    eglInitialize(display, NULL, NULL);

    /* Here, the application chooses the configuration it desires. In this
     * sample, we have a very simplified selection process, where we pick
     * the first EGLConfig that matches our criteria */
    eglChooseConfig(display, attribs, &config, 2, &numConfigs);

    LOGW("numConfigs %d",numConfigs);

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);
    //ANativeActivity_setWindowFlags(engine->app->activity,AWINDOW_FLAG_FULLSCREEN, AWINDOW_FLAG_SCALED);
    ANativeWindow_setBuffersGeometry(engine->app->window, 0, 0, format);
    LOGI("Window format is now %d",ANativeWindow_getFormat(engine->app->window));
    surface = eglCreateWindowSurface(display, config, engine->app->window, NULL);
    context = eglCreateContext(display, config, NULL, contextAttrs);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
        LOGW("Unable to eglMakeCurrent");
        return -1;
    }

    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);

    engine->display = display;
    engine->context = context;
    engine->surface = surface;
    engine->width = w;
    engine->height = h;
    engine->state.angle = 0;

    // Initialize GL state.
    //glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
    //glEnable(GL_CULL_FACE);
    //glShadeModel(GL_SMOOTH);
    //glDisable(GL_DEPTH_TEST);
    //
// make sure the game assets are present on the sdcard
    AAssetManager* assetManager = engine->app->activity->assetManager;
    FILE *new_file;
    const char* asset_sdpath = "/sdcard/SpecImpDemo1";
    int result;
    result = mkdir(asset_sdpath, 0777);
    LOGI("making directory.. %s,%i",asset_sdpath,result);
// open a file from the assets and copy it to the sdcard
// note that the files are appended with .mp3 to keep the android build tool
// from compressing it in the asset.. maybe use zlib to get around this later
    AAsset* asset_file;
    const void* asset_buffer;
    size_t len;
// load the assets
// ui vertex shader
    asset_file = AAssetManager_open(assetManager,"s1.v.glsl.mp3",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/SpecImpDemo1/s1.v.glsl","wb");
    len = strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// ui fragment shader
    asset_file = AAssetManager_open(assetManager,"s1.f.glsl.mp3",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/SpecImpDemo1/s1.f.glsl","wb");
    len = strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// move into the asset directory
    chdir("/sdcard/SpecImpDemo1");
    dust_engine_init(&w,&h);  //initialize the game engine
    LOGI("..dust_engine_init successful...");
    dust_engine_initgl();  //initialize the OpenGL window
    LOGI("..dust_engine_initgl successful...");
    engine->animating = 1;
    return 0;
}

/**
 * Just the current frame in the display.
 */
static void engine_draw_frame(struct engine* engine) {
    if (engine->display == NULL) {
        // No display.
        return;
    }

    //{
    //  LOGI("Fortran invar = %i\n",0);
    //}
    int glerrorcode;
    //LOGI("...dust_engine_run() called");
    dust_engine_run(); 
    //glerrorcode = glGetError();
    //LOGI("glGetError() returned: %i, %i",glerrorcode,GL_NO_ERROR);
    //LOGI("...dust_engine_run() returned");

    eglSwapBuffers(engine->display, engine->surface);
}

/**
 * Tear down the EGL context currently associated with the display.
 */
static void engine_term_display(struct engine* engine) {
    if (engine->display != EGL_NO_DISPLAY) {
        eglMakeCurrent(engine->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (engine->context != EGL_NO_CONTEXT) {
            eglDestroyContext(engine->display, engine->context);
        }
        if (engine->surface != EGL_NO_SURFACE) {
            eglDestroySurface(engine->display, engine->surface);
        }
        eglTerminate(engine->display);
    }
    engine->animating = 0;
    engine->display = EGL_NO_DISPLAY;
    engine->context = EGL_NO_CONTEXT;
    engine->surface = EGL_NO_SURFACE;
}

/**
 * Process the next input event.
 */
static int32_t engine_handle_input(struct android_app* app, AInputEvent* event) {
    struct engine* engine = (struct engine*)app->userData;
    if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        engine->animating = 1;
        engine->state.x = AMotionEvent_getX(event, 0);
        engine->state.y = AMotionEvent_getY(event, 0);
        engine->state.pressure = AMotionEvent_getPressure(event, 0);
        dust_com_touch(&engine->state.x,&engine->state.y,&engine->state.pressure);
        //LOGI("state.x= %i, state.y= %i",engine->state.x,engine->state.y);
        return 1;
    }
    return 0;
}

/**
 * Process the next main command.
 */
static void engine_handle_cmd(struct android_app* app, int32_t cmd) {
    struct engine* engine = (struct engine*)app->userData;
    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            // The system has asked us to save our current state.  Do so.
            engine->app->savedState = malloc(sizeof(struct saved_state));
            *((struct saved_state*)engine->app->savedState) = engine->state;
            engine->app->savedStateSize = sizeof(struct saved_state);
            break;
        case APP_CMD_INIT_WINDOW:
            // The window is being shown, get it ready.
            if (engine->app->window != NULL) {
                engine_init_display(engine);
                engine_draw_frame(engine);
            }
            break;
        case APP_CMD_TERM_WINDOW:
            // The window is being hidden or closed, clean it up.
            engine_term_display(engine);
            exit(0);
            break;
        case APP_CMD_GAINED_FOCUS:
            // When our app gains focus, we start monitoring the accelerometer.
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_enableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
                // We'd like to get 60 events per second (in us).
                ASensorEventQueue_setEventRate(engine->sensorEventQueue,
                        engine->accelerometerSensor, (1000L/60)*1000);
            }
            break;
        case APP_CMD_LOST_FOCUS:
            // When our app loses focus, we stop monitoring the accelerometer.
            // This is to avoid consuming battery while not being used.
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_disableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
            }
            // Also stop animating.
            engine->animating = 0;
            engine_draw_frame(engine);
            exit(0);
            break;
    }
}

/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
void android_main(struct android_app* state) {
    struct engine engine;

    // Make sure glue isn't stripped.
    app_dummy();

    memset(&engine, 0, sizeof(engine));
    state->userData = &engine;
    state->onAppCmd = engine_handle_cmd;
    state->onInputEvent = engine_handle_input;
    engine.app = state;

    // Prepare to monitor accelerometer
    engine.sensorManager = ASensorManager_getInstance();
    engine.accelerometerSensor = ASensorManager_getDefaultSensor(engine.sensorManager,
            ASENSOR_TYPE_ACCELEROMETER);
    engine.sensorEventQueue = ASensorManager_createEventQueue(engine.sensorManager,
            state->looper, LOOPER_ID_USER, NULL, NULL);

    if (state->savedState != NULL) {
        // We are starting with a previous saved state; restore from it.
        engine.state = *(struct saved_state*)state->savedState;
    }

    // loop waiting for stuff to do.

    //usleep(2000000);

    while (1) {
        // Read all pending events.
        int ident;
        int events;
        struct android_poll_source* source;

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while ((ident=ALooper_pollAll(engine.animating ? 0 : -1, NULL, &events,
                (void**)&source)) >= 0) {

            // Process this event.
            if (source != NULL) {
                source->process(state, source);
            }

            // If a sensor has data, process it now.
            if (ident == LOOPER_ID_USER) {
                if (engine.accelerometerSensor != NULL) {
                    ASensorEvent event;
                    while (ASensorEventQueue_getEvents(engine.sensorEventQueue,
                            &event, 1) > 0) {
                        //LOGI("accelerometer: x=%f y=%f z=%f",
                        //        event.acceleration.x, event.acceleration.y,
                        //        event.acceleration.z);
                        dust_com_sensors(&event.acceleration.x, &event.acceleration.y,
                                    &event.acceleration.z);
                        //dust_com_sensors(1.0, 1.0,
                        //            1.0);
                    }
                }
            }

            // Check if we are exiting.
            if (state->destroyRequested != 0) {
                engine_term_display(&engine);
                return;
            }
        }

        if (engine.animating) {
            // Done with events; draw next animation frame.
            engine.state.angle += .01f;
            if (engine.state.angle > 1) {
                engine.state.angle = 0;
            }

            // Drawing is throttled to the screen update rate, so there
            // is no need to do timing here.
            engine_draw_frame(&engine);
        }
    }
}
