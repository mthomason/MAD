//
//  MTTitleView.m
//  Reports
//
//  Created by Michael Thomason on 2/22/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTitleView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIDevice+Hack.h"

@implementation MTTitleView


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, self.bounds.size.width, self.bounds.size.height - 4.0000f)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"";
    [self addSubview:label];
    self.label = label;
    self.backgroundColor = [UIColor clearColor];
}

@end
