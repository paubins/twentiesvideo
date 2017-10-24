//
//  ViewController.m
//  PosterLoop
//
//  Created by Moses DeJong on 10/19/14.
//  Copyright (c) 2014 helpurock. All rights reserved.
//

#import "AlphaViewController.h"

#import <AVFoundation/AVFoundation.h>

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetReaderOutput.h>

#import <CoreMedia/CMSampleBuffer.h>

@interface AlphaViewController () <SDAVAssetExportSessionDelegate>

@end

@implementation AlphaViewController

- (id)init {
    if (self = [super init]) {
         self.images = [[[NSArray alloc] init] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

  NSAssert(self.imageView, @"imageView");
  
  self.view.backgroundColor = [UIColor greenColor];
  
  self.imageView.image = [UIImage imageNamed:@"question"];
   

  // Give app a little time to start up and begin processing events
  
  if (TRUE) {
  
  NSTimer *timer = [NSTimer timerWithTimeInterval: 1.0
                                           target: self
                                         selector: @selector(loadVideoContent)
                                         userInfo: NULL
                                          repeats: FALSE];
  
	[[NSRunLoop currentRunLoop] addTimer:timer forMode: NSDefaultRunLoopMode];
    
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
  
    NSLog(@"didReceiveMemoryWarning");
}

- (NSString*) getResourcePath:(NSString*)resFilename
{
	NSBundle* appBundle = [NSBundle mainBundle];
	NSString* movieFilePath = [appBundle pathForResource:resFilename ofType:nil];
  NSAssert(movieFilePath, @"movieFilePath is nil");
	return movieFilePath;
}



- (void)loadUpAssetWriter {
    self.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
    
    NSError *writerError;
    self.writer = [AVAssetWriter assetWriterWithURL:@"" fileType:@"mp4" error:&writerError];
    
    if (writerError) {
        
    }
    
    //
    // Video input
    //
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];

    if ([self.writer canAddInput:self.videoInput]) {
        [self.writer addInput:self.videoInput];
    }
    
    NSDictionary *pixelBufferAttributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferWidthKey: @(self.videoOutput.videoComposition.renderSize.width),
        (id)kCVPixelBufferHeightKey: @(self.videoOutput.videoComposition.renderSize.height),
        @"IOSurfaceOpenGLESTextureCompatibility": @YES,
        @"IOSurfaceOpenGLESFBOCompatibility": @YES,
    };
    
    self.videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];

    [self.writer startWriting];
}

// This method does a blocking load from 2 video input sources, the result
// is a series of PNG images.

