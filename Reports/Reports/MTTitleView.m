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
    self.backgroundColor = [UIColor clearColor];
    CGRect bounds = [self bounds];
    CGRect labelBounds = CGRectMake(CGPointZero.x, CGPointZero.y, bounds.size.width, bounds.size.height - 4.0000f);
    UILabel *label = [[UILabel alloc] initWithFrame:labelBounds];
        /*
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [label setFont:[UIFont boldSystemFontOfSize:20.0000f]];
        label.backgroundColor = [UIColor clearColor];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [[label layer] setShadowOpacity:1.0000f];
        [[label layer] setShadowRadius:0.0000f];
        
        [[label layer] setShadowColor:[[UIColor blackColor] CGColor]];
        BOOL retna = [UIDevice isRetnaDisplay];
        CGSize shadowOffset = CGSizeMake(0.0, !retna ? -1 : -1.5);
        [[label layer] setShadowOffset:shadowOffset];*/
    label.font = [UIFont systemFontOfSize:20.0000f];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"";
    [self addSubview:label];
    [self setLabel:label];
}

@end
