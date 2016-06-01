//
//  UIViewRuler.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTRulerView.h"

#import <QuartzCore/CALayer.h>

#import <UIKit/UIGraphics.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/NSParagraphStyle.h>
#import <UIKit/NSStringDrawing.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import "UIView+Extras.h"

const CGFloat MTReportDesignerRulerHeight           = 20.0000f;

static inline double xPoint(NSInteger i, double offsetInPoints);
static inline double cmInPoints();
static inline double eigthInchInPoints();

static inline double eigthInchInPoints() {
    return 72.0000f / 8.0000f;
}

static inline double cmInPoints() {
    return (72.0000f / 1.0000f) / 2.5400f;
}

static inline double xPoint(NSInteger i, double offsetInPoints) {
    return i * offsetInPoints;
}

@interface MTRulerView ()

@end

@implementation MTRulerView


- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {

    UIColor *blackColor = [UIColor blackColor];
    UIColor *whiteColor = [UIColor whiteColor];
    UIColor *otherColor = [MADColorEverydayApps newColorBorderColor];

    self.layer.borderWidth = [UIView borderWidthThin];
    self.layer.borderColor = blackColor.CGColor;
    self.backgroundColor = whiteColor;
    
    self.layer.borderWidth = [UIView borderWidthThin];
    self.layer.borderColor = otherColor.CGColor;
    self.translatesAutoresizingMaskIntoConstraints = NO;

}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGMutablePathRef pathInchMarks = CGPathCreateMutable();
    
    UIFont *fontStandard = [UIFont systemFontOfSize: 5.0000f];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                    fontStandard, NSFontAttributeName,
                                                    paragraphStyle, NSParagraphStyleAttributeName, nil];
    
    CGFloat length;
    CGFloat thinLineWidth = 1.0000f / self.traitCollection.displayScale;
    static const CGFloat lineWidth = 1.0000f;
    for (NSInteger i = (NSInteger)CGPointZero.x; i < rect.size.width / eigthInchInPoints(); i++) {
        @autoreleasepool {
            if ((i % 8) == 0) {
                CGRect locationRect = CGRectMake((CGFloat)xPoint(i, eigthInchInPoints()) - 5.000f,
                                                 rect.size.height - 8.0000f,
                                                 10.0000f, 5.0000f);
                NSString *s = [[NSString alloc] initWithFormat:@"%ld", (long)i / 8];
                [s drawInRect:locationRect withAttributes:attributes];
                length = 1.0000f;
                CGContextSetLineWidth(currentContext, lineWidth * 2.0000f);
            } else if (i % 2) {
                length = 4.0000f;
                CGContextSetLineWidth(currentContext, thinLineWidth);
            } else if (i % 4) {
                length = 3.0000f;
                CGContextSetLineWidth(currentContext, thinLineWidth);
            } else {
                length = 2.0000f;
                CGContextSetLineWidth(currentContext, thinLineWidth);
            }
            CGPathMoveToPoint(pathInchMarks, NULL, (CGFloat)xPoint(i, eigthInchInPoints()), rect.size.height);
            CGPathAddLineToPoint(pathInchMarks, NULL, (CGFloat)xPoint(i, eigthInchInPoints()), rect.size.height - length);
        }
    }
    
    UIFont *fontMetric = [UIFont systemFontOfSize: 4.0000f];
    NSDictionary *attributesMetric = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                    fontMetric, NSFontAttributeName,
                                                    paragraphStyle, NSParagraphStyleAttributeName, nil];
    CGFloat offsetInPoints = (72.0000f / 2.5400f) / 10.0000f;   //One cm
    CGMutablePathRef pathCmMarks = CGPathCreateMutable();
    for (NSInteger i = (NSInteger)CGPointZero.x; i < rect.size.width / offsetInPoints; i++) {
        @autoreleasepool {
            if ((i % 10) == 0) {
                CGRect locationRect = CGRectMake((CGFloat)xPoint(i, cmInPoints() / 10.0000f) - 5.000f, 1.0000f, 10.0000f, 5.0000f);
                NSString *s = [[NSString alloc] initWithFormat:@"%ld", (long)i / 10];
                [s drawInRect:locationRect withAttributes:attributesMetric];
                length = 2.0000f;
                CGContextSetLineWidth(currentContext, lineWidth * 2.0000f);
            } else if (i % 5) {
                length = 2.0000f;
                CGContextSetLineWidth(currentContext, thinLineWidth);
            } else {
                length = 3.0000f;
                CGContextSetLineWidth(currentContext, thinLineWidth);
            }
            CGPathMoveToPoint(pathCmMarks, NULL,
                              (CGFloat)xPoint(i, offsetInPoints), CGPointZero.y);
            CGPathAddLineToPoint(pathCmMarks, NULL,
                                 (CGFloat)xPoint(i, offsetInPoints), CGPointZero.y + length);
        }
    }
    
    CGContextAddPath(currentContext, pathCmMarks);
    CGContextAddPath(currentContext, pathInchMarks);
    
    [[UIColor blackColor] setStroke];
    
    CGContextDrawPath(currentContext, kCGPathStroke);

    CGPathRelease(pathInchMarks);
    CGPathRelease(pathCmMarks);
    
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, MTReportDesignerRulerHeight);
}

- (BOOL)isAccessibilityElement {
    return NO;
}

@end
