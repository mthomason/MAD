//
//  UIViewClipboard.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/5/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewClipboard.h"

@implementation UIViewClipboard

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor);
//CGRect rectFor1PxStroke(CGRect rect);
//void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color);
//void drawHighlightAndGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor, BOOL reverse);
void drawLinearGloss(CGContextRef context, CGRect rect, BOOL reverse);
void drawCurvedGloss(CGContextRef context, CGRect rect, CGFloat radius);
//static inline double radians (double degrees) { return degrees * M_PI/180; }
CGMutablePathRef createRoundedRectForRect(CGRect rect, CGFloat radius);
CGMutablePathRef createRoundedRectForRectCCW(CGRect rect, CGFloat radius);

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //[self setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        //[[self layer] setCornerRadius:5.0000f];
        //[self setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    CGFloat _brightness = 0.8000f, _hue = 0.5500f, _saturation = 0.8000f;

    CGContextRef context = UIGraphicsGetCurrentContext();
        
    CGFloat actualBrightness = _brightness;
    if (NO) {
        actualBrightness -= 0.10;
    }   
    
    CGColorRef blackColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0].CGColor;
    
	CGColorRef outerTop = [UIColor colorWithHue:_hue saturation:_saturation brightness:1.0*actualBrightness alpha:1.0].CGColor;
    CGColorRef outerBottom = [UIColor colorWithHue:_hue saturation:_saturation brightness:0.80*actualBrightness alpha:1.0].CGColor;
    
    CGRect outerRect = CGRectInset(self.bounds, 7.5f, 7.5f);            
    CGMutablePathRef outerPath = createRoundedRectForRect(outerRect, 6.0);
    
    // Draw gradient for outer path
	CGContextSaveGState(context);

	CGContextAddPath(context, outerPath);
	CGContextClip(context);
	drawLinearGradient(context, outerRect, outerTop, outerBottom);
    
	CGContextRestoreGState(context);
    
    // Stroke outer path
    CGContextSaveGState(context);

    //CGContextSetShadowWithColor(context, CGSizeMake(5.0000f, 5.0000f), 0.0000f, [[UIColor colorWithRed:0.0000f green:0.0000f blue:1.0000f alpha:0.9000f] CGColor]);
    
    CGContextSetLineWidth(context, 0.5);
    CGContextSetStrokeColorWithColor(context, blackColor);
    CGContextAddPath(context, outerPath);

    //[[UIColor clearColor] set];
    CGFloat zStrokeColour1[4]    = {0.0, 0.0, 1.0, 1.0};
    CGContextSetStrokeColor(context,zStrokeColour1);
    //CGContextDrawPath(context, kCGPathStroke);
    //CGContextSetStrokeColorWithColor(context, [[UIColor clearColor] CGColor]);
    CGContextStrokePath(context);

    //[[UIColor clearColor] setFill];
    //[outerPath fill];
    //CGContextStrokePath(context);

    CGContextRestoreGState(context);
    
    CFRelease(outerPath);
    
}

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef  endColor) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
    
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
    
	CGColorRef highlightStart = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.35].CGColor;
	CGColorRef highlightEnd = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1].CGColor;
    
    if (reverse) {
        
		CGRect half = CGRectMake(rect.origin.x, rect.origin.y+rect.size.height/2, rect.size.width, rect.size.height/2);    
		drawLinearGradient(context, half, highlightEnd, highlightStart);
	}
	else {
		CGRect half = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height/2);    
		drawLinearGradient(context, half, highlightStart, highlightEnd);
	}
    
}

void drawCurvedGloss(CGContextRef context, CGRect rect, CGFloat radius) {
    
	CGColorRef glossStart = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6].CGColor;
	CGColorRef glossEnd = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.1].CGColor;
    
	//CGFloat radius = 60.0f; //radius of gloss
    
	CGMutablePathRef glossPath = CGPathCreateMutable();
    
	CGContextSaveGState(context);
    CGPathMoveToPoint(glossPath, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect)-radius+rect.size.height/2);
	CGPathAddArc(glossPath, NULL, CGRectGetMidX(rect), CGRectGetMinY(rect)-radius+rect.size.height/2, radius, 0.75f*M_PI, 0.25f*M_PI, YES);	
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