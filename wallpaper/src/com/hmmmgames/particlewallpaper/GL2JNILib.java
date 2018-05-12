/*
 * Copyright (C) 2007 The Android Open Source Project
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

package com.hmmmgames.particlewallpaper;

import android.content.res.AssetManager;

// Wrapper for native library

public class GL2JNILib {

     static {
    	 System.loadLibrary("androidsoil");
         System.loadLibrary("gl2jni");
     }

    /**
     * @param width the current view width
     * @param height the current view height
     */
     public static native void init(int width, int height);
     public static native void step();
     public static native void accelerate(float jSensorX,float jSensorY, int mRotation);
     public static native void setnparticles(int npart, int particleSize);
	 public static native void updateTouch(float myX, float myY, int myAction);
	 public static native void enableGravity(boolean gravityOn);
	 public static native void enableTouch(boolean touchOn);
	 public static native void setOpacity(int opacity);
	 public static native void setGravity(int gravity);
	 public static native void setAttract(int attract);
	 public static native void setJavaEnv(AssetManager assetManager);
	 public static native void initGLpipeline(String wpPath, int theWidth, int theHeight);
	 public static native void setBackground(boolean useWallpaper);
	 public static native void offsetChanged(float xOffset, float yOffset,
			float xStep, float yStep, int xPixels, int yPixels);
}
