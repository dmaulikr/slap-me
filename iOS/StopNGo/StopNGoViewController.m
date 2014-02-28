/*
     File: StopNGoViewController.m
 Abstract: Document that captures stills to a QuickTime movie
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */
 
#import "StopNGoViewController.h"
#include <mach/mach_time.h>
#import <AssetsLibrary/AssetsLibrary.h>
@implementation StopNGoViewController

@synthesize previewView, fpsSlider, startFinishButton, takePictureButton;

- (BOOL)setupAVCapture
{
    [self switchSesions];
	
	return YES;
}

-(void)switchSesions
{
	NSError *error = nil;
    // 5 fps - taking 5 pictures will equal 1 second of video
	frameDuration = CMTimeMakeWithSeconds(1./5., 90000);
	
	AVCaptureSession *session = [AVCaptureSession new];
	[session setSessionPreset:AVCaptureSessionPresetHigh];
	
	// Select a video device, make an input
	AVCaptureDevice *backCamera;
    
    
    if (_isFrontCameraActive) {
        _isFrontCameraActive = NO;
        	backCamera = [self frontCamera];
        NSLog(@"front now");
        
    } else {
        	backCamera = [self backCamera];
        _isFrontCameraActive = YES;
        NSLog(@"back now");
    }
    
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
	if ([session canAddInput:input])
		[session addInput:input];
	
	// Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	if ([session canAddOutput:stillImageOutput])
		[session addOutput:stillImageOutput];
	
	// Make a preview layer so we can see the visual output of an AVCaptureSession
	AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	[previewLayer setFrame:[previewView bounds]];
	
    // add the preview layer to the hierarchy
    CALayer *rootLayer = [previewView layer];
	[rootLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[rootLayer addSublayer:previewLayer];
    
	
    // start the capture session running, note this is an async operation
    // status is provided via notifications such as AVCaptureSessionDidStartRunningNotification/AVCaptureSessionDidStopRunningNotification
    [session startRunning];
}

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

- (BOOL)setupAssetWriterForURL:(NSURL *)fileURL formatDescription:(CMFormatDescriptionRef)formatDescription
{
    // allocate the writer object with our output file URL
	NSError *error = nil;
	assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
	if (error)
		return NO;
	
    // initialized a new input for video to receive sample buffers for writing
    // passing nil for outputSettings instructs the input to pass through appended samples, doing no processing before they are written
	assetWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:nil];
	[assetWriterInput setExpectsMediaDataInRealTime:YES];
	if ([assetWriter canAddInput:assetWriterInput])
		[assetWriter addInput:assetWriterInput];
	
    // specify the prefered transform for the output file
	CGFloat rotationDegrees;
	switch ([[UIDevice currentDevice] orientation]) { 
		case UIDeviceOrientationPortraitUpsideDown:
			rotationDegrees = -90.;
			break;
		case UIDeviceOrientationLandscapeLeft: // no rotation
			rotationDegrees = 0.;
			break;
		case UIDeviceOrientationLandscapeRight:
			rotationDegrees = 180.;
			break;
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationUnknown:
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			rotationDegrees = 90.;
			break;
	}
	CGFloat rotationRadians = DegreesToRadians(rotationDegrees);
	[assetWriterInput setTransform:CGAffineTransformMakeRotation(rotationRadians)];
	
    // initiates a sample-writing at time 0
	nextPTS = kCMTimeZero;
	[assetWriter startWriting];
	[assetWriter startSessionAtSourceTime:nextPTS];
	
    return YES;
}

- (IBAction)takePicture:(id)sender
{
    NSTimer *timerToStop;
    if (!_isTakingPictures) {
        _isTakingPictures = YES;
        takePictureButton.title = @"Snaping";
        _pictureTimer = [NSTimer scheduledTimerWithTimeInterval: .2
                                                         target: self
                                                       selector:@selector(takePictureForTimer)
                                                       userInfo: nil repeats:YES];
        

        
        
        
timerToStop = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(stopAndFinish) userInfo:nil repeats:NO];
        
        
    } else {
        _isTakingPictures = NO;
        takePictureButton.title = @"Contintue snaping";
        [_pictureTimer invalidate];
        [timerToStop invalidate];
    }
   
}

- (AVCaptureDevice *)frontCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)backCamera {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    return nil;
}


