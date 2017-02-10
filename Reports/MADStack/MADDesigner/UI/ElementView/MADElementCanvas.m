//
//  MADElementCanvas.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/10/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADElementCanvas.h"
#import <UIKit/UIGraphics.h>

#import <MADCocoaExtensions/MADColor.h>

@implementation MADElementCanvas

static const CGFloat kDashedBorderWidth     = (0.5f);
static const CGFloat kDashedPhase           = (0.0f);
static const CGFloat kDashedLinesLength[]   = {4.0f, 2.0f};
static size_t const kDashedCount            = (2.0f);

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];

    id displayObject = [self.canvasDelegate displayObject];
    if ([displayObject isKindOfClass: [MTBarcode class]]) {
        [displayObject loadSampleData];
        MADColor *color = [[MADColor alloc] initWithColor:[UIColor lightGrayColor]];
        ((MTBarcode *)displayObject).forgroundColor = color;
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
