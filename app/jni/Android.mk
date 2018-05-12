# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_ARM_MODE  := arm
#LOCAL_ARM_NEON  := true
LOCAL_MODULE    := particlefun
LOCAL_SRC_FILES := iso_c_utilities.f90 android_fortran.f90 android_fortran_interface.c \
                   OpenGL_gl.f90 gl_2es.f90 shared_data.f90 \
									 gl2_fortran.f90 effects.f90 \
                   ui_module.f90 dustengine.f90 \
		   						 demodriver.f90 image_helper.c image_DXT.c stb_image_aug.c SOIL.c\
									 texture_tools.c util.c shader_tools.c  main.c
LOCAL_LDLIBS    := -llog -landroid -lEGL -lGLESv2 -lgfortran
LOCAL_STATIC_LIBRARIES := android_native_app_glue

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/native_app_glue)
