//
//  MTBlurView.m
//  MAD
//
//  Created by Michael Thomason on 9/17/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTBlurView.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UIToolbar.H>

@interface MTBlurView ()

    @property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation MTBlurView


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // If we don't clip to bounds the toolbar draws a thin shadow on top
    [self setClipsToBounds:YES];
    
    if (!self.toolbar) {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        [self.layer insertSublayer:toolbar.layer atIndex:0];
        self.toolbar = toolbar;
    }
}

- (void) setBlurTintColor:(UIColor *)blurTintColor {
    (self.toolbar).barTintColor = blurTintColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    (self.toolbar).frame = self.bounds;
}

@end
