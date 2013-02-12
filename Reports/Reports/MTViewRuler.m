//
//  UIViewRuler.m
//  TheReportViewer
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewRuler.h"

@implementation MTViewRuler

- (id)init {
    self = [super init];
    if (self) {
        [self setBackgroundColor:[UIColor yellowColor]];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor yellowColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGMutablePathRef pathInchMarks = CGPathCreateMutable();

    CGFloat eigthInchInPoints = 72.0000f / 8.0000f;
    for (NSInteger i = CGPointZero.x; i < rect.size.width / eigthInchInPoints; i++) {
        CGFloat xPoint = i * eigthInchInPoints;
        CGFloat length = 0.0000f;
        if ((i % 8) == 0) {
            CGRect locationRect = CGRectMake(xPoint - 2.5000f, rect.size.height - 18.0000f, 5.0000f, 5.0000f);
            [[NSString stringWithFormat:@"%d", i / 8] drawInRect: locationRect
                                                    withFont: [UIFont systemFontOfSize: 8.0000f]
                                               lineBreakMode: NSLineBreakByClipping
                                                   alignment: NSTextAlignmentLeft];
            
            length = 8.0000f;
        } else if (i % 2) {
            length = 6.0000f;
        } else if (i % 4) {
            length = 4.0000f;
        } else {
            length = 2.0000f;
        }
        CGPathMoveToPoint(pathInchMarks, NULL, xPoint, rect.size.height);
        CGPathAddLineToPoint(pathInchMarks, NULL, xPoint, rect.size.height - length);
    }
    
    CGFloat offsetInPoints = (72.0000f / 2.5400f) / 10.0000f;   //One cm
    CGMutablePathRef pathCmMarks = CGPathCreateMutable();
    for (NSInteger i = CGPointZero.x; i < rect.size.width / offsetInPoints; i++) {
        CGFloat length = 0.0000f;
        if ((i % 10) == 0) {
            length = 8.0000f;
        } else if (i % 5) {
            length = 2.0000f;
        } else {
            length = 5.0000f;
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