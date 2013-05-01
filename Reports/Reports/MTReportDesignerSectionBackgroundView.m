//
//  MTReportDesignerSectionBackgroundView.m
//  Reports
//
//  Created by Michael Thomason on 5/1/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerSectionBackgroundView.h"

@interface MTReportDesignerSectionBackgroundView ()

@property (nonatomic, assign, readonly) NSUInteger numberOfRowsInBackground;

@end

@implementation MTReportDesignerSectionBackgroundView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setNumberOfRowsInBackground:(NSUInteger)numberOfRowsInBackground {
    _numberOfRowsInBackground = numberOfRowsInBackground;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    if ([self numberOfRowsInBackground] >= 2) {
        [[UIColor scrollViewTexturedBackgroundColor] setStroke];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGFloat sectionHeight = rect.size.height / [self numberOfRowsInBackground];
        CGFloat lineOriginY = CGPointZero.y;
        for (NSUInteger row = 0; row < [self numberOfRowsInBackground]; row++) {
            
            
            
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