- (UIImage*)imageByCombiningImage:(UIImage*)firstImage withImage:(UIImage*)secondImage {
    UIImage *image = nil;
    
    CGSize newImageSize = CGSizeMake(MAX(firstImage.size.width, secondImage.size.width), MAX(firstImage.size.height, secondImage.size.height));
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(newImageSize, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(newImageSize);
    }
    [firstImage drawAtPoint:CGPointMake(roundf((newImageSize.width-firstImage.size.width)/2),
                                        roundf((newImageSize.height-firstImage.size.height)/2))];
    [secondImage drawAtPoint:CGPointMake(roundf((newImageSize.width-secondImage.size.width)/2),
                                         roundf((newImageSize.height-secondImage.size.height)/2))];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}




-(void)takePictureForTimer{
    
    [self switchSesions];

        

        
        // initiate a still image capture, return immediately
        // the completionHandler is called when a sample buffer has been captured
        AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
//    CMTimeShow(stillImageConnection.videoMinFrameDuration);
//    CMTimeShow(stillImageConnection.videoMaxFrameDuration);
//    
//    if (stillImageConnection.isVideoMinFrameDurationSupported)
//        stillImageConnection.videoMinFrameDuration = CMTimeMake(1, 5);
//    if (stillImageConnection.isVideoMaxFrameDurationSupported)
//        stillImageConnection.videoMaxFrameDuration = CMTimeMake(1, 5);
//    
//    CMTimeShow(stillImageConnection.videoMinFrameDuration);
//    CMTimeShow(stillImageConnection.videoMaxFrameDuration);
    
    
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *__strong error) {
                                                          
                                                          // set up the AVAssetWriter using the format description from the first sample buffer captured
                                                          if ( !assetWriter ) {
                                                              outputURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%llu.mov", NSTemporaryDirectory(), mach_absolute_time()]];
                                                              //NSLog(@"Writing movie to \"%@\"", outputURL);
                                                              CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(imageDataSampleBuffer);
                                                              
                                                              if ( NO == [self setupAssetWriterForURL:outputURL formatDescription:formatDescription] )
                                                                  return;
                                                          }
                                                          
                                                        
                                                          
                                                          // re-time the sample buffer - in this sample frameDuration is set to 5 fps
                                                          CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
                                                          timingInfo.duration = frameDuration;
                                                          timingInfo.presentationTimeStamp = nextPTS;
                                                          CMSampleBufferRef sbufWithNewTiming = NULL;
                                                          
                                                          
                                                          NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                          if (jpegData) {
                                                              NSLog(@"got jpeg");
                                                            
                                                              
                                                              // add image
                                                              UIImage *image = [UIImage imageWithData:jpegData];
                                                              
                                                              
                                                              
//                                                              [self saveImage:[self scaleImage:image toSize:CGSizeMake(768, 1280)] withIndex:_countToTwo];
                                                              
                                                              [_arrayOfImages addObject:[self scaleImage:image toSize:CGSizeMake(200, 300)]];

                                                              
//                                                              UIImage *usePreviousImage;
//                                                              
//                                                              if (!_previousImage) {
//                                                                  CGSize imageSize = CGSizeMake(3264,2448);
//                                                                  UIColor *fillColor = [UIColor blackColor];
//                                                                  UIGraphicsBeginImageContextWithOptions(imageSize, YES, 0);
//                                                                  CGContextRef context = UIGraphicsGetCurrentContext();
//                                                                  [fillColor setFill];
//                                                                  CGContextFillRect(context, CGRectMake(0, 0, imageSize.width, imageSize.height));
//                                                                  UIImage *blackimage = UIGraphicsGetImageFromCurrentImageContext();
//                                                                  UIGraphicsEndImageContext();
//                                                                  
//                                                                  usePreviousImage = blackimage;
//
//                                                              } else {
//                                                                  usePreviousImage = _previousImage;
//                                                              }
//                                                              if (_countToTwo < 1) {
//                                                                  NSLog(@"got into it");

//                                                              if (image) {
//                                                                  NSLog(@"got uiimage");
//                                                                  
//
//                                                                  CGSize size = CGSizeMake(image.size.width, image.size.height + usePreviousImage.size.height);
//                                                                  
//                                                                  UIGraphicsBeginImageContext(size);
//                                                                  
//                                                                  [image drawInRect:CGRectMake(0,0,size.width, image.size.height)];
//                                                                  [usePreviousImage drawInRect:CGRectMake(0,image.size.height,size.width, usePreviousImage.size.height)];
//                                                                  
//                                                                  UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
//                                                                  
//                                                                  UIGraphicsEndImageContext();
//                                                                  
//                                                                  //Add image to view
////                                                                  UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, finalImage.size.width, finalImage.size.height)];
//                                                                 
//                                                                  _testPreview.image = finalImage;
//                                                                  
////                                                                  _testPreview.image = [self imageByCombiningImage:image withImage:image];
//
//
//                                                                 
//                                                                      _previousImage = image;
//                                                                  
//                                                                  }
                                                              


                                                                  

                                                                
//                                                              }
//                                                              else {
//                                                                  _countToTwo = 0;
//                                                                  NSLog(@"count was restet");
//                                                              }

                                                          }
                                                          
                                                          
//                                                          NSData *imageToVideoData = UIImageJPEGRepresentation(_testPreview.image, 65);
                                                          
                                                          
                                                          OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault,
                                                                                                               imageDataSampleBuffer,
                                                                                                               1, // numSampleTimingEntries
                                                                                                               &timingInfo,
                                                                                                               &sbufWithNewTiming);
                                                          
                                                          if (err)
                                                              return;
                                                          
                                                          // append the sample buffer if we can and increment presnetation time
                                                          if ( [assetWriterInput isReadyForMoreMediaData] ) {
                                                              if ([assetWriterInput appendSampleBuffer:sbufWithNewTiming]) {
                                                                  nextPTS = CMTimeAdd(frameDuration, nextPTS);
                                                              }
                                                              else {
                                                                  NSError *error = [assetWriter error];
                                                                  NSLog(@"failed to append sbuf: %@", error);
                                                              }
                                                          }
                                                          
                                                          // release the copy of the sample buffer we made
                                                          CFRelease(sbufWithNewTiming);
                                                      }];
    


}
- (UIImage *) scaleImage:(UIImage *)image toSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)saveImage: (UIImage*)image withIndex:(int)index
{
    if (image != nil)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                             NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"new%d.png", index] ];
        NSData* data = UIImagePNGRepresentation(image);
        [data writeToFile:path atomically:YES];
    }
}


