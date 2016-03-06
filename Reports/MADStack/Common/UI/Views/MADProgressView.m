//
//  MADProgressView.m
//  MAD Designer
//
//  Created by Michael Thomason on 5/24/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADProgressView.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADProgressView

- (instancetype)initWithProgressViewStyle:(UIProgressViewStyle)style {
    if (self = [super initWithProgressViewStyle:style]) {
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progressView.trackTintColor = [MADColorEverydayApps newColorRed];
        progressView.tintColor = [MADColorEverydayApps newColorBlue];
        progressView.progress = 0.0000f;
    }
    return self;
}

@end
