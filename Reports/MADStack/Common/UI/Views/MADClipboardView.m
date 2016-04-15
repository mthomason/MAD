//
//  MADClipboardView.m
//  Reports
//
//  Created by Michael Thomason on 3/5/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADClipboardView.h"
#import <UIKit/UIGraphics.h>

@implementation MADClipboardView

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);
void drawLinearGloss(CGContextRef context, CGRect rect, BOOL reverse);
void drawCurvedGloss(CGContextRef context, CGRect rect, CGFloat radius);
CGMutablePathRef createRoundedRectForRect(CGRect rect, CGFloat radius);
CGMutablePathRef createRoundedRectForRectCCW(CGRect rect, CGFloat radius);

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) { }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGFloat _brightness = 0.8000f, _hue = 0.5500f, _saturation = 0.8000f;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat actualBrightness = _brightness;
    CGColorRef blackColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0].CGColor;
	CGColorRef outerTop = [UIColor colorWithHue:_hue saturation:_saturation brightness:1.0000f * actualBrightness alpha:1.0].CGColor;
    CGColorRef outerBottom = [UIColor colorWithHue:_hue saturation:_saturation brightness:0.80000f * actualBrightness alpha:1.0].CGColor;
    CGRect outerRect = CGRectInset(self.bounds, 7.5f, 7.5f);
    CGMutablePathRef outerPath = createRoundedRectForRect(outerRect, 6.0);
	CGContextSaveGState(context);
	CGContextAddPath(context, outerPath);
	CGContextClip(context);
	drawLinearGradient(context, outerRect, outerTop, outerBottom);
	CGContextRestoreGState(context);
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, blackColor);
    CGContextAddPath(context, outerPath);
    CGFloat zStrokeColour1[4]    = {0.0, 0.0, 1.0, 1.0};
    CGContextSetStrokeColor(context,zStrokeColour1);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    CFRelease(outerPath);

}

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor) {

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
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

void drawLinearGloss(CGContextRef context, CGRect rect, BOOL reverse) {

	CGColorRef highlightStart = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3500f].CGColor;
	CGColorRef highlightEnd = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1000f].CGColor;
    
    if (reverse) {
		CGRect half = CGRectMake(rect.origin.x, rect.origin.y+rect.size.height/2, rect.size.width, rect.size.height/2);
		drawLinearGradient(context, half, highlightEnd, highlightStart);
	} else {
		CGRect half = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height/2);    
		drawLinearGradient(context, half, highlightStart, highlightEnd);
	}

}

void drawCurvedGloss(CGContextRef context, CGRect rect, CGFloat radius) {
    
	CGColorRef glossStart = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6000f].CGColor;
	CGColorRef glossEnd = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1000f].CGColor;
    
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
	drawLinearGradient(context, half, glossStart, glossEnd);
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

@end