- (void)saveMovieToCameraRoll
{
    // save the movie to the camera roll
//	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	//NSLog(@"writing \"%@\" to photos album", outputURL);
//	[library writeVideoAtPathToSavedPhotosAlbum:outputURL
//								completionBlock:^(NSURL *assetURL, NSError *error) {
//									if (error) {
//										NSLog(@"assets library failed (%@)", error);
//									}
//									else {
//										[[NSFileManager defaultManager] removeItemAtURL:outputURL error:&error];
//										if (error)
//											NSLog(@"Couldn't remove temporary movie file \"%@\"", outputURL);
//									}
//									outputURL = nil;
//								}];
    
    for (int i = 0; i < [_arrayOfImages count]-1; i+=2) {
        
        UIImage *firstImage = [_arrayOfImages objectAtIndex:i];
        UIImage *secondImage = [_arrayOfImages objectAtIndex:i+1];
        CGSize size = CGSizeMake(firstImage.size.width + secondImage.size.width, firstImage.size.height);
        
                                                                          UIGraphicsBeginImageContext(size);
        
                                                                          [firstImage drawInRect:CGRectMake(0,0,firstImage.size.width, firstImage.size.height)];
                                                                          [secondImage drawInRect:CGRectMake(firstImage.size.width, 0 ,secondImage.size.width, secondImage.size.height)];
        
                                                                         UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
        
                                                                        UIGraphicsEndImageContext();
        


        [self saveImage:finalImage withIndex:_countToTwo];
        _countToTwo = _countToTwo + 1;
        

    }
    
    [self showPreviewAnimation];
    

//    [_arrayOfImages removeAllObjects];
    
//    UIImageView * animatedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 400,600)];
//    
////    NSArray *imageNames = @[@"bird1.png", @"bird2.png"];
////    animTime =.0;
//    [animatedImageView setAnimationImages:_arrayOfImages] ;
//    animatedImageView.animationDuration =  1;
//    animatedImageView.animationRepeatCount = 2;
//    [self.view addSubview: animatedImageView];
//    [animatedImageView startAnimating];
}


