//
//  MTViewBordered.m
//  Reports
//
//  Created by Michael Thomason on 1/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTBorderedView.h"

@interface MTBorderedView ()

@property (nonatomic, retain) UIColor *borderColor;

@end

@implementation MTBorderedView

- (void)dealloc {
    [_borderColor release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBorderColor:[UIColor blackColor]];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andColor:(UIColor *)color {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBorderColor:color];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(currentContext, path);
    [[UIColor clearColor] setFill];
    [[self borderColor] setStroke];
    float dashPhase = 0.0;
    float dashLengths[] = { 7, 3, 7, 3, 7, 3 };
    CGContextSetLineDash(currentContext,
                         dashPhase, dashLengths,
                         sizeof( dashLengths ) / sizeof( float ) );
    CGContextSetLineWidth(currentContext, 1.0000f);
    CGContextDrawPath(currentContext, kCGPathFillStroke);
    [[UIColor blackColor] set];
    CGPathRelease(path);
    
}

@end
