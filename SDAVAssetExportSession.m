//
//  SDAVAssetExportSession.m
//
// This file is part of the SDAVAssetExportSession package.
//
// Created by Olivier Poitrey <rs@dailymotion.com> on 13/03/13.
// Copyright 2013 Olivier Poitrey. All rights servered.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//


#import "SDAVAssetExportSession.h"
#import <AVFoundation/AVFoundation.h>

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetReaderOutput.h>

#import <CoreMedia/CMSampleBuffer.h>

@interface SDAVAssetExportSession ()

@property (nonatomic, assign, readwrite) float progress;

@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVAssetReaderVideoCompositionOutput *videoOutput;
@property (nonatomic, strong) AVAssetReaderAudioMixOutput *audioOutput;
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) dispatch_queue_t inputQueue;
@property (nonatomic, strong) void (^completionHandler)(void);

@end

@implementation SDAVAssetExportSession
{
    NSError *_error;
    NSTimeInterval duration;
    CMTime lastSamplePresentationTime;
}

+ (id)exportSessionWithAsset:(AVAsset *)asset
{
    return [SDAVAssetExportSession.alloc initWithAsset:asset];
}

- (id)initWithAsset:(AVAsset *)asset
{
    if ((self = [super init]))
    {
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
        [self initWithAlpha];
    }

    return self;
}

- (NSString*) getResourcePath:(NSString*)resFilename
{
    NSBundle* appBundle = [NSBundle mainBundle];
    NSString* movieFilePath = [appBundle pathForResource:resFilename ofType:nil];
    NSAssert(movieFilePath, @"movieFilePath is nil");
    return movieFilePath;
}

- (void)initWithAlpha {
    NSString *alphaFilename = @"01161_old_film_look_paper_texture.mov";

    NSString *alphaPath = [self getResourcePath:alphaFilename];
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                        forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    NSURL *urlAlpha = [NSURL fileURLWithPath:alphaPath];
    
    self.avUrlAssetAlpha = [[AVURLAsset alloc] initWithURL:urlAlpha options:options];
    NSAssert(self.avUrlAssetAlpha, @"AVURLAsset");
    
    NSError *assetError = nil;
    
    self.aVAssetReaderAlpha = [[AVAssetReader alloc] initWithAsset:self.avUrlAssetAlpha error:nil];
    NSAssert(self.aVAssetReaderAlpha, @"aVAssetReaderAlpha");
    
    // This video setting indicates that native 32 bit endian pixels with a leading
    // ignored alpha channel will be emitted by the decoding process.
    
    NSDictionary *videoSettings = @{
                                    (id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]
                                    };
    
    NSArray *videoTracksAlpha =  [self.avUrlAssetAlpha tracksWithMediaType:AVMediaTypeVideo];
    
    NSAssert([videoTracksAlpha count] == 1, @"only 1 video track can be decoded");
    
    AVAssetTrack *videoTrackAlpha = [videoTracksAlpha objectAtIndex:0];
    
    AVAssetReaderTrackOutput *aVAssetReaderOutputAlpha = [AVAssetReaderTrackOutput
                                                          assetReaderTrackOutputWithTrack:videoTrackAlpha
                                                          outputSettings:videoSettings];
    
    [self.aVAssetReaderAlpha addOutput:aVAssetReaderOutputAlpha];
    self.outputAlpha = (AVAssetReaderTrackOutput *)[self.aVAssetReaderAlpha.outputs objectAtIndex:0];
    
//    NSAssert(self.worked, @"AVAssetReaderVideoCompositionOutput failed");
}

