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

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self setTranslatesAutoresizingMaskIntoConstraints:YES];

        UIColor *color = [UIColor whiteColor];
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0000f, 3.0000f, 215.0000f, 24.0000f)];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor blackColor]];
        [label setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [label setFont:font];
        [label setTextColor:color];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [button setFrame:CGRectMake(274.0000f, 0.0000f, 29.0000f, 29.0000f)];
        [button setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
        [button setTintColor:[UIColor whiteColor]];
        [self setButtonAdd:button];
        [self setLabelTitle:label];

        [self addSubview:[self buttonAdd]];
        [self addSubview:[self labelTitle]];

    }
    return self;
}

@end