//
//  ExporterController.m
//  FakeFaceTime
//
//  Created by Patrick Aubin on 7/7/17.
//  Copyright © 2017 com.paubins.FakeFaceTime. All rights reserved.
//

#import "ExporterController.h"


@implementation ExporterController

+ (void)export:(NSURL *)exportUrl fromOutput:(NSArray *)outputFiles handler:(void (^)(NSURL*))handler{
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    CMTime currentTime = kCMTimeZero;
    
    NSMutableArray* videoAssets = [[[NSArray alloc] init] mutableCopy];
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = nil;
    AVMutableCompositionTrack *audioComposition = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];;
    
    for (int i = 0; i < outputFiles.count; i++) {
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:(NSURL *)outputFiles[i] options:nil];
        [videoAssets addObject:videoAsset];

        clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        
        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                       ofTrack:clipVideoTrack
                                        atTime:currentTime error:nil];
        
        if (0 < [videoAsset tracksWithMediaType:AVMediaTypeAudio].count) {
            AVAssetTrack *sourceAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            [audioComposition insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:sourceAudioTrack atTime:currentTime error:nil]; //[asset duration]
        }
        
        currentTime = CMTimeAdd(currentTime, videoAsset.duration);
        
//        [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
        
    }
    
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    
    assetExport.outputURL = exportUrl;
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    assetExport.shouldOptimizeForNetworkUse = YES;

    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         switch (assetExport.status) {
             case AVAssetExportSessionStatusFailed:{
                 NSLog(@"Fail");
                 NSLog(@"asset export fail error : %@", assetExport.error);
                 
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    
                                });
                 break;
             }
             case AVAssetExportSessionStatusCompleted:{
                 NSLog(@"Success");
                 UISaveVideoAtPathToSavedPhotosAlbum(assetExport.outputURL.path, self, nil, nil);
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    handler(exportUrl);
                                });
                 break;
             }
                 
             default:
                 break;
         }
         
     }       
     ];   
}

+ (void) overlapVideos {
    
    //First load your videos using AVURLAsset. Make sure you give the correct path of your videos.
    
    AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"]] options:nil];
    AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"]] options:nil];
    
    //Create AVMutableComposition Object which will hold our multiple AVMutableCompositionTrack or we can say it will hold our multiple videos.
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    //Now we are creating the first AVMutableCompositionTrack containing our first video and add it to our AVMutableComposition object.
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //Repeat the same process for the 2nd track as we did above for the first track.
    AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    //See how we are creating AVMutableVideoCompositionInstruction object. This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects. You set the duration of the layer. You should add the length equal to the length of the longer asset in terms of duration.
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    
    //We will be creating 2 AVMutableVideoCompositionLayerInstruction objects. Each for our 2 AVMutableCompositionTrack. Here we are creating AVMutableVideoCompositionLayerInstruction for out first track. See how we make use of Affinetransform to move and scale our First Track. So it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
    //Note: You have to apply transformation to scale and move according to your video size.
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    CGAffineTransform Scale = CGAffineTransformMakeScale(0.6f,0.6f);
    CGAffineTransform Move = CGAffineTransformMakeTranslation(320,320);
    [FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
    
    //Here we are creating AVMutableVideoCompositionLayerInstruction for our second track.see how we make use of Affinetransform to move and scale our second Track.
    AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
    CGAffineTransform SecondScale = CGAffineTransformMakeScale(0.9f,0.9f);
    CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(0,0);
    [SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
    
    //Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
    
    //Now we create AVMutableVideoComposition object.We can add multiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.renderSize = CGSizeMake(640, 480);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *myPathDocs = [documentsDirectory stringByAppendingPathComponent:@"overlapVideo.mov"];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:myPathDocs])
    {
        [[NSFileManager defaultManager] removeItemAtPath:myPathDocs error:nil];
    }
    
    NSURL *url = [NSURL fileURLWithPath:myPathDocs];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = url;
    [exporter setVideoComposition:MainCompositionInst];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
    {
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self exportDidFinish:exporter];
        });
    }];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage*)imageWithImage: (UIImage*)sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (CALayer *)createVideoLayer:(CGRect)bounds size:(CGSize)newSize {
    // a simple red rectangle
    CALayer *layer = [CALayer layer];
    layer.backgroundColor = NULL;
    layer.frame = bounds;
    
    UIImage *newImage = [ExporterController imageWithImage:[UIImage imageNamed:@"buttons"] scaledToWidth:newSize.width];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:newImage];
    imageView.frame = CGRectMake(bounds.size.width/2 - newImage.size.width/2, 70, newImage.size.width, newImage.size.height);
    
    CALayer *outLayer = [CALayer layer];
    outLayer.frame = layer.bounds;
    outLayer.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.3f].CGColor;
    // add outer layer to inner layer
    [layer addSublayer:imageView.layer];
    
    return layer;
}


@end
