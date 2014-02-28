package hackathon.slapme.service;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.media.ExifInterface;

public class ImageService {

	public ImageService() {}
	
	public static Bitmap combineImages(File c, File s) {
		return combineImages(loadAndRotateBitmapFromFile(c),loadAndRotateBitmapFromFile(s));
	}
	
	public static Bitmap combineImages(Bitmap c, Bitmap s) 
	{ 
	    Bitmap cs = null; 

	    int width, height = 0; 

	    width = c.getWidth() + s.getWidth(); 
	    height = c.getHeight(); 	    

	    cs = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888); 

	    Canvas comboImage = new Canvas(cs); 

	    comboImage.drawBitmap(c, 0f, 0f, null); 
	    comboImage.drawBitmap(s, c.getWidth(), 0f, null); 

	    return cs; 
	} 
	
	public static void saveBitmapToFile(String filename, Bitmap mBitmap) {
	    FileOutputStream fos;
	    try {
	        fos = new FileOutputStream(filename);
	        mBitmap.compress(CompressFormat.JPEG, 30, fos);
	        fos.flush();
	        fos.close();
	    } catch (FileNotFoundException e) {
	        e.printStackTrace();
	    } catch (IOException e) {
	        e.printStackTrace();
	    }
	}
	
	public static Bitmap loadBitmapFromFile(File file) {
		if (file == null) {
			throw new IllegalArgumentException("file = " + file);
		}
		Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath());		
		return bitmap;
	}
	
	public static Bitmap loadScaledBitmapFromFile(File file) {
		if (file == null) {
			throw new IllegalArgumentException("file = " + file);
		}
		
		final BitmapFactory.Options options = new BitmapFactory.Options();

	    // Calculate inSampleSize
	    options.inSampleSize = 8;

	    // Decode bitmap with inSampleSize set
	    options.inJustDecodeBounds = false;
	    
	    Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath(), options);		
		return bitmap;
		
	} 
	
	public static Bitmap loadAndRotateBitmapFromFile(File file) {
		if (file == null) {
			throw new IllegalArgumentException("file = " + file);
		}
		Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath());
		ExifInterface exif = null;
		
		try {
			exif = new ExifInterface(file.getPath());			
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		int rotation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);  
		int rotationInDegrees = exifToDegrees(rotation);
		
		Matrix matrix = new Matrix();
		if (rotation != 0f) {
			matrix.preRotate(rotationInDegrees);
		}
		
		Bitmap rotated = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
		bitmap.recycle();
		return rotated;
	}
	
	private static int exifToDegrees(int exifOrientation) {        
	    if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90) { return 90; } 
	    else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_180) {  return 180; } 
	    else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_270) {  return 270; }            
	    return 0;    
	 }	
}
