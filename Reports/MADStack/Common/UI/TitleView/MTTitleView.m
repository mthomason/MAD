//
//  MTTitleView.m
//  Reports
//
//  Created by Michael Thomason on 2/22/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MTTitleView.h"
#import <UIKit/UILabel.h>
#import <UIKit/UIGraphics.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

static CGFloat Padding = 2.0;

static inline CGRect LabelRect(CGRect bounds);
static inline CGRect LabelRect(CGRect bounds) {
    return CGRectMake(CGPointZero.x, CGPointZero.y + Padding,
                      bounds.size.width, bounds.size.height - Padding);
}

@implementation MTTitleView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    
    UILabel *label = [[UILabel alloc] initWithFrame:LabelRect(self.bounds)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"";
    [self addSubview:label];
    _label = label;
    
    UIColor *color = [UIColor clearColor];
    self.backgroundColor = color;
}

@end

@implementation MADTitleViewQueryTable

- (void)setStyle:(MADTitleViewQueryTableStyle)style {
    if (_style == style) return;
    
    switch (style) {
        case MADTitleViewQueryTableRoot:
            self.label.textColor = [UIColor whiteColor];
            self.label.font = [UIFont monospacedDigitSystemFontOfSize:12.0f weight:UIFontWeightSemibold];
            break;
        case MADTitleViewQueryTableChild:
            self.label.textColor = [MADColorEverydayApps newColorBlue];
            self.label.font = [UIFont monospacedDigitSystemFontOfSize:11.0f weight:UIFontWeightMedium];
            break;
            
        default:
            break;
    }
    _style = style;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [[MADColorEverydayApps newColorBlue] setStroke];

    CGMutablePathRef border = CGPathCreateMutable();
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(currentContext,
                          1.0000f / self.traitCollection.displayScale);
    CGPathMoveToPoint(border, NULL, rect.origin.x,
                      rect.origin.y + rect.size.height);
    CGPathAddLineToPoint(border, NULL, rect.origin.x + rect.size.width,
                         rect.origin.y + rect.size.height);
    CGContextAddPath(currentContext, border);
    CGContextDrawPath(currentContext, kCGPathStroke);
    CGPathRelease(border);

}


@end
