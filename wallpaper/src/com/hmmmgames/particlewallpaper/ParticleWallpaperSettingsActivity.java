/*
 * Copyright (C) 2010 Daniel Sundberg
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

import android.R.color;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.util.Log;
import android.widget.TextView;

import com.hmmmgames.particlewallpaper.util.IabHelper;
import com.hmmmgames.particlewallpaper.util.IabHelper.OnIabPurchaseFinishedListener;
import com.hmmmgames.particlewallpaper.util.IabResult;
import com.hmmmgames.particlewallpaper.util.Inventory;
import com.hmmmgames.particlewallpaper.util.Purchase;

public class ParticleWallpaperSettingsActivity extends PreferenceActivity
    implements SharedPreferences.OnSharedPreferenceChangeListener {
    static final String TAG = "SettingsActivity";
	
    IabHelper mHelper;
    //private String base64EncodedPublicKey = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0tyGbY2f7vi/ZR9OuOMIWipjzjYkHHcWHsgvBacN4+zEKEO+5ZLKX4bAm2je8jgkdJ58qOSLbOo5MQ2a5VF1I1MJuHx/zHyRwKznFqrobu414RExpXOg5mJr2pbs7dzNlGmi/az9CpVXzF7BSUDlh39FdOOIsqc8jKLL2MX8opUCH0Yaf83W6LPbb0GVf/neoS3MyvEh0Ht0VQJMBwqpmwHHvj634f9fu+sRVTk8KvB0RLrn+ZKodu065CHudhQbEwSeAxGyow85naNMSNxp5m7tJCo8xpXl8jiAKsm9VRhN88elEt27UXTSgA+udDjl25h/t8pw726jArm0YXC7bQIDAQAB";
    static final String SKU_UNLOCK_KEY = "unlock_features_key";
    private boolean isUnlocked;
    private String blorpa = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0tyGb";
    private String blorph = "Y2f7vi/ZR9OuOMIWipjzjYkHHcWHsgvBacN4+zEKEO+5ZLKX4b";
    private String blorpc = "Am2je8jgkdJ58qOSLbOo5MQ2a5VF1I1MJuHx/zHyRwKznFqrobu";
    private String blorpd = "414RExpXOg5mJr2pbs7dzNlGmi/az9CpVXzF7BSUDlh39F";
    private String blorpe = "dOOIsqc8jKLL2MX8opUCH0Yaf83W6LPbb0GVf/neoS3MyvEh0Ht0VQJ";
    private String blorpf = "MBwqpmwHHvj634f9fu+sRVTk8KvB0RLrn+ZKodu065CHudhQbEwSe";
    private String blorpg = "AxGyow85naNMSNxp5m7tJCo8xpXl8jiAKsm9VRhN88elEt27UXTSgA+udDj";
    private String blorpb = "l25h/t8pw726jArm0YXC7bQIDAQAB";
    private String base64EncodedPublicKey = blorpa+blorph+blorpc+blorpd+blorpe+blorpf+blorpg+blorpb;
    private SharedPreferences prefs;
    private AlertDialog diag = null;
    private boolean supportClicked;
	@Override 
	protected void onCreate(Bundle icicle) {
		super.onCreate(icicle);
		supportClicked = false;
		ParticleWallpaperService.engine.toastOverride = true;
		//addPreferencesFromResource(R.xml.preferences);
		setContentView(R.layout.main);
		getPreferenceManager().setSharedPreferencesName(ParticleWallpaperService.PREFERENCES);
		addPreferencesFromResource(R.xml.particlewallpaperpreferences);
        getPreferenceManager().getSharedPreferences().registerOnSharedPreferenceChangeListener(
                this);
        prefs = getSharedPreferences(ParticleWallpaperService.PREFERENCES,MODE_PRIVATE);
        getListView().setBackgroundColor(Color.WHITE);
        // set the initial unlock state
        isUnlocked = prefs.getBoolean("keyUnlocked", false);
        setUnlockState();
        // connect to Google Play to check unlock status

        // compute your public key and store it in base64EncodedPublicKey
        mHelper = new IabHelper(this, base64EncodedPublicKey);
        // enable debug logging (for a production application, you should set this to false).
        mHelper.enableDebugLogging(false);
        // Start setup. This is asynchronous and the specified listener
        // will be called once setup completes.
        Log.d(TAG, "Starting setup.");
        mHelper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
            public void onIabSetupFinished(IabResult result) {
                Log.d(TAG, "Setup finished.");

                if (!result.isSuccess()) {
                    // Oh noes, there was a problem.
                    Log.d(TAG,"Problem setting up in-app billing: " + result);
                    return;
                }

                // Hooray, IAB is fully set up. Now, let's get an inventory of stuff we own.
                Log.d(TAG, "Setup successful. Querying inventory.");
                mHelper.queryInventoryAsync(mGotInventoryListener);
            }
        });
        
//        getListView().setCacheColorHint(Color.BLACK);
//        getListView().setDrawingCacheBackgroundColor(Color.BLACK);
//        getListView().setDrawingCacheEnabled(true);
//        final Button unlockButton = (Button) findViewById(R.id.unlockButton);
        //button1.setVisibility(View.GONE);
//        unlockButton.setVisibility(View.VISIBLE);
//        getListView().setBackgroundColor(Color.BLACK);
        Preference keyUnlockedPref = findPreference("keyUnlocked");
        keyUnlockedPref.setOnPreferenceClickListener(new Preference.OnPreferenceClickListener() {
          public boolean onPreferenceClick(Preference p) {
        	  if(!isUnlocked){
        		supportClicked = true;
	        	mHelper.dispose();
	            mHelper = new IabHelper(ParticleWallpaperSettingsActivity.this, base64EncodedPublicKey);
	            // enable debug logging (for a production application, you should set this to false).
	            mHelper.enableDebugLogging(false);
	            // Start setup. This is asynchronous and the specified listener
	            // will be called once setup completes.
	            Log.d(TAG, "Starting setup.");
	            mHelper.startSetup(new IabHelper.OnIabSetupFinishedListener() {
	                public void onIabSetupFinished(IabResult result) {
	                    Log.d(TAG, "Setup finished.");
	
	                    if (!result.isSuccess()) {
	                        // Oh noes, there was a problem.
	                        Log.d(TAG,"Problem setting up in-app billing: " + result);
	                        return;
	                    }
	
	                    // Hooray, IAB is fully set up. Now, let's get an inventory of stuff we own.
	                    Log.d(TAG, "Setup successful. Querying inventory.");
	                    mHelper.queryInventoryAsync(mGotInventoryListener);
	                }
	            });
        	  }
        	  else
        	  {
        		  supportClicked = false;
        		  showHelpDialog();
        	  }
                return true;
            }
        });
	}
	
	void setUnlockState()
	{
        Preference keyUnlockedPref = findPreference("keyUnlocked");
        Log.i("preferences"," changing keyUnlocked = "+String.valueOf(isUnlocked));
        SharedPreferences.Editor editor = prefs.edit();
        editor.putBoolean("keyUnlocked", isUnlocked);
        editor.commit();  
//    	TextView keyUnlockedView = (TextView) this.findViewById(keyUnlockedPref.getLayoutResource());
//    	keyUnlockedView.setTextColor(Color.BLUE);
    	//        if(!isUnlocked)
        if(isUnlocked)
        {
        	keyUnlockedPref.setTitle("Thank You!");
        	keyUnlockedPref.setSummary("(Click for help)");
        }
        
        boolean allUnlocked = true;
        Preference seekParticles = findPreference("seekParticles");
        seekParticles.setEnabled(allUnlocked);
        Preference seekPartSize = findPreference("seekPartSize");
        seekPartSize.setEnabled(allUnlocked);        
        Preference seekOpacity = findPreference("seekOpacity");
        seekOpacity.setEnabled(allUnlocked);        
        Preference seekGravity = findPreference("seekGravity");
        seekGravity.setEnabled(allUnlocked);        
        Preference seekAttract = findPreference("seekAttract");
        seekAttract.setEnabled(allUnlocked);
        Preference useWallpaper = findPreference("useWallpaper");
        useWallpaper.setEnabled(allUnlocked);     
	}
	
    // Listener that's called when we finish querying the items and subscriptions we own
    IabHelper.QueryInventoryFinishedListener mGotInventoryListener = new IabHelper.QueryInventoryFinishedListener() {
        public void onQueryInventoryFinished(IabResult result, Inventory inventory) {
            Log.d(TAG, "Query inventory finished.");
            if (result.isFailure()) {
                Log.d(TAG,"Failed to query inventory: " + result);
                setUnlockState();
                return;
            }

            Log.d(TAG, "Query inventory was successful.");
            
            /*
             * Check for items we own. Notice that for each purchase, we check
             * the developer payload to see if it's correct! See
             * verifyDeveloperPayload().
             */
            
            // Do we have the premium upgrade?
            Purchase unlockPurchase = inventory.getPurchase(SKU_UNLOCK_KEY);
