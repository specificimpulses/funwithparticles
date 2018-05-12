package com.hmmmgames.particlefun;

import android.app.NativeActivity;
import android.util.Log;
import android.view.Display;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.content.Context;

public class ParticleFun extends NativeActivity {
  public static int myRotation = 0;
//  public static int nRotation = 0;
  static {
    System.loadLibrary("particlefun");  
  }
    private WindowManager mWindowManager;
    private Display mDisplay;
  
  private static String TAG = "ParticleFun";
  /** Called when the activity is first created. */
  @Override
  public void onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      // Get an instance of the WindowManager
      mWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
      mDisplay = mWindowManager.getDefaultDisplay();
      myRotation = mDisplay.getRotation();
      String logString = "onCreate Rotation = " + String.valueOf(myRotation);
      Log.i(TAG,logString);
  }

  public ParticleFun() {
    super();
    Log.i(TAG,"... ParticleFun constructor called");
    String logString = "super() Rotation = " + String.valueOf(myRotation);
    Log.i(TAG,logString);
  }

//  public int ngetRotation() {
////    WindowManager nWindowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
////    Display nDisplay = nWindowManager.getDefaultDisplay();
////    nRotation = nDisplay.getRotation();
//    nRotation = 999;
//    String logString = "ngetRotation() Rotation = " + String.valueOf(nRotation);
//    Log.i(TAG,logString);
//    return nRotation;
//  }

}

