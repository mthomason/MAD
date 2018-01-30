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
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = NSTextAlignmentRight;
        self.font = [UIFont boldSystemFontOfSize:9.0000f];
        self.textColor = [[UIColor darkTextColor] colorWithAlphaComponent:0.90000000f];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.layer.shadowOpacity = 6.0;
        self.layer.shadowRadius = 0.0;
        self.layer.shadowOffset = CGSizeMake(0.75000f, 0.750000f);
        UIColor *blueColor = [MADColorEverydayApps newColorRed];
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

@end