- (void)exportAsynchronouslyWithCompletionHandler:(void (^)(void))handler
{
    NSParameterAssert(handler != nil);
    [self cancelExport];
    self.completionHandler = handler;

    if (!self.outputURL)
    {
        _error = [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@
        {
            NSLocalizedDescriptionKey: @"Output URL not set"
        }];
        handler();
        return;
    }

    NSError *readerError;
    self.reader = [AVAssetReader.alloc initWithAsset:self.asset error:&readerError];
    if (readerError)
    {
        _error = readerError;
        handler();
        return;
    }

    NSError *writerError;
    self.writer = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:self.outputFileType error:&writerError];
    if (writerError)
    {
        _error = writerError;
        handler();
        return;
    }

    self.reader.timeRange = self.timeRange;
    self.writer.shouldOptimizeForNetworkUse = self.shouldOptimizeForNetworkUse;
    self.writer.metadata = self.metadata;

    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];


    if (CMTIME_IS_VALID(self.timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(self.timeRange.duration))
    {
        duration = CMTimeGetSeconds(self.timeRange.duration);
    }
    else
    {
        duration = CMTimeGetSeconds(self.asset.duration);
    }
    //
    // Video output
    //
    if (videoTracks.count > 0) {
        self.videoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:self.videoInputSettings];
        self.videoOutput.alwaysCopiesSampleData = NO;
        if (self.videoComposition)
        {
            self.videoOutput.videoComposition = self.videoComposition;
        }
        else
        {
            self.videoOutput.videoComposition = [self buildDefaultVideoComposition];
        }
        if ([self.reader canAddOutput:self.videoOutput])
        {
            [self.reader addOutput:self.videoOutput];
        }

        //
        // Video input
        //
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
        self.videoInput.expectsMediaDataInRealTime = NO;
        if ([self.writer canAddInput:self.videoInput])
        {
            [self.writer addInput:self.videoInput];
        }
        NSDictionary *pixelBufferAttributes = @
        {
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferWidthKey: @(self.videoOutput.videoComposition.renderSize.width),
            (id)kCVPixelBufferHeightKey: @(self.videoOutput.videoComposition.renderSize.height),
            @"IOSurfaceOpenGLESTextureCompatibility": @YES,
            @"IOSurfaceOpenGLESFBOCompatibility": @YES,
        };
        self.videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];
    }

    //
    //Audio output
    //
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
      self.audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
      self.audioOutput.alwaysCopiesSampleData = NO;
      self.audioOutput.audioMix = self.audioMix;
      if ([self.reader canAddOutput:self.audioOutput])
      {
          [self.reader addOutput:self.audioOutput];
      }
    } else {
        // Just in case this gets reused
        self.audioOutput = nil;
    }

    //
    // Audio input
    //
    if (self.audioOutput) {
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
        self.audioInput.expectsMediaDataInRealTime = NO;
        if ([self.writer canAddInput:self.audioInput])
        {
            [self.writer addInput:self.audioInput];
        }
    }
    
    [self.writer startWriting];
    [self.reader startReading];
    [self.aVAssetReaderAlpha startReading];
    [self.writer startSessionAtSourceTime:self.timeRange.start];

    __block BOOL videoCompleted = NO;
    __block BOOL audioCompleted = NO;
    __weak typeof(self) wself = self;
    self.inputQueue = dispatch_queue_create("VideoEncoderInputQueue", DISPATCH_QUEUE_SERIAL);
    if (videoTracks.count > 0) {
        [self.videoInput requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^
        {
            if (![wself encodeReadySamplesFromOutput:wself.videoOutput toInput:wself.videoInput])
            {
                @synchronized(wself)
                {
                    videoCompleted = YES;
                    if (audioCompleted)
                    {
                        [wself finish];
                    }
                }
            }
        }];
    }
    else {
        videoCompleted = YES;
    }
    
    if (!self.audioOutput) {
        audioCompleted = YES;
    } else {
        [self.audioInput requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^
         {
             if (![wself encodeReadySamplesFromOutput:wself.audioOutput toInput:wself.audioInput])
             {
                 @synchronized(wself)
                 {
                     audioCompleted = YES;
                     if (videoCompleted)
                     {
                         [wself finish];
                     }
                 }
             }
         }];
    }
}

