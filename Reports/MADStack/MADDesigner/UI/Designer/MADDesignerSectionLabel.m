//
//  DesignerSectionLabel.m
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionLabel.h"

#import <QuartzCore/CALayer.h>

#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/MADReportSection.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import <UIKit/UITapGestureRecognizer.h>

#import "UIView+Extras.h"

const CGFloat MADesignerSectionLabelFontSize = 10.0;

@interface MADDesignerSectionLabel ()
    <UIGestureRecognizerDelegate>

    @property (nonatomic, assign, readwrite) BOOL selected;

@end

@implementation MADDesignerSectionLabel

- (instancetype)initWithText:(NSString *)text {
    if (self = [self initWithFrame:CGRectZero]) {

        self.selected = NO;
        self.scale = 1.0;

        UIColor *tintColor = [MADColorEverydayApps newColorBlue];
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = NSTextAlignmentRight;
        self.lineBreakMode = NSLineBreakByClipping;
        self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.textColor = tintColor;
        
        self.text = text.copy;
        self.autoresizingMask = MADViewAutoresizingFlexable();
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.cornerRadius = 0.0;
        self.clipsToBounds = YES;
        
        [self setContentHuggingPriority: UILayoutPriorityDefaultLow
                                forAxis: UILayoutConstraintAxisHorizontal];
        
        [self setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh
                                              forAxis: UILayoutConstraintAxisHorizontal];
        self.userInteractionEnabled = YES;
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIColor *color = [MADColorEverydayApps newColorBlue];
    if (self.selected) {
        self.textColor = [color colorWithAlphaComponent:0.5000f];
    } else {
        self.textColor = color;
    }
}

- (void)dimView {
    UIColor *tintColor = [MADColorEverydayApps newColorBlue];
    self.textColor = [tintColor colorWithAlphaComponent:0.5000f];
    self.selected = YES;
}

- (void)normalView {
    UIColor *tintColor = [MADColorEverydayApps newColorBlue];
    self.textColor = tintColor;
    self.selected = NO;
}

- (void)tintColorDidChange {

}

- (void)applyBorder {
    UIColor *tintColor = [MADColorEverydayApps newColorAnalogous4];
    self.layer.borderColor = tintColor.CGColor;
    self.layer.borderWidth = [UIView borderWidthThin];
}

- (void)removeBorder {
    UIColor *color = [UIColor blackColor];
    self.layer.borderColor = color.CGColor;
    self.layer.borderWidth = 0;
}

@end
