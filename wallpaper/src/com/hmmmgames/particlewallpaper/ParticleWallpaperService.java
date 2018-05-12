package com.hmmmgames.particlewallpaper;

//import com.example.android.livecubes.cube2.CubeWallpaper2;

import java.io.File;

import net.rbgrn.android.glwallpaperservice.GLWallpaperService;
import android.app.WallpaperManager;
import android.content.SharedPreferences;
import android.content.res.AssetManager;
import android.graphics.drawable.BitmapDrawable;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.SurfaceHolder;
import android.widget.Toast;

public class ParticleWallpaperService extends GLWallpaperService {

	public static final String PREFERENCES = "com.hmmmgames.particlewallpaper.preferences";
    //SharedPreferences prefs = this.getSharedPreferences(PREFERENCES,MODE_PRIVATE);
    //get data from settings activity in this case the language
	private SensorManager sm;
    private float mSensorX;
    private float mSensorY;
    private int mRotation;
    public static BitmapDrawable myWallpaperBitmap;
    public static MyEngine engine;
    public static File filesDir;
    public boolean keyUnlocked;
    public static boolean useSystemBackground;
    
    //private int nparticles;
    //private int particleSize;
    //WallpaperInfo myWallpaperInfo = myWallpaperManager.getWallpaperInfo();
       
	public ParticleWallpaperService() {
		super();
		//mRotation = this.myRotation;
	}

	public Engine onCreateEngine() {
		engine = new MyEngine();
		myWallpaperBitmap = engine.myWallpaperBitmap;
		return engine;
	}
    
