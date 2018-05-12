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
#define LOGE(...) ((void)__android_log_print(ANDROID_LOG_ERROR, "native-activity", __VA_ARGS__))

//jint JNI_OnLoad(JavaVM *, void *);

JavaVM *nativeJavaVM;
jmethodID mid_getRotation;
jfieldID fid_myRotation;
jobject jobject_ParticleFun;

/**
 * Our saved state data.
 */
struct saved_state {
    float angle;
    int32_t x;
    int32_t y;
    int32_t keyAction;
    int32_t keyCode;
    int32_t action;
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

const EGLint attribs[] = {
    EGL_LEVEL,            0,
    EGL_SURFACE_TYPE,      EGL_WINDOW_BIT,
    EGL_RENDERABLE_TYPE,   EGL_OPENGL_ES2_BIT,
    EGL_DEPTH_SIZE,         EGL_DONT_CARE,
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
    eglChooseConfig(display, attribs, &config, 1, &numConfigs);

    LOGW("numConfigs %d",numConfigs);

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);
    //ANativeActivity_setWindowFlags(engine->app->activity,AWINDOW_FLAG_FULLSCREEN, AWINDOW_FLAG_SCALED);
    ANativeWindow_setBuffersGeometry(engine->app->window, 0, 0, format);
    LOGI("Window format is now %d",ANativeWindow_getFormat(engine->app->window));
    context = eglCreateContext(display, config, NULL, contextAttrs);
    surface = eglCreateWindowSurface(display, config, engine->app->window, NULL);
    //context = eglCreateContext(display, config, EGL_NO_CONTEXT, contextAttrs);
    LOGI("GL surface: %x\n", surface);
    if (surface==0) LOGW("Error code: %x\n", eglGetError());
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
    const char* asset_sdpath = "/sdcard/FunWithParticles";
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
// particle vertex shader
    asset_file = AAssetManager_open(assetManager,"s1.v.glsl.mp3",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/FunWithParticles/s1.v.glsl","wb");
    len = strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// particle fragment shader
    asset_file = AAssetManager_open(assetManager,"s1.f.glsl.mp3",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/FunWithParticles/s1.f.glsl","wb");
    len = strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// ui vertex shader
    asset_file = AAssetManager_open(assetManager,"ui.v.glsl.mp3",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/FunWithParticles/ui.v.glsl","wb");
    len = strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// ui fragment shader
    asset_file = AAssetManager_open(assetManager,"ui.f.glsl.mp3",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/FunWithParticles/ui.f.glsl","wb");
    len = strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// ui overlay graphic
    asset_file = AAssetManager_open(assetManager,"overl1.png",AASSET_MODE_UNKNOWN);
    asset_buffer = AAsset_getBuffer(asset_file);
// open the file on the sdcard and write the buffer to it
    new_file = fopen("/sdcard/FunWithParticles/overl1.png","wb");
    len = 22646; //strlen(asset_buffer)-5;
    LOGW("..asset buffer size: %i",len);
    // android puts some extra info in the last 8 bytes, so leave that off
    fwrite(asset_buffer,len,1,new_file);
    fclose(new_file);
    AAsset_close(asset_file);
// move into the asset directory
    chdir("/sdcard/FunWithParticles");
    int myRot = getScreenRotation();    
    LOGI("...screen rotation = %i",myRot);
    dust_engine_init(w,h,myRot);  //initialize the game engine
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
        //engine->state.x = AMotionEvent_getX(event, 0);
        //engine->state.y = AMotionEvent_getY(event, 0);
        //engine->state.pressure = AMotionEvent_getPressure(event, 0);
        //engine->state.action = AMotionEvent_getAction(event);
        size_t nPointerCount = AMotionEvent_getPointerCount(event);
        int32_t pX;
        int32_t pY;
        int32_t pAction;
        float pPressure;
        // get the action and pointer ID
        int32_t thisAction = AMotionEvent_getAction(event);
        int32_t pIndex = (thisAction & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) 
        >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT;
        int n;
        // from Sony Xperia Play example...
        for( n = 0 ; n < nPointerCount ; ++n )
          {
            int nPointerId = AMotionEvent_getPointerId( event, n );
            int nAction= AMOTION_EVENT_ACTION_MASK &
            AMotionEvent_getAction( event );        //while (i <= pCount - 1)
            if( nAction == AMOTION_EVENT_ACTION_DOWN || nAction ==
                AMOTION_EVENT_ACTION_POINTER_DOWN || AMOTION_EVENT_ACTION_MOVE )
              {
                pX = AMotionEvent_getX( event, n );
                pY = AMotionEvent_getY( event, n );
                pPressure = AMotionEvent_getPressure(event,n);
                dust_com_touch(&pX,&pY,&pPressure,&nPointerId,&nAction);
                //LOGI("pIndex= %i, pId= %i, pX= %i, pY= %i",pIndex,nPointerId,pX,pY,nAction);
              }
          }
        //  { 
            //pID = AMotionEvent_getPointerId(event,i);
            //pAction[i] = AMotionEvent_getAction(event,i);
        //    i++;
        //  }
        return 1;
        }
    else if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_KEY) {
        engine->animating = 1;
        engine->state.keyCode = AKeyEvent_getKeyCode(event); 
        engine->state.keyAction = AKeyEvent_getAction(event);
        dust_com_key(&engine->state.keyCode,&engine->state.keyAction);
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

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
  JNIEnv* env;
  nativeJavaVM = vm;
  jmethodID constr_Display;
  LOGI("JNI_OnLoad called");
  if ((*vm)->GetEnv(vm, (void**) &env, JNI_VERSION_1_6) != JNI_OK){
    LOGE("Failed to get the environment using GetEnv()");
    return -1;
  }
  LOGI("cacheing VM stuff...");
  jobject_ParticleFun = (*env)->NewGlobalRef(env, (*env)->FindClass(env, "com/hmmmgames/particlefun/ParticleFun"));
  fid_myRotation = (*env)->GetStaticFieldID(env, jobject_ParticleFun,"myRotation","I");
//  mid_getRotation = (*env)->GetMethodID(env, jobject_ParticleFun,"ngetRotation","()I");
  return JNI_VERSION_1_6;
}

int getScreenRotation()
{
  LOGI("...entering getScreenRotation()");
  JNIEnv* env;
  LOGI("...attaching native thread");
  (*nativeJavaVM)->AttachCurrentThread(nativeJavaVM, &env, NULL);
//  mid_getRotation = (*env)->GetMethodID(env, jobject_ParticleFun,"ngetRotation","()I");
  LOGI("...requesting rotation value through JNI");
  int myRotation = (*env)->GetStaticIntField(env, jobject_ParticleFun, fid_myRotation);
//  int myGetRotation = (*env)->CallIntMethod(env, jobject_ParticleFun, mid_getRotation);
//  jmethodID mid2 = (*env)->GetMethodID(env, jView,"toString","()Ljava/lang/String;");
//  jstring jViewName = (*env)->CallObjectMethod(env, jView, mid2);
//  char* my_c_string = strdup((*env)->GetStringUTFChars(env,jViewName, 0));
//  (*env)->ReleaseStringUTFChars(env,jViewName, my_c_string);
  (*nativeJavaVM)->DetachCurrentThread(nativeJavaVM);
//  LOGI("...getRotation = %i",myGetRotation);
  LOGI("...rotation = %i",myRotation);
  return myRotation;
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
    // disable the screen timeout (might break some phones.. not sure yet).
    ANativeActivity_setWindowFlags(state->activity,AWINDOW_FLAG_FULLSCREEN|AWINDOW_FLAG_KEEP_SCREEN_ON,0);

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

    // pass the android_app pointer to fortran
    set_android_app(engine.app);

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
