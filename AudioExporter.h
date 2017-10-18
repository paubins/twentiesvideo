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

+ (NSString *)getAudioFromVideo:(AVAsset *)asset handler:(void (^)(AVAssetExportSession*))handler;

@end
