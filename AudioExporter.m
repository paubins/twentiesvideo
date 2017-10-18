//
//  AudioExporter.m
//  Stutter
//
//  Created by Patrick Aubin on 6/22/17.
//  Copyright © 2017 com.paubins.Stutter. All rights reserved.
//

#import "AudioExporter.h"

@implementation AudioExporter

+ (NSString *)getAudioFromVideo:(AVAsset *)asset handler:(void (^)(AVAssetExportSession*))handler {
    NSString *audioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"audio.caf"];
    
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    
    exportSession.outputURL = [NSURL fileURLWithPath:audioPath];
    exportSession.outputFileType = AVFileTypeCoreAudioFormat;
    exportSession.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
    }
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (exportSession.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed -> Reason: %@, User Info: %@",
                      exportSession.error.localizedDescription,
                      exportSession.error.userInfo.description);
                break;
                
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export cancelled");
                break;
                
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Export finished");
                handler(exportSession);
                NSLog(@"AudioLocation : %@", audioPath);
                break;
                
            default:
                break;
        }
    }];
    
    return audioPath;
}

@end
