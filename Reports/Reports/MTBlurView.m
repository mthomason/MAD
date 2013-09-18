//
//  MTBlurView.m
//  MAD
//
//  Created by Michael Thomason on 9/17/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBlurView.h"
#import <QuartzCore/QuartzCore.h>

@interface MTBlurView ()

@property (nonatomic, retain) UIToolbar *toolbar;

@end

@implementation MTBlurView

- (void)dealloc {
    [_toolbar release];
    [_blurTintColor release];
    [super dealloc];
}

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
    
    if (![self toolbar]) {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:[self bounds]];
        [[self layer] insertSublayer:[toolbar layer] atIndex:0];
        [self setToolbar:toolbar];
    }
}

- (void) setBlurTintColor:(UIColor *)blurTintColor {
    [[self toolbar] setBarTintColor:blurTintColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [[self toolbar] setFrame:[self bounds]];
}

@end
