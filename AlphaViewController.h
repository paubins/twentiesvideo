//
//  ViewController.h
//  PosterLoop
//
//  Created by Moses DeJong on 10/19/14.
//  Copyright (c) 2014 helpurock. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AlphaViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@property (nonatomic, assign) int aniStep;

@property (nonatomic, copy) NSString *aniPrefix;

@property (nonatomic, copy) NSString *aniSuffix;

- (void) loadVideoContent:(NSString *)rgbPath handler:(void (^)(NSString*))handler;

@end
