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


void fortran_process_events(struct android_app* fortran_app) {
        // Read all pending events.
        int ident;
        int events;
        struct android_poll_source* source;

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        ident=ALooper_pollAll(0, NULL, &events,(void**)&source);

            // Process this event.
            if (source != NULL) {
                source->process(fortran_app, source);
                LOGI("fortran_process_events.. %d",ident);
            }

    }