- (void) loadVideoContent:(NSString *)rgbPath handler:(void (^)(NSString*))handler
{
  BOOL worked;
  
  // Define animated images in terms of the tmp path
  
  self.aniPrefix = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Poster.mov"];
  self.aniSuffix = ([UIScreen mainScreen].scale == 1.0f) ? @"" : @"@2x";
    
  NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Poster.mov"];
    
    [[NSFileManager defaultManager] removeItemAtURL:[[NSURL alloc] initFileURLWithPath:path] error:nil];
  
  NSString *rgbFilename = @"Poster_rgb_CRF_15_24BPP.m4v";
  NSString *alphaFilename = @"01161_old_film_look_paper_texture.mov";
  
//  NSString *rgbPath = [self getResourcePath:path];
  NSString *alphaPath = [self getResourcePath:alphaFilename];
  
  NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                      forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
  
  NSURL *urlRGB = [NSURL fileURLWithPath:rgbPath];
  NSURL *urlAlpha = [NSURL fileURLWithPath:alphaPath];
  
  AVURLAsset *avUrlAssetRGB = [[AVURLAsset alloc] initWithURL:urlRGB options:options];
  NSAssert(avUrlAssetRGB, @"AVURLAsset");

  AVURLAsset *avUrlAssetAlpha = [[AVURLAsset alloc] initWithURL:urlAlpha options:options];
  NSAssert(avUrlAssetAlpha, @"AVURLAsset");

  NSError *assetError = nil;
  
  AVAssetReader *aVAssetReaderRGB = [[AVAssetReader alloc] initWithAsset:avUrlAssetRGB error:nil];
  NSAssert(aVAssetReaderRGB, @"aVAssetReaderRGB");
  
  AVAssetReader *aVAssetReaderAlpha = [[AVAssetReader alloc] initWithAsset:avUrlAssetAlpha error:nil];
  NSAssert(aVAssetReaderAlpha, @"aVAssetReaderAlpha");
  
  // This video setting indicates that native 32 bit endian pixels with a leading
  // ignored alpha channel will be emitted by the decoding process.
  
    NSDictionary *videoSettings2 = @{
                                    (id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
                                    };
  
    NSArray *videoTracksRGB = [avUrlAssetRGB tracksWithMediaType:AVMediaTypeVideo];
  
  NSAssert([videoTracksRGB count] == 1, @"only 1 video track can be decoded");
  
  AVAssetTrack *videoTrackRGB = [videoTracksRGB objectAtIndex:0];
  
  NSArray *videoTracksAlpha =  [avUrlAssetAlpha tracksWithMediaType:AVMediaTypeVideo];
  
  NSAssert([videoTracksAlpha count] == 1, @"only 1 video track can be decoded");
  
  AVAssetTrack *videoTrackAlpha = [videoTracksAlpha objectAtIndex:0];

    AVAssetReaderTrackOutput *aVAssetReaderOutputRGB = [AVAssetReaderTrackOutput
                                                        assetReaderTrackOutputWithTrack:videoTrackRGB
                                                        outputSettings:videoSettings2];
  
    [aVAssetReaderRGB addOutput:aVAssetReaderOutputRGB];
    AVAssetReaderTrackOutput *outputRGB = [aVAssetReaderRGB.outputs objectAtIndex:0];

    AVAssetReaderTrackOutput *aVAssetReaderOutputAlpha = [AVAssetReaderTrackOutput
                                                          assetReaderTrackOutputWithTrack:videoTrackAlpha
                                                          outputSettings:videoSettings2];

   // connect aVAssetReaderAlpha to aVAssetReaderOutputAlpha here
    [aVAssetReaderAlpha addOutput:aVAssetReaderOutputAlpha];
    AVAssetReaderTrackOutput *outputAlpha = [aVAssetReaderAlpha.outputs objectAtIndex:0];

  worked = [aVAssetReaderRGB startReading];
  NSAssert(worked, @"AVAssetReaderVideoCompositionOutput failed");
  
  worked = [aVAssetReaderAlpha startReading];
  NSAssert(worked, @"AVAssetReaderVideoCompositionOutput failed");
  
  // numFrames is hard coded to 21 here to avoid having to calculate based on video duration
  
    CGSize frameSize = CGSizeMake(720, 1280);
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:
                                  [NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    
    if(error) {
        NSLog(@"error creating AssetWriter: %@",[error description]);
    }
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecTypeH264, AVVideoCodecKey,
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
    
  int numFrames = 0;

    CMTime presentTime = kCMTimeZero;

  CMSampleBufferRef sampleBufferRGB = [outputRGB copyNextSampleBuffer];
    
    while(sampleBufferRGB != NULL) {
        CMSampleBufferRef sampleBufferAlpha = NULL;
        sampleBufferAlpha = [outputAlpha copyNextSampleBuffer];
        
        if (sampleBufferAlpha == NULL) {
            [aVAssetReaderAlpha cancelReading];
            outputAlpha = [aVAssetReaderAlpha.outputs objectAtIndex:0];
            worked = [aVAssetReaderAlpha startReading];
            NSAssert(worked, @"AVAssetReaderVideoCompositionOutput failed");
            sampleBufferAlpha = [outputAlpha copyNextSampleBuffer];
        }
        
        @autoreleasepool {
            UIImage *maskedImg = nil;
            if ((int)CMTimeGetSeconds(presentTime) == 2) {
                maskedImg = self.images[0];
            } else {
                maskedImg = [self renderAsUIImage:sampleBufferRGB sampleBufferAlpha:sampleBufferAlpha];
            }
            
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                NSLog(@"inside for loop %d ", numFrames);
                CMTime frameTime = CMTimeMake(1, 30);
                CMTime lastTime = CMTimeMake(numFrames, 30);
                
                presentTime = CMTimeAdd(lastTime, frameTime);
                if (numFrames == 0) {
                    presentTime = kCMTimeZero;
                }
                
                CVPixelBufferRef buffer = NULL;
                buffer = [self pixelBufferFromCGImage:[maskedImg CGImage]];
                BOOL result = [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
                
                if (result == NO) //failes on 3GS, but works on iphone 4
                {
                    NSLog(@"failed to append buffer");
                    NSLog(@"The error is %@", [videoWriter error]);
                }
                if(buffer)
                    CVBufferRelease(buffer);
                
                numFrames += 1;
            }
            else
            {
                NSLog(@"error");
            }
        }
        
        if ((int)CMTimeGetSeconds(presentTime) != 2) {
           CFRelease(sampleBufferRGB);
        }
        
        CFRelease(sampleBufferAlpha);
        
        if ((int)CMTimeGetSeconds(presentTime) == 2) {
            
        } else {
            sampleBufferRGB = [outputRGB copyNextSampleBuffer];
        }
    }

    //Finish the session:
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
        
    }];
    
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
    

  [aVAssetReaderRGB cancelReading];
  [aVAssetReaderAlpha cancelReading];
    
    handler(path);
    
  return;
}

