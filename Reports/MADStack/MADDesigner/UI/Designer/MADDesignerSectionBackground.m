//
//  MADDesignerSectionBackground.m
//  Reports
//
//  Created by Michael Thomason on 5/1/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionBackground.h"
#import <UIKit/UIGraphics.h>

@implementation MADDesignerSectionBackground {
    int32_t _numberOfRowsInBackground;
};

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)setNumberOfRowsInBackground:(int32_t)numberOfRowsInBackground {
    _numberOfRowsInBackground = numberOfRowsInBackground;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect: rect];

    if (_numberOfRowsInBackground >= 2) {
        [[UIColor groupTableViewBackgroundColor] setStroke];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGFloat sectionHeight = rect.size.height / _numberOfRowsInBackground;
        CGFloat lineOriginY = CGPointZero.y;
        for (int32_t row = 0; row < _numberOfRowsInBackground; row++) {
            
            
            
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