	class MyEngine extends GLEngine implements
			SharedPreferences.OnSharedPreferenceChangeListener,
			SensorEventListener {
		ParticleWallRenderer renderer;
	    AssetManager assetManager;
	    WallpaperManager myWallpaperManager
	    = WallpaperManager.getInstance(getApplicationContext());
	    BitmapDrawable myWallpaperBitmap = (BitmapDrawable) myWallpaperManager.getDrawable();
        private SharedPreferences mPrefs;
        public int wpDesiredH,wpDesiredW;
        public boolean toastOverride;

		public MyEngine() {
			super();
			
//			if(myWallpaperInfo == null)
//			{
//			    Log.i("wallpaperinfo","..returned null!");
//			}
//			else
//			{
//				//Log.i("wallpaperinfo",myWallpaperInfo.toString());
//			}
	        //Log.i("dustengine","this is where the number of particles will be reported");
			// handle prefs, other initialization
			toastOverride = false;
	        filesDir = getFilesDir();
	        //Log.i("MyEngine","filesDir = "+filesDir.toString());
	        AssetManager assetManager = getAssets();
	        GL2JNILib.setJavaEnv(assetManager);
            mPrefs = ParticleWallpaperService.this.getSharedPreferences(PREFERENCES, 0);
	        //PreferenceManager.getDefaultSharedPreferences(getBaseContext());
	        PreferenceManager.setDefaultValues(getBaseContext(), PREFERENCES, MODE_WORLD_READABLE, R.xml.particlewallpaperpreferences, true);
			mPrefs.registerOnSharedPreferenceChangeListener(this);
			// check unlock key value
			keyUnlocked = mPrefs.getBoolean("keyUnlocked", false);
			Log.i("MyEngine","keyUnlocked = "+String.valueOf(keyUnlocked));
            onSharedPreferenceChanged(mPrefs, null);
//			Log.i("MyEngine","seekParticles = "+String.valueOf(nparticles)+" seekPartSize = "+
//			String.valueOf(particleSize));
			renderer = new ParticleWallRenderer();
			setEGLContextClientVersion(2);
			setRenderer(renderer);
			setRenderMode(RENDERMODE_CONTINUOUSLY);
//          int nparticles = mPrefs.getInt("seekParticles", 400);
//			int particleSize = mPrefs.getInt("seekPartSize", 6);
			// activate all initial settings
			GL2JNILib.init(renderer.rwidth, renderer.rheight);
			//Log.i("MyEndine","rwidth = "+String.valueOf(renderer.rwidth)+" rheight = "+String.valueOf(renderer.rheight));
		    GL2JNILib.setnparticles(mPrefs.getInt("seekParticles", 400),
		    		mPrefs.getInt("seekPartSize", 6));
			GL2JNILib.setOpacity(mPrefs.getInt("seekOpacity", 80));
			GL2JNILib.setBackground(mPrefs.getBoolean("useWallpaper", false));
			GL2JNILib.setGravity(mPrefs.getInt("seekGravity", 50));
			GL2JNILib.setAttract(mPrefs.getInt("seekAttract", 50));
			useSystemBackground = mPrefs.getBoolean("useWallpaper", false);
			GL2JNILib.setBackground(useSystemBackground);
			wpDesiredH = myWallpaperManager.getDesiredMinimumHeight();
			wpDesiredW = myWallpaperManager.getDesiredMinimumWidth();
			//Log.i("MyEngine","wpDesiredW = "+String.valueOf(wpDesiredW)+" wpDesiredH = "+
			//       String.valueOf(wpDesiredH));
			
//			try {
//				myWallpaperManager.setBitmap(myWallpaperBitmap.getBitmap());
//			} catch (IOException e) {
//				// TODO Auto-generated catch block
//				e.printStackTrace();
//			}
			// pass the Java env to the C/C++ side
		}
		

		public void onDestroy() {
			// Unregister this as listener
			sm.unregisterListener(this);

			// Kill renderer			
			renderer = null;

			setTouchEventsEnabled(false);

			super.onDestroy();
		}

		@Override
		public void onTouchEvent(MotionEvent event) {
			super.onTouchEvent(event);	
			float myY = event.getY();
			float myX = event.getX();
			int myAction = event.getAction();
			GL2JNILib.updateTouch(myX,myY,myAction);
//			Log.i("Tag..","Touch Event: myX = "+String.valueOf(myX)+" myY = "+String.valueOf(myY));
		}

		@Override
		public void onCreate(SurfaceHolder surfaceHolder) {
			super.onCreate(surfaceHolder);
			// check if in preview mode
			if(engine.isPreview())
			{
				Log.i("MyEngine","Running in Preview Mode");
				settingsReminder();
			}
			else
			{
				Log.i("MyEngine","Running in Real Mode");
			}
			// Add touch events
			setTouchEventsEnabled(true);
			// Get sensormanager and register as listener.
			sm = (SensorManager) getSystemService(SENSOR_SERVICE);
			Sensor orientationSensor = sm.getDefaultSensor(SensorManager.SENSOR_ORIENTATION);
			sm.registerListener(this, orientationSensor, SensorManager.SENSOR_DELAY_GAME);
		}

	    public void settingsReminder() {
	    	//display in short period of time

	    	String toastText = "Preparing partices, please wait.. :)";
			Toast myToast = Toast.makeText(getApplicationContext(), toastText, Toast.LENGTH_SHORT);
			myToast.setGravity(Gravity.CENTER_VERTICAL, 0, 0);
			myToast.show();
//	        AlertDialog.Builder bld = new AlertDialog.Builder(ParticleWallpaperService.this.getApplication());
//	        bld.setMessage("If you like this wallpaper and want to have even more control, push the settings button!");
//	        bld.setNeutralButton("OK", null);
//	        bld.setTitle("Have Even More Fun With Particles!");
//	        Log.d("MyEngine", "Showing alert dialog: settings reminder ");
//	        bld.create().show();
	    }
	    
		public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
		    Log.i("Tag..","Shared Preference Changed : key  = "+key);
		    if(key != null)
		    {
				if(key.contentEquals("seekParticles") || key.contentEquals("seekPartSize"))
				{
					int nparticles = sharedPreferences.getInt("seekParticles", 400);
					int particleSize = sharedPreferences.getInt("seekPartSize", 6);
				    GL2JNILib.setnparticles(nparticles,particleSize);
				}
				if(key.contentEquals("gravityOn"))
				{
					GL2JNILib.enableGravity(sharedPreferences.getBoolean("gravityOn", true));
				}
				if(key.contentEquals("touchOn"))
				{
					GL2JNILib.enableTouch(sharedPreferences.getBoolean("touchOn", true));
				}				
				if(key.contentEquals("seekOpacity"))
				{
					GL2JNILib.setOpacity(sharedPreferences.getInt("seekOpacity", 80));
				}				
				if(key.contentEquals("seekGravity"))
				{
					int gravity = sharedPreferences.getInt("seekGravity", 50);
//					Log.i("Tag..","setGravity = "+String.valueOf(gravity));
					GL2JNILib.setGravity(gravity);
				}				
				if(key.contentEquals("seekAttract"))
				{
					//int attract = sharedPreferences.getInt("seekAttract", 50);
//					Log.i("Tag..","setAttract = "+String.valueOf(attract));
					GL2JNILib.setAttract(sharedPreferences.getInt("seekAttract", 50));
				}
				if(key.contentEquals("useWallpaper"))
				{
					GL2JNILib.setBackground(mPrefs.getBoolean("useWallpaper", false));
				}
		    }
		}

		public void onAccuracyChanged(Sensor sensor, int accuracy) {
		}

		public void onSensorChanged(SensorEvent event) {
		    if (event.sensor.getType() != Sensor.TYPE_ACCELEROMETER)
                return;
            mSensorX = event.values[0];
            mSensorY = event.values[1];
            //Log.e("Tag..","mRotation = "+String.valueOf(getMyRotation())+"\n");
            GL2JNILib.accelerate(mSensorX,mSensorY,getMyRotation());
		}
		
        @Override
        public void onOffsetsChanged(float xOffset, float yOffset,
                float xStep, float yStep, int xPixels, int yPixels) {
//            Log.i("onOffsetsChanges"," xOffset="+String.valueOf(xOffset)+
//            		" yOffset="+String.valueOf(yOffset)+
//            		" xStep="+String.valueOf(xStep)+
//            		" yStep= "+String.valueOf(yStep)+"\n"+
//            		" xPixels="+String.valueOf(xPixels)+
//            		" yPixels="+String.valueOf(yPixels));
            GL2JNILib.offsetChanged(xOffset,yOffset,xStep,yStep,xPixels,yPixels);
        }
	}
}
