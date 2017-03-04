//
//  DesignerSectionLabel.m
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionLabel.h"
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/MADReportSection.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIView+Animations.h>

#import <UIKit/UITapGestureRecognizer.h>
#import <QuartzCore/CALayer.h>

const CGFloat MADesignerSectionLabelFontSize = 10.0000f;

@interface MADDesignerSectionLabel ()
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign, readwrite) BOOL selected;
@property (nonatomic, strong) RptqDocumentSection *section;

@end

@implementation MADDesignerSectionLabel

- (instancetype)initWithSection:(MADReportSection *)section {

    if (self = [self initWithFrame:CGRectZero]) {

        [self setSelected:NO];
        
        self.scale = 1.0000f;

        UIColor *tintColor = [MADColorEverydayApps newColorBlue];
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = NSTextAlignmentRight;
        self.lineBreakMode = NSLineBreakByClipping;
        self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.textColor = tintColor;
        
        self.text = [section localizedDisplayName];
        self.autoresizingMask = MADViewAutoresizingFlexable();
        self.translatesAutoresizingMaskIntoConstraints = YES;
        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layer.cornerRadius = 0.0000f;
        self.clipsToBounds = YES;
        
        [self setContentHuggingPriority: UILayoutPriorityDefaultLow
                                forAxis: UILayoutConstraintAxisHorizontal];
        
        [self setContentCompressionResistancePriority: UILayoutPriorityDefaultHigh
                                              forAxis: UILayoutConstraintAxisHorizontal];
        self.userInteractionEnabled = YES;
        
    }
    return self;
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    super.contentScaleFactor = contentScaleFactor;
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
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
    self.textColor = [tintColor colorWithAlphaComponent:0.500f];
    self.selected = YES;
}

- (void)normalView {
    
    UIColor *tintColor = [MADColorEverydayApps newColorBlue];
    self.textColor = tintColor;
    self.selected = NO;
}

- (void)tintColorDidChange {

}

@end
