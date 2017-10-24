//
//  ViewController.h
//  PosterLoop
//
//  Created by Moses DeJong on 10/19/14.
//  Copyright (c) 2014 helpurock. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDAVAssetExportSession.h"

@interface AlphaViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@property (nonatomic, assign) int aniStep;

@property (nonatomic, copy) NSString *aniPrefix;

@property (nonatomic, copy) NSString *aniSuffix;

@property (nonatomic, strong) SDAVAssetExportSession *encoder;

- (void) loadVideoContent:(NSString *)rgbPath handler:(void (^)(NSString*))handler;

@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetReaderVideoCompositionOutput *videoOutput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;

@property (nonatomic, copy) NSDictionary *videoSettings;

@property (nonatomic, strong) NSArray *times;
@property (nonatomic, strong) NSMutableArray *images;

@end
