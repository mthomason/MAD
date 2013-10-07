//
//  UIViewRuler.m
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTRulerView.h"
#import "UIDevice+Hack.h"

@implementation MTRulerView

- (id)init {
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGMutablePathRef pathInchMarks = CGPathCreateMutable();
    
    CGFloat thinLineWidth = 1.0000f / [[UIScreen mainScreen] scale];
    CGFloat lineWidth = 1.0000f;

    CGFloat eigthInchInPoints = 72.0000f / 8.0000f;
    CGFloat cmInPoints = (72.0000f / 1.0000f) / 2.5400f;
    for (NSInteger i = CGPointZero.x; i < rect.size.width / eigthInchInPoints; i++) {
        CGFloat xPoint = i * eigthInchInPoints;
        CGFloat length = 0.0000f;
        if ((i % 8) == 0) {
            CGRect locationRect = CGRectMake(xPoint - 5.000f, rect.size.height - 8.0000f, 10.0000f, 5.0000f);
            [[NSString stringWithFormat:@"%d", i / 8] drawInRect: locationRect
                                                        withFont: [UIFont systemFontOfSize: 6.0000f]
                                                   lineBreakMode: NSLineBreakByClipping
                                                       alignment: NSTextAlignmentCenter];
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
        CGPathMoveToPoint(pathInchMarks, NULL, xPoint, rect.size.height);
        CGPathAddLineToPoint(pathInchMarks, NULL, xPoint, rect.size.height - length);
    }
    
    CGFloat offsetInPoints = (72.0000f / 2.5400f) / 10.0000f;   //One cm
    CGMutablePathRef pathCmMarks = CGPathCreateMutable();
    for (NSInteger i = CGPointZero.x; i < rect.size.width / offsetInPoints; i++) {
        CGFloat length = 0.0000f;
        CGFloat xPointC = i * (cmInPoints / 10.0000f);
        if ((i % 10) == 0) {
            CGRect locationRect = CGRectMake(xPointC - 5.000f, 1.0000f, 10.0000f, 5.0000f);
            [[NSString stringWithFormat:@"%d", i / 10] drawInRect: locationRect
                                                        withFont: [UIFont systemFontOfSize: 5.0000f]
                                                   lineBreakMode: NSLineBreakByClipping
                                                       alignment: NSTextAlignmentCenter];

            length = 2.0000f;
            CGContextSetLineWidth(currentContext, lineWidth * 2.0000f);
        } else if (i % 5) {
            length = 2.0000f;
            CGContextSetLineWidth(currentContext, thinLineWidth);
        } else {
            length = 3.0000f;
            CGContextSetLineWidth(currentContext, thinLineWidth);
        }
        CGFloat xPoint = i * offsetInPoints;
        CGPathMoveToPoint(pathCmMarks, NULL, xPoint, CGPointZero.y);
        CGPathAddLineToPoint(pathCmMarks, NULL, xPoint, CGPointZero.y + length);
    }
    
    CGContextAddPath(currentContext, pathCmMarks);
    CGContextAddPath(currentContext, pathInchMarks);
    
    [[UIColor darkGrayColor] setStroke];
    CGContextDrawPath(currentContext, kCGPathStroke);

    CGPathRelease(pathInchMarks);
    CGPathRelease(pathCmMarks);
    
}

@end
