//
//  MTReportDesignerSectionDecorationView.m
//  Reports
//
//  Created by Michael Thomason on 4/30/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionDecorationView.h"

@implementation MTReportDesignerSectionDecorationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [[UIColor blackColor] setStroke];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathStroke);
}

@end