- (BOOL)encodeReadySamplesFromOutput:(AVAssetReaderOutput *)output toInput:(AVAssetWriterInput *)input
{
    while (input.isReadyForMoreMediaData)
    {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if (sampleBuffer)
        {
            BOOL handled = NO;
            BOOL error = NO;

            if (self.reader.status != AVAssetReaderStatusReading || self.writer.status != AVAssetWriterStatusWriting)
            {
                handled = YES;
                error = YES;
            }
            
            if (!handled && self.videoOutput == output)
            {
                // update the video progress
                lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                lastSamplePresentationTime = CMTimeSubtract(lastSamplePresentationTime, self.timeRange.start);
                self.progress = duration == 0 ? 1 : CMTimeGetSeconds(lastSamplePresentationTime) / duration;

                if ([self.delegate respondsToSelector:@selector(exportSession:renderFrame:withPresentationTime:toBuffer:)])
                {
                    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
                    CVPixelBufferRef renderBuffer = NULL;
                    CVPixelBufferPoolCreatePixelBuffer(NULL, self.videoPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
                    [self.delegate exportSession:self renderFrame:pixelBuffer withPresentationTime:lastSamplePresentationTime toBuffer:renderBuffer];
                    if (![self.videoPixelBufferAdaptor appendPixelBuffer:renderBuffer withPresentationTime:lastSamplePresentationTime])
                    {
                        error = YES;
                    }
                    CVPixelBufferRelease(renderBuffer);
                    handled = YES;
                }
            }
            
            
//            NSAssert(self.worked, @"AVAssetReaderVideoCompositionOutput failed");
            
            if (!handled && self.videoOutput == output)
            {
                CMSampleBufferRef sampleBufferAlpha = [self.outputAlpha copyNextSampleBuffer];
                
                if (sampleBufferAlpha == NULL) {
                    [self.aVAssetReaderAlpha cancelReading];
                    self.outputAlpha = (AVAssetReaderTrackOutput *)[self.aVAssetReaderAlpha.outputs objectAtIndex:0];
                    self.worked = [self.aVAssetReaderAlpha startReading];
                    NSAssert(self.worked, @"AVAssetReaderVideoCompositionOutput failed");
                    sampleBufferAlpha = [self.outputAlpha copyNextSampleBuffer];
                }
                
                UIImage *maskedImg = [self renderAsUIImage:sampleBuffer sampleBufferAlpha:sampleBufferAlpha];
                CFRelease(sampleBufferAlpha);
            }
            
            
            if (!handled && ![input appendSampleBuffer:sampleBuffer])
            {
                error = YES;
            }
            CFRelease(sampleBuffer);

            if (error)
            {
                return NO;
            }
        }
        else
        {
            [input markAsFinished];
            return NO;
        }
    }

    return YES;
}


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
    
    UIImage *img = [self renderMaskedUIImage:cgImageRefRGB maskImgRef:cgImageRefAlpha];
    
    CGImageRelease(cgImageRefRGB);
    CGImageRelease(cgImageRefAlpha);
    
    CGDataProviderRelease(dataProviderRGB);
    CGDataProviderRelease(dataProviderAlpha);
    
    CVPixelBufferUnlockBaseAddress(imageBufferRGB, 0);
    CVPixelBufferUnlockBaseAddress(imageBufferAlpha, 0);
    
    return img;
}

- (UIImage*) renderMaskedUIImage:(CGImageRef)rgbImageRef
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

