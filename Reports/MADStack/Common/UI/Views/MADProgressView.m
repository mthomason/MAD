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

+ (instancetype)newProgressView:(MADProgressViewType)type {
    id progressView;
    
    switch (type) {

        case MADProgressViewTypeFileExplorer:
            progressView = [[self.class alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
            ((__kindof UIProgressView *) progressView).trackTintColor = [MADColorEverydayApps newColorRed];
            ((__kindof UIProgressView *) progressView).tintColor = [MADColorEverydayApps newColorBlue];
            ((__kindof UIProgressView *) progressView).progress = 0.0000f;
            
            break;

        case MADProgressViewTypeConnection:
            progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            ((__kindof UIProgressView *) progressView).autoresizingMask = UIViewAutoresizingFlexibleWidth;
            ((__kindof UIProgressView *) progressView).progressTintColor = [MADColorEverydayApps newColorAnalogous4];
            ((__kindof UIProgressView *) progressView).trackTintColor = [UIColor grayColor];
            break;

        case MADProgressViewTypeDefault:
        default:
            progressView = [[self.class alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
            ((__kindof UIProgressView *) progressView).trackTintColor = [MADColorEverydayApps newColorRed];
            ((__kindof UIProgressView *) progressView).tintColor = [MADColorEverydayApps newColorBlue];
            ((__kindof UIProgressView *) progressView).progress = 0.0000f;
            break;
    }
    return progressView;
}

@end
