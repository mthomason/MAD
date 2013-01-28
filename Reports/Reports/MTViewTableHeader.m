//
//  MTViewTableHeader.m
//  Reports
//
//  Created by Michael Thomason on 1/27/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTViewTableHeader.h"

@interface MTViewTableHeader ()

@end

@implementation MTViewTableHeader

- (void)dealloc {
    [_labelTitle release];
    [_buttonAdd release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self setBackgroundColor: [UIColor edaTableHeaderBackground]];
        [self setTranslatesAutoresizingMaskIntoConstraints:YES];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0000f, 3.0000f, 215.0000f, 24.0000f)];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor blackColor]];
        [label setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [label setFont:[UIFont boldSystemFontOfSize:20.0000f]];
        [label setHighlightedTextColor:[UIColor whiteColor]];
        [label setShadowColor:[UIColor whiteColor]];
        [label setShadowOffset:CGSizeMake(1.0000f, 1.0000f)];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [button setFrame:CGRectMake(274.0000f, 0.0000f, 29.0000f, 29.0000f)];
        [button setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        
        [self setButtonAdd:button];
        [self setLabelTitle:label];

        [self addSubview:[self buttonAdd]];
        [self addSubview:[self labelTitle]];

        [label release];
    }
    return self;
}

@end