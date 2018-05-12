package com.hmmmgames.particlewallpaper;

import java.io.File;
import java.io.FileOutputStream;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.Log;

/**
 * This class implements our custom renderer. Note that the GL10 parameter passed in is unused for OpenGL ES 2.0
 * renderers -- the static class GLES20 is used instead.
 */
public class ParticleWallRenderer implements GLSurfaceView.Renderer 
{
	/** Used for debug logs. */
	private static final String TAG = "ParticleWallRenderer";
//	private static boolean firstLoad = true;
	private static String systemWallpaper = "none";
	public int rwidth,rheight;
	@Override
	public void onSurfaceCreated(GL10 glUnused, EGLConfig config) 
	{
//		if(firstLoad)
//		{
		int[] maxTextureSize = new int[1];
		GLES20.glGetIntegerv(GLES20.GL_MAX_TEXTURE_SIZE, maxTextureSize, 0);
		//Log.i("renderer","maxTextureSize = "+String.valueOf(maxTextureSize[0]));
		BitmapDrawable aBitmap = ParticleWallpaperService.engine.myWallpaperBitmap;
		Bitmap theBitmap = aBitmap.getBitmap();
		int theHeight = theBitmap.getHeight();
		int theWidth = theBitmap.getWidth();
		
//		if(ParticleWallpaperService.useSystemBackground)
//		{
			//Log.i("renderer","theBitmap width = "+String.valueOf(theWidth)+
			//		" height = "+String.valueOf(theHeight));
			// rescale the texture to 1024 max if larger
			int maxSize = Math.min(Math.max(theHeight, theWidth),maxTextureSize[0]);
			//Log.i("renderer","max image dimension required = "+String.valueOf(maxSize));
			float factor = (float) 1.0;
			if(theHeight > maxSize || theWidth > maxSize)
			{
				if(theHeight >= theWidth)
				{
					factor = (float)theHeight/(float)maxSize;
				}
				else
				{
					factor = (float)theWidth/(float)maxSize;
				}
				factor = factor*(float)1.0;
			}
			//Log.i("renderer","factor = "+String.valueOf(factor));
			int newHeight = (int) (theHeight/factor);
			int newWidth = (int) (theWidth/factor);
			//Log.i("renderer","resizedBitmap width = "+String.valueOf(newWidth)+
			//		" height = "+String.valueOf(newHeight));		
			Bitmap resizedBitmap =  Bitmap.createScaledBitmap(theBitmap, newHeight, newWidth, true);
			Log.i("renderer","onSurfaceCreated called..");
	//		int bytes = theBitmap.getRowBytes()*theBitmap.getHeight();
	        String filename = "/current_wallpaper.jpg";
	        File sd = ParticleWallpaperService.filesDir;
	        File dest = new File(sd, filename);
	        systemWallpaper = dest.toString();
	        try 
	        {
	        	 //Log.i("bitmap", dest.toString());
	             FileOutputStream out = new FileOutputStream(dest);
	             resizedBitmap.compress(Bitmap.CompressFormat.JPEG, 90, out);
	             out.flush();
	             out.close();
	        } 
	        catch (Exception e) 
	        {
	             e.printStackTrace();
	        }
	        resizedBitmap.recycle();
//		}
		GL2JNILib.initGLpipeline(systemWallpaper,theWidth,theHeight);
	}	
		
	@Override
	public void onSurfaceChanged(GL10 glUnused, int width, int height) 
	{
		//GLES20.glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		rwidth = width;
		rheight = height;
        GL2JNILib.init(width,height);
	}	

	@Override
	public void onDrawFrame(GL10 glUnused) 
	{
        GL2JNILib.step();
	}				
}
