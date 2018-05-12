#include <jni.h>
//#include <errno.h>

//#include <EGL/egl.h>
//#include <GLES2/gl2.h>
//#include <GLES2/gl2ext.h>

//#include <android/sensor.h>
#include <android/log.h>
//#include <android_native_app_glue.h>
//#include <android/window.h>
//#include <android/asset_manager.h>

// for native asset manager
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "dustengine", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "dustengine", __VA_ARGS__))

void clogi(char *my_string)
{
	LOGI("%s%c",my_string,NULL);
}

void clogw(char *my_string)
{
	LOGW("%s",my_string);
}

