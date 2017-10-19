//
//  AudioExporter.m
//  Stutter
//
//  Created by Patrick Aubin on 6/22/17.
//  Copyright © 2017 com.paubins.Stutter. All rights reserved.
//

#import "AudioExporter.h"

@implementation AudioExporter

+ (AVAssetExportSession *)getAudioFromVideo:(AVAsset *)asset handler:(void (^)(AVAssetExportSession*))handler {
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
    
    return exportSession;
}

+ (NSString *)exportAssetAsWaveFormat:(NSString*)filePath progressHandler:(void (^)(CMTime))progressHandler handler:(void (^)(NSString*))handler
{
    NSError *error = nil ;
    
    NSDictionary *audioSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [ NSNumber numberWithFloat:16000.0], AVSampleRateKey,
                                  [ NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                  [ NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                  [ NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                  [ NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                  [ NSNumber numberWithBool:0], AVLinearPCMIsBigEndianKey,
                                  [ NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                  [ NSData data], AVChannelLayoutKey, nil ];
    
    NSString *audioFilePath = filePath;
    AVURLAsset * URLAsset = [[AVURLAsset alloc]  initWithURL:[NSURL fileURLWithPath:audioFilePath] options:nil];
    
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:URLAsset error:&error];
    if (error) return nil;
    
    NSArray *tracks = [URLAsset tracksWithMediaType:AVMediaTypeAudio];
    if (![tracks count]) return nil;
    
    AVAssetReaderAudioMixOutput *audioMixOutput = [AVAssetReaderAudioMixOutput
                                                   assetReaderAudioMixOutputWithAudioTracks:tracks
                                                   audioSettings :audioSetting];
    
    if (![assetReader canAddOutput:audioMixOutput]) return nil;
    
    [assetReader addOutput :audioMixOutput];
    
    if (![assetReader startReading]) return nil;
    
    NSString *title = @"WavConverted";
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex: 0];
    NSString *outPath = [[docDir stringByAppendingPathComponent :title]
                         stringByAppendingPathExtension:@"wav"];
    
    NSURL *outURL = [NSURL fileURLWithPath:outPath];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:outPath error:&error];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outURL
                                                          fileType:AVFileTypeWAVE
                                                             error:&error];
    if (error) return nil;
    
    AVAssetWriterInput *assetWriterInput = [ AVAssetWriterInput assetWriterInputWithMediaType :AVMediaTypeAudio
                                                                                outputSettings:audioSetting];
    assetWriterInput.expectsMediaDataInRealTime = NO;
    
    if (![assetWriter canAddInput:assetWriterInput]) return nil;
    
    [assetWriter addInput :assetWriterInput];
    
    if (![assetWriter startWriting]) return nil;
    
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t queue = dispatch_queue_create( "assetWriterQueue", NULL );
    
    [assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        
        NSLog(@"start");
        
        while (1)
        {
            if ([assetWriterInput isReadyForMoreMediaData]) {
                
                CMSampleBufferRef sampleBuffer = [audioMixOutput copyNextSampleBuffer];

                CMTime presTime = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );

                progressHandler(presTime);

                if (sampleBuffer) {
                    [assetWriterInput appendSampleBuffer :sampleBuffer];
                    CFRelease(sampleBuffer);
                } else {
                    [assetWriterInput markAsFinished];
                    break;
                }
            }
        }
        
        handler(outPath);
        
        NSLog(@"finish");
    }];
    
    return @"";
}

@end