- (AVMutableVideoComposition *)buildDefaultVideoComposition
{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];

    // get the frame rate from videoSettings, if not set then try to get it from the video track,
    // if not set (mainly when asset is AVComposition) then use the default frame rate of 30
    float trackFrameRate = 0;
    if (self.videoSettings)
    {
        NSDictionary *videoCompressionProperties = [self.videoSettings objectForKey:AVVideoCompressionPropertiesKey];
        if (videoCompressionProperties)
        {
            NSNumber *frameRate = [videoCompressionProperties objectForKey:AVVideoAverageNonDroppableFrameRateKey];
            if (frameRate)
            {
                trackFrameRate = frameRate.floatValue;
            }
        }
    }
    else
    {
        trackFrameRate = [videoTrack nominalFrameRate];
    }

    if (trackFrameRate == 0)
    {
        trackFrameRate = 30;
    }

	videoComposition.frameDuration = CMTimeMake(1, trackFrameRate);
	CGSize targetSize = CGSizeMake([self.videoSettings[AVVideoWidthKey] floatValue], [self.videoSettings[AVVideoHeightKey] floatValue]);
	CGSize naturalSize = [videoTrack naturalSize];
	CGAffineTransform transform = videoTrack.preferredTransform;
	// Workaround radar 31928389, see https://github.com/rs/SDAVAssetExportSession/pull/70 for more info
	if (transform.ty == -560) {
		transform.ty = 0;
	}

	if (transform.tx == -560) {
		transform.tx = 0;
	}

	CGFloat videoAngleInDegree  = atan2(transform.b, transform.a) * 180 / M_PI;
	if (videoAngleInDegree == 90 || videoAngleInDegree == -90) {
		CGFloat width = naturalSize.width;
		naturalSize.width = naturalSize.height;
		naturalSize.height = width;
	}
	videoComposition.renderSize = naturalSize;
	// center inside
	{
		float ratio;
		float xratio = targetSize.width / naturalSize.width;
		float yratio = targetSize.height / naturalSize.height;
		ratio = MIN(xratio, yratio);

		float postWidth = naturalSize.width * ratio;
		float postHeight = naturalSize.height * ratio;
		float transx = (targetSize.width - postWidth) / 2;
		float transy = (targetSize.height - postHeight) / 2;

		CGAffineTransform matrix = CGAffineTransformMakeTranslation(transx / xratio, transy / yratio);
		matrix = CGAffineTransformScale(matrix, ratio / xratio, ratio / yratio);
		transform = CGAffineTransformConcat(transform, matrix);
	}

	// Make a "pass through video track" video composition.
	AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration);

	AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];

    [passThroughLayer setTransform:transform atTime:kCMTimeZero];

	passThroughInstruction.layerInstructions = @[passThroughLayer];
	videoComposition.instructions = @[passThroughInstruction];

    return videoComposition;
}

- (void)finish
{
    // Synchronized block to ensure we never cancel the writer before calling finishWritingWithCompletionHandler
    if (self.reader.status == AVAssetReaderStatusCancelled || self.writer.status == AVAssetWriterStatusCancelled)
    {
        return;
    }

    if (self.writer.status == AVAssetWriterStatusFailed)
    {
        [self complete];
    }
    else if (self.reader.status == AVAssetReaderStatusFailed) {
        [self.writer cancelWriting];
        [self complete];
    }
    else
    {
        [self.writer finishWritingWithCompletionHandler:^
        {
            [self complete];
        }];
    }
}

- (void)complete
{
    if (self.writer.status == AVAssetWriterStatusFailed || self.writer.status == AVAssetWriterStatusCancelled)
    {
        [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
    }

    if (self.completionHandler)
    {
        self.completionHandler();
        self.completionHandler = nil;
    }
}

- (NSError *)error
{
    if (_error)
    {
        return _error;
    }
    else
    {
        return self.writer.error ? : self.reader.error;
    }
}

- (AVAssetExportSessionStatus)status
{
    switch (self.writer.status)
    {
        default:
        case AVAssetWriterStatusUnknown:
            return AVAssetExportSessionStatusUnknown;
        case AVAssetWriterStatusWriting:
            return AVAssetExportSessionStatusExporting;
        case AVAssetWriterStatusFailed:
            return AVAssetExportSessionStatusFailed;
        case AVAssetWriterStatusCompleted:
            return AVAssetExportSessionStatusCompleted;
        case AVAssetWriterStatusCancelled:
            return AVAssetExportSessionStatusCancelled;
    }
}

- (void)cancelExport
{
    if (self.inputQueue)
    {
        dispatch_async(self.inputQueue, ^
        {
            [self.aVAssetReaderAlpha cancelReading];
            [self.writer cancelWriting];
            [self.reader cancelReading];
            [self complete];
            [self reset];
        });
    }
}

- (void)reset
{
    _error = nil;
    self.progress = 0;
    self.reader = nil;
    self.videoOutput = nil;
    self.audioOutput = nil;
    self.writer = nil;
    self.videoInput = nil;
    self.videoPixelBufferAdaptor = nil;
    self.audioInput = nil;
    self.inputQueue = nil;
    self.completionHandler = nil;
}

@end
