//
//  MTTitleView.m
//  Reports
//
//  Created by Michael Thomason on 2/22/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTitleView.h"

static CGFloat Padding = 2.0;

static inline CGRect LabelRect(CGRect bounds);
static inline CGRect LabelRect(CGRect bounds) {
    return CGRectMake(CGPointZero.x, CGPointZero.y + Padding,
                      bounds.size.width, bounds.size.height - Padding);
}

@implementation MTTitleView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    
    UILabel *label = [[UILabel alloc] initWithFrame:LabelRect(self.bounds)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"";
    [self addSubview:label];
    _label = label;
    
    UIColor *color = [UIColor clearColor];
    self.backgroundColor = color;
}

@end
