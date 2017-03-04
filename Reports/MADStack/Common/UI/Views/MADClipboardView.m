//
//  MADClipboardView.m
//  Reports
//
//  Created by Michael Thomason on 3/5/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADClipboardView.h"
#import <UIKit/UIGraphics.h>

static void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);
static void drawLinearGloss(CGContextRef context, CGRect rect, BOOL reverse);
static void drawCurvedGloss(CGContextRef context, CGRect rect, CGFloat radius);
CGMutablePathRef createRoundedRectForRect(CGRect rect, CGFloat radius);
CGMutablePathRef createRoundedRectForRectCCW(CGRect rect, CGFloat radius);

static void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor) {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0000f, 1.0000f };
    NSArray *colors = @[(__bridge id)startColor, (__bridge id)endColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef) colors, locations);
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
}

static void drawLinearGloss(CGContextRef context, CGRect rect, BOOL reverse) {
    
    
    UIColor *highlightStart = [[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.3500f];
    UIColor *highlightEnd = [[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.1000f];
    
    if (reverse) {
        CGRect half = CGRectMake(rect.origin.x, rect.origin.y+rect.size.height/2, rect.size.width, rect.size.height/2);
        drawLinearGradient(context, half, highlightEnd.CGColor, highlightStart.CGColor);
    } else {
        CGRect half = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height/2);
        drawLinearGradient(context, half, highlightStart.CGColor, highlightEnd.CGColor);
    }
    
}

static void drawCurvedGloss(CGContextRef context, CGRect rect, CGFloat radius) {
    
    UIColor *glossStart = [[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.6000f];
    UIColor *glossEnd = [[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.1000f];
    
    CGMutablePathRef glossPath = CGPathCreateMutable();
    CGContextSaveGState(context);
    CGPathMoveToPoint(glossPath, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect)-radius+rect.size.height/2);
    CGPathAddArc(glossPath, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect)-radius+rect.size.height/2, radius, (CGFloat)(0.75*M_PI), (CGFloat)(0.25*M_PI), YES);
    CGPathCloseSubpath(glossPath);
    CGContextAddPath(context, glossPath);
    CGContextClip(context);
    CGMutablePathRef buttonPath=createRoundedRectForRect(rect, 6.0f);
    CGContextAddPath(context, buttonPath);
    CGContextClip(context);
    CGRect half = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height/2);
    drawLinearGradient(context, half, glossStart.CGColor, glossEnd.CGColor);
    CGContextRestoreGState(context);
    CGPathRelease(buttonPath);
    CGPathRelease(glossPath);
    
}

CGMutablePathRef createRoundedRectForRect(CGRect rect, CGFloat radius) {
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMinY(rect), CGRectGetMaxX(rect), CGRectGetMaxY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMaxY(rect), CGRectGetMinX(rect), CGRectGetMaxY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect), CGRectGetMinX(rect), CGRectGetMinY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetMaxX(rect), CGRectGetMinY(rect), radius);
    CGPathCloseSubpath(path);
    return path;
    
}

CGMutablePathRef createRoundedRectForRectCCW(CGRect rect, CGFloat radius) {
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPathAddArcToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetMinX(rect), CGRectGetMaxY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMinX(rect), CGRectGetMaxY(rect), CGRectGetMaxX(rect), CGRectGetMaxY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMaxY(rect), CGRectGetMaxX(rect), CGRectGetMinY(rect), radius);
    CGPathAddArcToPoint(path, NULL, CGRectGetMaxX(rect), CGRectGetMinY(rect), CGRectGetMinX(rect), CGRectGetMinY(rect), radius);
    CGPathCloseSubpath(path);
    return path;
    
}

@implementation MADClipboardView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) { }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

static inline CGRect OuterRect(CGRect bounds);
static inline CGRect OuterRect(CGRect bounds) {
    return CGRectInset(bounds, 7.5f, 7.5f);
}

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];

    const CGFloat _brightness = 0.8000f, _hue = 0.5500f, _saturation = 0.8000f;
    const CGFloat zStrokeColour1[4]    = {0.0, 0.0, 1.0, 1.0};
    
    UIColor *black =            [[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    
    UIColor *outerTopColor =    [[UIColor alloc] initWithHue:_hue saturation:_saturation
                                           brightness:1.0000f * _brightness alpha:1.0];
    
    UIColor *outerBottomColor = [[UIColor alloc] initWithHue:_hue saturation:_saturation
                                           brightness:0.80000f * _brightness alpha:1.0];

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGMutablePathRef outerPath = createRoundedRectForRect(OuterRect(self.bounds), 6.0);
	CGContextSaveGState(context);
	CGContextAddPath(context, outerPath);
	CGContextClip(context);
	drawLinearGradient(context, OuterRect(self.bounds), outerTopColor.CGColor, outerBottomColor.CGColor);
	CGContextRestoreGState(context);
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, black.CGColor);
    CGContextAddPath(context, outerPath);
    CGContextSetStrokeColor(context, zStrokeColour1);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    CFRelease(outerPath);

}

@end
