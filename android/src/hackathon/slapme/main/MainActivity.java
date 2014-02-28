package hackathon.slapme.main;

import hackathon.slap_me.R;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import android.app.Activity;
import android.content.Context;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Environment;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;

public class MainActivity extends Activity {

	ImageView imageViewMain;
	private Camera mCameraFront;
	private Preview mPreviewFront;
	
	private Camera mCameraBack;
	private Preview mPreviewBack;
	
	private CountDownTimer countDownTimer;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		mPreviewFront = new Preview(this);
		mPreviewBack = new Preview(this);				
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}

	public void takePhotoTimer(View view) {						
		
		countDownTimer = new CountDownTimer(10000,1000){
			boolean cameraSide = false;
					
		    public void onTick(long millisUntilFinished) {
		        if(cameraSide == false){
		        	 Log.e("Photo", "Taken Front as " + millisUntilFinished);	
		     		 safeCameraOpen(Camera.CameraInfo.CAMERA_FACING_FRONT);
		    		 mPreviewFront.setFrontCamera();
		        	 takePhotoFront();
		        	 cameraSide = true;
		         } else {
		        	 Log.e("Photo", "Taken Back as " + millisUntilFinished);
		     		 safeCameraOpen(Camera.CameraInfo.CAMERA_FACING_BACK);
		    		 mPreviewBack.setBackCamera();
		        	 takePhotoBack();
		        	 cameraSide = false;
		         }
		     }

		     public void onFinish() {
		         
		     }
		  }.start();
	}
	
	public void btnPhotoFront(View view) {
		safeCameraOpen(Camera.CameraInfo.CAMERA_FACING_FRONT);
		mPreviewFront.setFrontCamera();	
		takePhotoFront();
	}
	
	public void takePhotoFront() {
		try {		
			mCameraFront.takePicture(null, null, mPictureFront);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public void btnPhotoBack(View view) {	
		safeCameraOpen(Camera.CameraInfo.CAMERA_FACING_BACK);
		mPreviewBack.setBackCamera();	
		takePhotoBack();
	}

	public void takePhotoBack() {
		try {	
			mCameraBack.takePicture(null, null, mPictureBack);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
    PictureCallback mPictureBack = new PictureCallback() {
        @Override
        public void onPictureTaken(byte[] data, Camera camera) {
            File pictureFile = getOutputMediaFile();
            if (pictureFile == null) {
                return;
            }
            try {
                FileOutputStream fos = new FileOutputStream(pictureFile);
                fos.write(data);
                fos.close();
            } catch (FileNotFoundException e) {

            } catch (IOException e) {
            }
        }
    };
	
    PictureCallback mPictureFront = new PictureCallback() {
        @Override
        public void onPictureTaken(byte[] data, Camera camera) {
            File pictureFile = getOutputMediaFile();
            if (pictureFile == null) {
                return;
            }
            try {
                FileOutputStream fos = new FileOutputStream(pictureFile);
                fos.write(data);
                fos.close();
            } catch (FileNotFoundException e) {

            } catch (IOException e) {
            }
        }
    };
    
    private static File getOutputMediaFile() {
        File mediaStorageDir = new File(
                Environment
                        .getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "MyCameraApp");
        if (!mediaStorageDir.exists()) {
            if (!mediaStorageDir.mkdirs()) {
                Log.d("MyCameraApp", "failed to create directory");
                return null;
            }
        }
        // Create a media file name
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss")
                .format(new Date());
        File mediaFile;
        mediaFile = new File(mediaStorageDir.getPath() + File.separator
                + "IMG_" + timeStamp + ".jpg");

        return mediaFile;
    }
    
    private Size mSizeBack;
    private Size mSizeFront;
	
	private boolean safeCameraOpen(int id) {
	    boolean qOpened = false;
	  
	    try {
	    	if(id == Camera.CameraInfo.CAMERA_FACING_BACK) {
		        releaseCameraAndPreview();		        
		        
		        mCameraBack = Camera.open(id);
		        Camera.Parameters params = mCameraBack.getParameters();
		        List<Size> sizes = params.getSupportedPictureSizes();
		        // See which sizes the camera supports and choose one of those
		        if(mSizeBack == null) {
			        mSizeBack = sizes.get(0);
			        for(Size s : sizes) {
			        	if(s.width==1280 && s.height==720)
			        		mSizeBack = s;
			        	//Log.e("Size", "Width:" + s.width + " Height:" + s.height);
			        }
		        }
		        params.setPictureSize(mSizeBack.width, mSizeBack.height);
		        params.set("orientation", "portrait");
		        params.set("rotation", 90);
		        mCameraBack.setParameters(params);       		        
		        
		        qOpened = (mCameraBack != null);
	    	} else if (id == Camera.CameraInfo.CAMERA_FACING_FRONT){
		        releaseCameraAndPreview();		        
		        
		        mCameraFront = Camera.open(id);
		        Camera.Parameters params = mCameraFront.getParameters();
		        List<Size> sizes = params.getSupportedPictureSizes();
		        // See which sizes the camera supports and choose one of those
		        if(mSizeFront == null) {
		        	mSizeFront = sizes.get(0);
			        for(Size s : sizes) {
			        	if(s.width==1280 && s.height==720)
			        		mSizeFront = s;
			        	//Log.e("Size", "Width:" + s.width + " Height:" + s.height);
			        }
		        }
		        params.setPictureSize(mSizeFront.width, mSizeFront.height);
		        params.set("orientation", "portrait");
		        params.set("rotation", 270);
		        mCameraFront.setParameters(params);	        
		        
		        qOpened = (mCameraFront != null);	    		
	    	}
	    } catch (Exception e) {
	        Log.e(getString(R.string.app_name), "failed to open Camera");
	        e.printStackTrace();
	    }

	    return qOpened;    
	}

	private void releaseCameraAndPreview() {
		mPreviewBack.stopBackPreviewAndFreeCamera();
		mPreviewFront.stopFrontPreviewAndFreeCamera();		
	}
	
	class Preview extends ViewGroup implements SurfaceHolder.Callback {

	    SurfaceView mSurfaceView;
	    SurfaceHolder mHolder;
		private List<Size> mSupportedPreviewSizes;

	    /**
	     * When this function returns, mCamera will be null.
	     */
	    public void stopFrontPreviewAndFreeCamera() {	        
	        if (mCameraFront != null) {
	            // Call stopPreview() to stop updating the preview surface.
	        	mCameraFront.stopPreview();
	        
	            // Important: Call release() to release the camera for use by other
	            // applications. Applications should release the camera immediately
	            // during onPause() and re-open() it during onResume()).
	        	mCameraFront.release();
	        
	        	mCameraFront = null;
	        }
	    }
	    
	    /**
	     * When this function returns, mCamera will be null.
	     */
	    public void stopBackPreviewAndFreeCamera() {
	        if (mCameraBack != null) {
	            // Call stopPreview() to stop updating the preview surface.
	            mCameraBack.stopPreview();
	        
	            // Important: Call release() to release the camera for use by other
	            // applications. Applications should release the camera immediately
	            // during onPause() and re-open() it during onResume()).
	            mCameraBack.release();
	        
	            mCameraBack = null;
	        }
	    }
	    
	    public void setFrontCamera() {	               
	        if (mCameraFront != null) {
	            List<Size> localSizes = mCameraFront.getParameters().getSupportedPreviewSizes();
	            mSupportedPreviewSizes = localSizes;
	            requestLayout();
	          
	            try {
	                mCameraFront.setPreviewDisplay(mHolder);
	            } catch (IOException e) {
	                e.printStackTrace();
	            }
	          
	            // Important: Call startPreview() to start updating the preview
	            // surface. Preview must be started before you can take a picture.
	            mCameraFront.startPreview();
	        }
	    }
	    
	    public void setBackCamera() {	 
	        if (mCameraBack != null) {
	            List<Size> localSizes = mCameraBack.getParameters().getSupportedPreviewSizes();
	            mSupportedPreviewSizes = localSizes;
	            requestLayout();
	          
	            try {
	            	mCameraBack.setPreviewDisplay(mHolder);
	            } catch (IOException e) {
	                e.printStackTrace();
	            }
	          
	            // Important: Call startPreview() to start updating the preview
	            // surface. Preview must be started before you can take a picture.
	            mCameraBack.startPreview();
	        }
	    }

	    Preview(Context context) {
	        super(context);

	        mSurfaceView = new SurfaceView(context);
	        addView(mSurfaceView);
	        //mSurfaceView = (SurfaceView)findViewById(R.id.surfaceview_top);

	        // Install a SurfaceHolder.Callback so we get notified when the
	        // underlying surface is created and destroyed.
	        mHolder = mSurfaceView.getHolder();
	        mHolder.addCallback(this);
	        mHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
	    }

		@Override
		public void surfaceCreated(SurfaceHolder holder) {
		}

		@Override
		public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
			if(mCameraFront != null) {
			    // Now that the size is known, set up the camera parameters and begin
			    // the preview.
			    Camera.Parameters parameters = mCameraFront.getParameters();
			    //parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
			    requestLayout();
			    mCameraFront.setParameters(parameters);
	
			    // Important: Call startPreview() to start updating the preview surface.
			    // Preview must be started before you can take a picture.
			    mCameraFront.startPreview();
			}
			
			if(mCameraBack != null) {
			    // Now that the size is known, set up the camera parameters and begin
			    // the preview.
			    Camera.Parameters parameters = mCameraBack.getParameters();
			    //parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
			    requestLayout();
			    mCameraBack.setParameters(parameters);
	
			    // Important: Call startPreview() to start updating the preview surface.
			    // Preview must be started before you can take a picture.
			    mCameraBack.startPreview();
			}
		}

		@Override
	    public void surfaceDestroyed(SurfaceHolder holder) {
	        // Surface will be destroyed when we return, so stop the preview.
			stopFrontPreviewAndFreeCamera();
			stopBackPreviewAndFreeCamera();	
	    }

		@Override
		protected void onLayout(boolean changed, int l, int t, int r, int b) {
		}
	}
	
	public int getScreenWidth() {
		RelativeLayout rlMain = (RelativeLayout)findViewById(R.id.relativelayout_main);
		return rlMain.getWidth();
	}
	
	public int getScreenHeight() {
		RelativeLayout rlMain = (RelativeLayout)findViewById(R.id.relativelayout_main);
		return rlMain.getHeight();
	}
	
}