-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:videoSettings] ;
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:0] CGImage] size:CGSizeMake(480, 320)];
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    
    _forFrameRate += 1;
    CMTime frameTime = CMTimeMake(1, duration);
    CMTime lastTime = CMTimeMake(_forFrameRate, duration);
    
    
    CMTime presentTime = CMTimeAdd(lastTime, frameTime);
    NSLog(@"presentTime = %f",CMTimeGetSeconds(presentTime));
    
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    int i = 0;
    while (writerInput.readyForMoreMediaData) // every iteration i add my CGImage to buffer, but after 5th iteration readyForMoreMediaData sets to NO, Why???
    {
        NSLog(@"inside for loop %d",i);
        CMTime frameTime = CMTimeMake(1, 10);
        CMTime lastTime=CMTimeMake(i, 100);
        CMTime presentTime=CMTimeAdd(lastTime, frameTime);
        
        if (i >= [array count])
        {
            buffer = NULL;
        }
        else
        {
            buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:i] CGImage] size:CGSizeMake(480, 320)];
        }
        //CVBufferRetain(buffer);
        
        if (buffer)
        {
            // append buffer
            [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            i++;
        }
        else
        {
            // done!
            
            //Finish the session:
            [writerInput markAsFinished];
            [videoWriter finishWriting];
            
            CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
          
            NSLog (@"Done");
            // [imageArray removeAllObjects];
            
            break;
            
            
        }
    }
    
}

-(void)cleanUp
{
    _imutableArrayOfImages = nil;
    [self cleanFileFromDocyments:@"png"];
    [self cleanFileFromDocyments:@"mp4"];
}

-(CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    status=status;//Added to make the stupid compiler not show a stupid warning.
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    //CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    //CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(void)showPreviewAnimation
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray *pngs = [[NSBundle bundleWithPath:[paths objectAtIndex:0]] pathsForResourcesOfType:@"png" inDirectory:nil];
    
    NSLog(@"image paths: %@", pngs);
    
    UIImageView * animatedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320,440)];
    animatedImageView.contentMode  = UIViewContentModeScaleAspectFit;
    animatedImageView.clipsToBounds = YES;
    
    NSMutableArray *arrayOfImages = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [pngs count]; i++) {
        NSLog(@"number %d is ok", i);
        NSLog(@"image named: %@", [pngs objectAtIndex:i]);
        NSString *fullPath = [pngs objectAtIndex:i];
        NSLog(@"fullPath %@", fullPath);
//        NSString *strippedPath  = [fullPath stringByDeletingLastPathComponent];
//        NSLog(@"stripptedPath %@", strippedPath);
        [arrayOfImages addObject:[UIImage imageWithContentsOfFile:fullPath]];
    }

    NSLog(@"our array of images %@", arrayOfImages);
    _imutableArrayOfImages = [arrayOfImages copy];
    
    [self performSelectorInBackground:@selector(saveVideoForSelectorCall) withObject:nil];
    [animatedImageView setAnimationImages:arrayOfImages] ;
        animatedImageView.animationDuration =  3;
        animatedImageView.animationRepeatCount = 1;
        [self.view addSubview: animatedImageView];
        [animatedImageView startAnimating];

}

-(void)saveVideoForSelectorCall
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:@"newVideo.mp4" ];
     [self writeImageAsMovie:_imutableArrayOfImages toPath:path size:CGSizeMake(480, 320) duration:5];
    
    [self performSelector:@selector(cleanUp) withObject:nil afterDelay:3];
}

- (IBAction)startStop:(id)sender
{
	if (started) {
		if (assetWriter) {
			[assetWriterInput markAsFinished];
			[assetWriter finishWriting];
			assetWriterInput = nil;
			assetWriter = nil;
			[self saveMovieToCameraRoll];
		}
		[sender setTitle:@"Get Ready!"];
		[takePictureButton setEnabled:NO];
        

        
	}
	else {
		[sender setTitle:@"Finish"];
		[takePictureButton setEnabled:YES];
		
	}
	started = !started;
}

