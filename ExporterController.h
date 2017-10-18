//
//  ExporterController.h
//  FakeFaceTime
//
//  Created by Patrick Aubin on 7/7/17.
//  Copyright © 2017 com.paubins.FakeFaceTime. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface ExporterController : NSObject

+ (void)export:(NSURL *)exportUrl fromOutput:(NSArray *)outputFiles;
+ (void) overlapVideos;
+ (CALayer *)createVideoLayer:(CGRect)bounds size:(CGSize)newSize;

@end