//            Purchase unlockPurchase = inventory.getPurchase("android.test.purchased");
            isUnlocked = (unlockPurchase != null && verifyDeveloperPayload(unlockPurchase));
            Log.d(TAG, "User is " + (isUnlocked ? "UNLOCKED" : "LOCKED"));
            if(supportClicked)
            {
            	askToPurchase();
            }
            Log.d(TAG, "Initial inventory query finished; enabling main UI.");
            setUnlockState();
        }
    };
    
    void showHelpDialog()
    {
    	String message;
    	message = "Use the sliders to change the way that the particles appear and behave."+
    			"  Press the back button after changing settings to see the effect.\n"+
    			"To set your own picture as the background, set the picture wallpaper "+
    			"like normal BEFORE turning on this live wallpaper, then check the "+
    			"'Use System Wallpaper' box to enable it!"
    			;
        AlertDialog.Builder bld = new AlertDialog.Builder(this);
        bld.setMessage(message);
        bld.setNeutralButton("OK", null);
        bld.setTitle("Have Some Fun With Particles!");
        Log.d(TAG, "Showing alert dialog: " + message);
        bld.create().show();
    }
    
    void askToPurchase() {
    	diag = null;
    	String message;
//    	message = "Unlock the full version to enable these great features\n"+
//                  "\n - Use your own backgrounds!\n - Change particle size"+
//      		      "\n - Change number of particles\n - Change touch force"+
//                  "\n - Change gravity force\n - And more!(soon)"+
//                  "\n\nYour support will encourage us to "+
//      		      "add new features and let us work on even cooler things!";
    	message = "Your support will encourage us to "+
    		      "add new features and let us work on even cooler things!";
        AlertDialog.Builder bld = new AlertDialog.Builder(this);
        //bld.setCancelable(false);
        bld.setMessage(message);
        bld.setNegativeButton("No Thanks.", null);
        bld.setPositiveButton("Yes!", new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int id) {
                //do what you want.
            	Log.d(TAG,"Unlock key purchase clicked!");
            	purchaseUnlockKey();
           }
       });
        bld.setTitle("Have Even More Fun With Particles!");
        Log.d(TAG, "Showing alert dialog: " + message);
        diag = bld.create();
        if(diag != null){diag.show();}
    }
    
    void purchaseUnlockKey()
    {
//    	IabHelper.OnIabPurchaseFinishedListener mPurchaseFinishedListener = null;

		OnIabPurchaseFinishedListener mPurchaseFinishedListener = new OnIabPurchaseFinishedListener() {
    	   public void onIabPurchaseFinished(IabResult result, Purchase purchase) 
    	   {
    	      if (result.isFailure()) {
    	         Log.d(TAG, "Error purchasing: " + result);
    	         return;
    	      }      
    	      else if (purchase.getSku().equals(SKU_UNLOCK_KEY)) {
    	         // give user access to premium content and update the UI
    	    	  Log.d(TAG,"Successfully purchased unlock key!");
    	    	  isUnlocked = true;
                  setUnlockState();
    	      }
    	   }
    	};
		mHelper.launchPurchaseFlow(this, SKU_UNLOCK_KEY, 10001,   
 			   mPurchaseFinishedListener, "test_purchase_string");
    }
    
    /** Verifies the developer payload of a purchase. */
    boolean verifyDeveloperPayload(Purchase p) {
        String payload = p.getDeveloperPayload();
        
        /*
         * TODO: verify that the developer payload of the purchase is correct. It will be
         * the same one that you sent when initiating the purchase.
         * 
         * WARNING: Locally generating a random string when starting a purchase and 
         * verifying it here might seem like a good approach, but this will fail in the 
         * case where the user purchases an item on one device and then uses your app on 
         * a different device, because on the other device you will not have access to the
         * random string you originally generated.
         *
         * So a good developer payload has these characteristics:
         * 
         * 1. If two different users purchase an item, the payload is different between them,
         *    so that one user's purchase can't be replayed to another user.
         * 
         * 2. The payload must be such that you can verify it even when the app wasn't the
         *    one who initiated the purchase flow (so that items purchased by the user on 
         *    one device work on other devices owned by the user).
         * 
         * Using your own server to store and verify developer payloads across app
         * installations is recommended.
         */
        
        return true;
    }

    @Override
    protected void onResume() {
        super.onResume();
    }
    
    @Override
    protected void onDestroy() {
        getPreferenceManager().getSharedPreferences().unregisterOnSharedPreferenceChangeListener(
                this);
        super.onDestroy();
        if (mHelper != null) mHelper.dispose();
        mHelper = null;
        
//        ParticleWallpaperService.engine.toastOverride = false;
        if(diag != null){diag.dismiss();}
        //getListView().invalidate();
    }

    public void onSharedPreferenceChanged(SharedPreferences sharedPreferences,
            String key) {
    }

}