// Render RGB and Alpha data into a UIImage

- (UIImage *) renderAsUIImage:(CMSampleBufferRef)sampleBufferRGB
            sampleBufferAlpha:(CMSampleBufferRef)sampleBufferAlpha
{
  CVImageBufferRef imageBufferRGB = CMSampleBufferGetImageBuffer(sampleBufferRGB);
  CVImageBufferRef imageBufferAlpha = CMSampleBufferGetImageBuffer(sampleBufferAlpha);
  
  CVPixelBufferLockBaseAddress(imageBufferRGB, 0);
  CVPixelBufferLockBaseAddress(imageBufferAlpha, 0);
  
  // Under iOS, the output pixels are always as sRGB.
  
  CGColorSpaceRef colorSpace = NULL;

  colorSpace = CGColorSpaceCreateDeviceGray();

  NSAssert(colorSpace, @"colorSpace");
  
  // Create a Quartz direct-access data provider that uses data we supply.
  
  CGDataProviderRef dataProviderRGB =
  CGDataProviderCreateWithData(NULL,
                               CVPixelBufferGetBaseAddress(imageBufferRGB),
                               CVPixelBufferGetDataSize(imageBufferRGB), NULL);
  
  CGDataProviderRef dataProviderAlpha =
  CGDataProviderCreateWithData(NULL,
                               CVPixelBufferGetBaseAddress(imageBufferAlpha),
                               CVPixelBufferGetDataSize(imageBufferAlpha), NULL);
  
  CGImageRef cgImageRefRGB = CGImageCreate(CVPixelBufferGetWidth(imageBufferRGB),
                                        CVPixelBufferGetHeight(imageBufferRGB),
                                        8, 32, CVPixelBufferGetBytesPerRow(imageBufferRGB),
                                        colorSpace, kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst,
                                        dataProviderRGB, NULL, true, kCGRenderingIntentDefault);

  CGImageRef cgImageRefAlpha = CGImageCreate(CVPixelBufferGetWidth(imageBufferAlpha),
                                           CVPixelBufferGetHeight(imageBufferAlpha),
                                           8, 32, CVPixelBufferGetBytesPerRow(imageBufferAlpha),
                                           colorSpace, kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst,
                                           dataProviderAlpha, NULL, true, kCGRenderingIntentDefault);

  
	CGColorSpaceRelease(colorSpace);
  
  UIImage *img = [self.class renderMaskedUIImage:cgImageRefRGB maskImgRef:cgImageRefAlpha];

  CGImageRelease(cgImageRefRGB);
  CGImageRelease(cgImageRefAlpha);
  
  CGDataProviderRelease(dataProviderRGB);
  CGDataProviderRelease(dataProviderAlpha);
  
  CVPixelBufferUnlockBaseAddress(imageBufferRGB, 0);
  CVPixelBufferUnlockBaseAddress(imageBufferAlpha, 0);
  
  return img;
}

