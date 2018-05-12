package com.hmmmgames.particlewallpaper;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.ConfigurationInfo;
import android.opengl.GLSurfaceView;
import android.os.Bundle;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.preference.PreferenceManager;

public class ParticleWallActivity extends Activity 
{
	/** Hold a reference to our GLSurfaceView */
	private GLSurfaceView mGLSurfaceView;
    private SensorManager mSensorManager;

	@Override
	public void onCreate(Bundle savedInstanceState) 
	{
		super.onCreate(savedInstanceState);
	    // set default preferences
		PreferenceManager.setDefaultValues(this, R.xml.particlewallpaperpreferences, false);
		mGLSurfaceView = new GLSurfaceView(this);

        // Get an instance of the SensorManager
        mSensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);

		// Check if the system supports OpenGL ES 2.0.
		final ActivityManager activityManager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
		final ConfigurationInfo configurationInfo = activityManager.getDeviceConfigurationInfo();
		final boolean supportsEs2 = configurationInfo.reqGlEsVersion >= 0x20000;

		if (supportsEs2) 
		{
			// Request an OpenGL ES 2.0 compatible context.
			mGLSurfaceView.setEGLContextClientVersion(2);

			// Set the renderer to our demo renderer, defined below.
			mGLSurfaceView.setRenderer(new ParticleWallRenderer());
		} 
		else 
		{
			// This is where you could create an OpenGL ES 1.x compatible
			// renderer if you wanted to support both ES 1 and ES 2.
			return;
		}

		setContentView(mGLSurfaceView);
	}

	@Override
	protected void onResume() 
	{
		// The activity must call the GL surface view's onResume() on activity onResume().
		super.onResume();
	       //get data from settings activity in this case the language
        SharedPreferences settings = PreferenceManager.getDefaultSharedPreferences(this);
        int nparticles = settings.getInt("nparticles", 400);
        //GL2JNILib.setnparticles(nparticles);
        mGLSurfaceView.onResume();
	}

	@Override
	protected void onPause() 
	{
		// The activity must call the GL surface view's onPause() on activity onPause().
		super.onPause();
		mGLSurfaceView.onPause();
	}	
}