-(void)stopAndFinish {
    [self takePicture:nil];
    [self startStop:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self setupAVCapture];
    
    [self cleanFileFromDocyments:@"png"];
    [self cleanFileFromDocyments:@"mp4"];
    
    _forFrameRate = 1;

    
    _arrayOfImages = [[NSMutableArray alloc] initWithCapacity:0];
    
    _isTakingPictures = NO;
    _isFrontCameraActive = NO;
    _isItSecondTime = NO;
    
    _countToTwo = 0;
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)cleanFileFromDocyments:(NSString *)ext
{
    NSString *extension = ext;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        
        if ([[filename pathExtension] isEqualToString:extension]) {
            
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return ( UIInterfaceOrientationPortrait == interfaceOrientation );
}


//---alternative
/*
- (void) writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path {
    
    NSString *documents = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    documents = [documents stringByAppendingPathComponent:@"/ourVideo"];
    
    //NSLog(path);
    NSString *filename = [documents stringByAppendingPathComponent:[array objectAtIndex:0]];
    UIImage *first = [UIImage imageWithContentsOfFile:filename];
    
    
    CGSize frameSize = first.size;
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                   nil];
    
    
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                        assetWriterInputWithMediaType:AVMediaTypeVideo
                                        outputSettings:videoSettings];
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32ARGB] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:attributes];
    
    [videoWriter addInput:writerInput];
    
    // fixes all errors
    writerInput.expectsMediaDataInRealTime = YES;
    
    //Start a session:
    BOOL start = [videoWriter startWriting];
    NSLog(@"Session started? %d", start);
    [videoWriter startSessionAtSourceTime:kCMTimeZero];

    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[first CGImage]];
    BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    if (result == NO) //failes on 3GS, but works on iphone 4
        NSLog(@"failed to append buffer");
    
    if(buffer)
        CVBufferRelease(buffer);
    
    [NSThread sleepForTimeInterval:0.05];
    
    
    int reverseSort = NO;
    NSArray *newArray = [array sortedArrayUsingFunction:sort context:&reverseSort];
    
    delta = 1.0/[newArray count];
    
    int fps = (int)fpsSlider.value;
    
    int i = 0;
    for (NSString *filename in newArray)
    {
        if (adaptor.assetWriterInput.readyForMoreMediaData)
        {
            
            i++;
            NSLog(@"inside for loop %d %@ ",i, filename);
            CMTime frameTime = CMTimeMake(1, fps);
            CMTime lastTime=CMTimeMake(i, fps);
            CMTime presentTime=CMTimeAdd(lastTime, frameTime);
            
            NSString *filePath = [documents stringByAppendingPathComponent:filename];
            
            UIImage *imgFrame = [UIImage imageWithContentsOfFile:filePath] ;
            buffer = [self pixelBufferFromCGImage:[imgFrame CGImage]];
            BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            
            if (result == NO) //failes on 3GS, but works on iphone 4
            {
                NSLog(@"failed to append buffer");
                NSLog(@"The error is %@", [videoWriter error]);
            }
            if(buffer)
                CVBufferRelease(buffer);
            [NSThread sleepForTimeInterval:0.05];
        }
        else
        {
            NSLog(@"error");
            i--;
        }
        [NSThread sleepForTimeInterval:0.02];
    }
    
    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter finishWriting];
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);

}
 

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                        CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                        &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGAffineTransform flipVertical = CGAffineTransformMake(
                                                           1, 0, 0, -1, 0, CGImageGetHeight(image)
                                                           );
    CGContextConcatCTM(context, flipVertical);
    
    
    
    CGAffineTransform flipHorizontal = CGAffineTransformMake(
                                                             -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0
                                                             );
    
    CGContextConcatCTM(context, flipHorizontal);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
 */

//alternative 2
/*
-(void) writeImagesToMovieAtPath:(NSString *) path withSize:(CGSize) size
{
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath error:nil];
    for (NSString *tString in dirContents)
    {
        if ([tString isEqualToString:@"essai.mp4"])
        {
            [[NSFileManager defaultManager]removeItemAtPath:[NSString stringWithFormat:@"%@/%@",documentsDirectoryPath,tString] error:nil];
        }
    }
    NSLog(@"Write Started");
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4
                                                              error:&error];
    NSParameterAssert(videoWriter);
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                             assetWriterInputWithMediaType:AVMediaTypeVideo
                                             outputSettings:videoSettings] ;
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    [videoWriter addInput:videoWriterInput];
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    //Video encoding
    CVPixelBufferRef buffer = NULL;
    //convert uiimage to CGImage.
    int frameCount = 0;
    for(int i = 0; i<[_arrayOfImages count]; i++)
    {
        buffer = [self pixelBufferFromCGImage:[[_arrayOfImages objectAtIndex:i] CGImage] andSize:size];
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) 10);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                CVPixelBufferPoolRef bufferPool = adaptor.pixelBufferPool;
                NSParameterAssert(bufferPool != NULL);
                [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok)
        {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        frameCount++;
        CVBufferRelease(buffer);
    }
    [videoWriterInput markAsFinished];
    [videoWriter finishWriting];
    [_arrayOfImages removeAllObjects];
    NSLog(@"Write Ended");
}

- (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    status=status;//Added to make the stupid compiler not show a stupid warning.
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    //CGContextTranslateCTM(context, 0, CGImageGetHeight(image));
    //CGContextScaleCTM(context, 1.0, -1.0);//Flip vertically to account for different origin
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
 */

@end
