//
//  MADLabelPageSlider.m
//  MAD Designer
//
//  Created by Michael on 8/21/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelPageSlider.h"
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

@implementation MADLabelPageSlider

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIColor *clearColor = [UIColor clearColor];
        self.backgroundColor = clearColor;
        self.textAlignment = NSTextAlignmentRight;
        self.font = [UIFont boldSystemFontOfSize:9.0000f];
        UIColor *darkTextColor = [UIColor darkTextColor];
        UIColor *textColor = [darkTextColor colorWithAlphaComponent:0.80000000f];
        self.textColor = textColor;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.layer.shadowOpacity = 6.0;
        self.layer.shadowRadius = 0.0;
        self.layer.shadowOffset = CGSizeMake(0.75000f, 0.750000f);
        UIColor *blueColor = [MADColorEverydayApps newColorBlue];
        CGColorRef color = CGColorRetain(blueColor.CGColor);
        self.layer.shadowColor = color;
        CGColorRelease(color);

    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.tintColor = enabled ? [MADColorEverydayApps newColorRed] : [UIColor lightGrayColor];
}

- (void)setPageNumber:(NSUInteger)pageNumber {
    _pageNumber = pageNumber;
    NSString *display;
    display = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)pageNumber];
    self.text = display;
}

- (void)translateToPoint:(CGPoint)drawingPoint {
    self.transform = CGAffineTransformTranslate(self.transform,
                                                 self.frame.origin.x > 0 ? -1 * self.frame.origin.x : self.frame.origin.x,
                                                 self.frame.origin.y > 0 ? -1 * self.frame.origin.y : self.frame.origin.y);
    self.transform = CGAffineTransformTranslate(self.transform, drawingPoint.x, drawingPoint.y);

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
