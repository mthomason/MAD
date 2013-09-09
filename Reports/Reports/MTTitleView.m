//
//  MTTitleView.m
//  Reports
//
//  Created by Michael Thomason on 2/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTTitleView.h"
#import "UIDevice+Hack.h"

@implementation MTTitleView

- (void)dealloc {
    [_label release];
    [super dealloc];
}

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
    CGRect labelBounds = CGRectMake(CGPointZero.x, CGPointZero.y, [self bounds].size.width, [self bounds].size.height - 4.0000f);
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
        [[label layer] setShadowOffset:CGSizeMake(0.0, ![UIDevice isRetnaDisplay] ? -1 : -1.5)];
    } else {
        [label setFont:[UIFont boldSystemFontOfSize:20.0000f]];
        [label setTextColor:[UIColor blackColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
    }
    [label setText:@""];
    [self addSubview:label];
    [self setLabel:label];
    [label release];
}

@end
