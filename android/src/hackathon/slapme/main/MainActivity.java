package hackathon.slapme.main;

import hackathon.slap_me.R;
import hackathon.slapme.service.Film;
import hackathon.slapme.service.ImageService;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.Size;
import android.net.Uri;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Environment;
import android.provider.MediaStore;
import android.provider.MediaStore.Video;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.ImageView;
import android.widget.TextView;

public class MainActivity extends Activity {

	ImageView imageViewMain;
	private Camera mCameraFront;
	private Preview mPreviewFront;
	
	private Camera mCameraBack;
	private Preview mPreviewBack;
	
	private CountDownTimer countDownTimer;	
	private TextView textViewMain;
	
	private static List<String> fileNames;
	
	private static File getMediaStorageDirectory(){
		return new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "MyCameraApp");
	}
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
		textViewMain = (TextView)findViewById(R.id.textview_main);
		
		View titleView = getWindow().findViewById(android.R.id.title);
	    if (titleView != null) {
	      ViewParent parent = titleView.getParent();
	      if (parent != null && (parent instanceof View)) {
	        View parentView = (View)parent;
	        parentView.setBackgroundColor(Color.parseColor("#f6ee31"));
	      }
	    }
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}
	
	// handle menu click
	@Override
	public boolean onOptionsItemSelected(final MenuItem item) {
		// Handle item selection
		switch (item.getItemId()) {

		case R.id.action_back:
			takePhotoBack();
			return true;
		case R.id.action_front:
			takePhotoFront();
			return true;
		case R.id.action_timer:
			takePhotoTimer();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}
	
	public void btnPhotoTimer(View view) {						
		takePhotoTimer();
	}
	
	public void takePhotoTimer() {
		increment = 0;
		fileNames = new ArrayList<String>();
		
		setCountDownTimer(new CountDownTimer(20000,1000){
			boolean cameraSide = false;
		    public void onTick(long millisUntilFinished) {
		        if(cameraSide == false){
		        	 Log.e("Photo", "Taken Front as " + millisUntilFinished);	
		        	 takePhotoFront();
		        	 cameraSide = true;
		         } else {
		        	 Log.e("Photo", "Taken Back as " + millisUntilFinished);
		        	 takePhotoBack();
		        	 cameraSide = false;
		         }
		     }
		    public void onFinish() {	
		    	 combinePhotos();
		    	 increment = -1;
		     }
		  }.start());
	}
	
	public void combinePhotos() {
		File mediaStorageDir = getMediaStorageDirectory();
		int combineIncrement = 1;
		
		File fileOne = null;
		File fileTwo = null;
		Bitmap combined;
		List<String> outputFiles = new ArrayList<String>();
		
		for(String fileName : fileNames){
			if(fileOne == null) {
				Log.e("Image","Loading One");
				textViewMain.setText("Loading Photos (Slap Me).");
				fileOne = new File(mediaStorageDir + "/" + fileName);
			} else if ( fileTwo == null ){
				fileTwo = new File(mediaStorageDir + "/" + fileName);
				Log.e("Image","Loading Two");
				if(fileOne != null && fileTwo != null) {
					textViewMain.setText("Combining Photos. (Slap You)");
					combined = ImageService.combineImages(fileOne, fileTwo);
					Log.e("Image","Combining");
					String outputFilename = mediaStorageDir + "/Combined_" + combineIncrement + ".jpg";
					ImageService.saveBitmapToFile(outputFilename , combined);
					outputFiles.add(outputFilename);
					Log.e("Image","Output Combined");
					combineIncrement++;
					fileOne.delete();
					fileTwo.delete();
					fileOne = null;
					fileTwo = null;
				}
			}
		}
		
		String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
		File outputVideo = new File(mediaStorageDir + "/CombinedOn" + timeStamp + ".mp4");
		Film film = null;
				
		try {
			Log.e("Film","Create");
			textViewMain.setText("Creating Video. (Slap Your Mum)");
			film = new Film(outputVideo);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		for(String fileName : outputFiles){
			Log.e("Film","Create frame from Bitmap");
			fileOne = new File(fileName);
			Bitmap output = ImageService.loadBitmapFromFile(fileOne);
			try {
				film.encodeImage(output);
			} catch (IOException e) {
				e.printStackTrace();
			}
			output.recycle();
			Log.e("Film","Added Frame");
			textViewMain.setText("Adding frames.");
		}
		
		try {
			film.finish();
			textViewMain.setText("Finished Yo. Slap Chat It");
			Log.e("Film","Finished");
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		if (mediaStorageDir.isDirectory()) {
	        String[] children = mediaStorageDir.list();
	        for (int i = 0; i < children.length; i++) {
	            if(!children[i].contains("CombinedOn")) {
	            	new File(mediaStorageDir, children[i]).delete();
	            }
	        }
	    }
		
		Intent intent = createShareIntent(outputVideo.getAbsolutePath());
		startActivity(Intent.createChooser(intent, "Share this with your Mum?"));		
	}
	
	public void btnPhotoFront(View view) {
		takePhotoFront();
	}
	
	public void takePhotoFront() {
		try {		
			textViewMain.setText("Takening Photo Front. (Slap Me)");
			mPreviewFront = new Preview(this);
			safeCameraOpen(Camera.CameraInfo.CAMERA_FACING_FRONT);
			mPreviewFront.setFrontCamera();	
			mCameraFront.takePicture(null, null, mPictureFront);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	public void btnPhotoBack(View view) {	
		takePhotoBack();
	}

	public void takePhotoBack() {
		try {	
			textViewMain.setText("Takening Photo Back. (Slap Your Mum)");
			mPreviewBack = new Preview(this);	
			safeCameraOpen(Camera.CameraInfo.CAMERA_FACING_BACK);
			mPreviewBack.setBackCamera();	
			mCameraBack.takePicture(null, null, mPictureBack);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
    PictureCallback mPictureBack = new PictureCallback() {
        @Override
        public void onPictureTaken(byte[] data, Camera camera) {
        	PictureTaken(data);
        }
    };
	
    PictureCallback mPictureFront = new PictureCallback() {
        @Override
        public void onPictureTaken(byte[] data, Camera camera) { 
        	PictureTaken(data);
        }
    };
    
    private void PictureTaken(byte[] data) {    	
    	File pictureFile;
    	
    	if(increment != -1) {
        	String fileName = String.valueOf(increment);
        	increment++;
        	pictureFile = getOutputMediaFile(fileName);	
        } else {
        	pictureFile = getOutputMediaFile();
        }
    	
        if (pictureFile == null) {
            return;
        }
        
        textViewMain.setText("Photo Taken.");
        
        try {
            FileOutputStream fos = new FileOutputStream(pictureFile);
            fos.write(data);
            fos.close();
        } catch (FileNotFoundException e) {

        } catch (IOException e) {
        }
    }
    
    private static int increment;
    
    private static File getOutputMediaFile() {
    	File mediaStorageDir = getMediaStorageDirectory();
        if (!mediaStorageDir.exists()) {
            if (!mediaStorageDir.mkdirs()) {
                Log.d("MyCameraApp", "failed to create directory");
                return null;
            }
        }
        
        // Create a media file name
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());                
        File mediaFile;
        mediaFile = new File(mediaStorageDir.getPath() + File.separator + "IMG_" + timeStamp + ".jpg");

        return mediaFile;
    }
    
    private static File getOutputMediaFile(String filename) {
        File mediaStorageDir = getMediaStorageDirectory();
        if (!mediaStorageDir.exists()) {
            if (!mediaStorageDir.mkdirs()) {
                Log.d("MyCameraApp", "failed to create directory");
                return null;
            }
        }
                                
        File mediaFile;
        String fileName = "IMG_" + increment + ".jpg";
        fileNames.add(fileName);               
        mediaFile = new File(mediaStorageDir.getPath() + File.separator + fileName);
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
		if(mPreviewBack != null) {
			mPreviewBack.stopBackPreviewAndFreeCamera();
		}
		if(mPreviewFront != null) {
			mPreviewFront.stopFrontPreviewAndFreeCamera();
		}
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
	        	
	        	mSurfaceView = null;
	        	mHolder.getSurface().release();
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
	            
	            mSurfaceView = null;
	            mHolder.getSurface().release();
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

	public CountDownTimer getCountDownTimer() {
		return countDownTimer;
	}

	public void setCountDownTimer(CountDownTimer countDownTimer) {
		this.countDownTimer = countDownTimer;
	}
	
	private Intent createShareIntent(String pathToVideo) {
	    
	    ContentValues content = new ContentValues(4);
	    content.put(Video.VideoColumns.TITLE, "Slap Chatted");
	    content.put(Video.VideoColumns.DATE_ADDED,
	    System.currentTimeMillis() / 1000);
	    content.put(Video.Media.MIME_TYPE, "video/mp4");
	    content.put(MediaStore.Video.Media.DATA, pathToVideo);
	    ContentResolver resolver = getContentResolver();
	    Uri uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
	    content);

	    Intent intent = new Intent(Intent.ACTION_SEND);
	    intent.setType("video/*");
	    intent.putExtra(Intent.EXTRA_STREAM, uri);
	    return intent;
	    //startActivity(Intent.createChooser(intent, "Share using"));
	}  
}