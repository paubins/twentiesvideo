//
//  AudioExporter.h
//  Stutter
//
//  Created by Patrick Aubin on 6/22/17.
//  Copyright © 2017 com.paubins.Stutter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioExporter : NSObject

+ (AVAssetExportSession *)getAudioFromVideo:(AVAsset *)asset handler:(void (^)(AVAssetExportSession*))handler;
+ (NSString *)exportAssetAsWaveFormat:(NSString*)filePath progressHandler:(void (^)(CMTime))progressHandler handler:(void (^)(NSString*))handler;

@end
