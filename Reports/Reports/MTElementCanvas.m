//
//  MTElementCanvas.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTElementCanvas.h"

@implementation MTElementCanvas

static CGFloat const kDashedBorderWidth     = (0.5f);
static CGFloat const kDashedPhase           = (0.0f);
static CGFloat const kDashedLinesLength[]   = {4.0f, 2.0f};
static size_t const kDashedCount            = (2.0f);

- (void)drawRect:(CGRect)rect {
    
    id displayObject = [self.canvasDelegate displayObject];
    if ([displayObject isKindOfClass: [MTBarcode class]]) {
        [displayObject initSampleData];
        [displayObject setForgroundColor:[UIColor lightGrayColor]];
    }
    
    if ([displayObject isKindOfClass: [NSAttributedString class]]) {
        [displayObject drawWithRect: rect
                            options: self.drawingOptions
                            context: nil];
    } else {
        [displayObject drawInRect:rect];
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, kDashedBorderWidth);
    UIColor *tintColor = [UIColor blackColor];
    CGContextSetStrokeColorWithColor(context, tintColor.CGColor);
    CGContextSetLineDash(context, kDashedPhase, kDashedLinesLength, kDashedCount) ;
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
}

- (NSStringDrawingOptions)drawingOptions {
    return NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
}

@end
