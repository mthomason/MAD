//
//  MTReportDesignerSectionBackgroundView.m
//  Reports
//
//  Created by Michael Thomason on 5/1/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionBackgroundView.h"
#import <UIKit/UIGraphics.h>

@interface MTReportDesignerSectionBackgroundView ()

@property (nonatomic, assign, readonly) NSUInteger numberOfRowsInBackground;

@end

@implementation MTReportDesignerSectionBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)setNumberOfRowsInBackground:(NSUInteger)numberOfRowsInBackground {
    _numberOfRowsInBackground = numberOfRowsInBackground;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

    if (self.numberOfRowsInBackground >= 2) {
        [[UIColor groupTableViewBackgroundColor] setStroke];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGFloat sectionHeight = rect.size.height / self.numberOfRowsInBackground;
        CGFloat lineOriginY = CGPointZero.y;
        for (NSUInteger row = 0; row < self.numberOfRowsInBackground; row++) {
            
            
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, rect.origin.x, lineOriginY);
            CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, lineOriginY);
            
            CGContextClosePath(context);
            
            CGContextDrawPath(context, kCGPathStroke);
            
            lineOriginY += sectionHeight;
            
        }
    }
    
}

@end