+ (UIImage*) renderMaskedUIImage:(CGImageRef)rgbImageRef
                      maskImgRef:(CGImageRef)maskImgRef
{
  // Create non-opaque ABGR bitmap the same size as the image, with the screen scale
  
  CGSize size = CGSizeMake(CGImageGetWidth(rgbImageRef), CGImageGetHeight(rgbImageRef));
  
  int scale = (int) [UIScreen mainScreen].scale;
  
//  if (scale == 1) {
//    // No-op
//  } else if (scale == 2) {
//    size.width = size.width / 2;
//    size.height = size.height / 3;
//  } else {
//    // WTF ?
//    NSAssert(FALSE, @"unhandled scale %d", scale);
//  }

  UIGraphicsBeginImageContextWithOptions(size, FALSE, scale);
  
  CGRect frame = CGRectZero;
  frame.size = size;
  
  CGContextRef currentContext = UIGraphicsGetCurrentContext();
  NSAssert(currentContext != nil, @"currentContext");
  
  CGContextTranslateCTM(currentContext, 0.0, size.height);
  CGContextScaleCTM(currentContext, 1.0, -1.0);
  
  CGContextClipToMask(currentContext, frame, maskImgRef);
  
  CGContextDrawImage(currentContext, frame, rgbImageRef);
  
  UIImage *rendered = UIGraphicsGetImageFromCurrentImageContext();
  
  // pop the context to get back to the default
  UIGraphicsEndImageContext();
  
  return rendered;
}

- (void) animateStep
{
  NSString *path = [NSString stringWithFormat:@"%@%d%@.png", self.aniPrefix, self.aniStep, self.aniSuffix];
    
  self.imageView.image = [UIImage imageWithContentsOfFile:path];
  
  int scale = (int) [UIScreen mainScreen].scale;
    
  NSLog(@"loaded \"%@\" with scale %d", path, (int)self.imageView.image.scale);
  
  if (self.aniStep == 21-1) {
    self.aniStep = 0;
  } else {
    self.aniStep = self.aniStep + 1;
  }
}

- (void)exportSession:(SDAVAssetExportSession *)exportSession renderFrame:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime toBuffer:(CVPixelBufferRef)renderBuffer {
    NSLog(@"exporting..");
    
    // Print the presentation times of the frames
    // CMTimeShow(presentationTime);
    
    // Print details -- just for the first frame
    if (presentationTime.value == 0)
    {
        OSType sourceFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
        OSType destFormat = CVPixelBufferGetPixelFormatType(renderBuffer);
        size_t dataSize = CVPixelBufferGetDataSize(pixelBuffer);
        
//        NSLog(@"source format: %d, dest format: %d, planar: %d, size: %zu", NSFileTypeForHFSTypeCode(sourceFormat), NSFileTypeForHFSTypeCode(destFormat), CVPixelBufferIsPlanar(pixelBuffer), dataSize);
    }
    
    // Copy the source pixel buffer to the output pixel buffer.
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CVPixelBufferLockBaseAddress(renderBuffer, 0);
    
    if (CVPixelBufferIsPlanar(pixelBuffer))
    {
        // Planar formats, such as kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange and kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.
        size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
        
        for (size_t i = 0; i < planeCount; i++)
        {
            int height = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
            
            void *pixelBufferBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
            void *renderBufferBaseAddress = CVPixelBufferGetBaseAddressOfPlane(renderBuffer, i);
            
            memcpy(renderBufferBaseAddress, pixelBufferBaseAddress, height * bytesPerRow);
        }
    }
    else
    {
        // Packed formats, such as kCVPixelFormatType_32BGRA, kCVPixelFormatType_32ARGB, and kCVPixelFormatType_422YpCbCr8.
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        void *pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        void *renderBufferBaseAddress = CVPixelBufferGetBaseAddress(renderBuffer);
        
        memcpy(renderBufferBaseAddress, pixelBufferBaseAddress, height * bytesPerRow);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(renderBuffer, 0);
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
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
//    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
//    CGAffineTransform flipVertical = CGAffineTransformMake(
//                                                           1, 0, 0, -1, 0, CGImageGetHeight(image)
//                                                           );
//    CGContextConcatCTM(context, flipVertical);
//
//
//
//    CGAffineTransform flipHorizontal = CGAffineTransformMake(
//                                                             -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0
//                                                             );
//
//    CGContextConcatCTM(context, flipHorizontal);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
