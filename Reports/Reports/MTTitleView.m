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


- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {
    [self setBackgroundColor:[UIColor clearColor]];
    CGRect bounds = [self bounds];
    CGRect labelBounds = CGRectMake(CGPointZero.x, CGPointZero.y, bounds.size.width, bounds.size.height - 4.0000f);
    UILabel *label = [[UILabel alloc] initWithFrame:labelBounds];
    if ([UIDevice isLagacyOS]) {
        [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [label setFont:[UIFont boldSystemFontOfSize:20.0000f]];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [[label layer] setShadowOpacity:1.0000f];
        [[label layer] setShadowRadius:0.0000f];
        
        [[label layer] setShadowColor:[[UIColor blackColor] CGColor]];
        BOOL retna = [UIDevice isRetnaDisplay];
        CGSize shadowOffset = CGSizeMake(0.0, !retna ? -1 : -1.5);
        [[label layer] setShadowOffset:shadowOffset];
    } else {
        [label setFont:[UIFont systemFontOfSize:20.0000f]];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
    }
    [label setText:@""];
    [self addSubview:label];
    [self setLabel:label];
}

@end
