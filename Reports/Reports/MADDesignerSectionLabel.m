//
//  DesignerSectionLabel.m
//  Reports
//
//  Created by Michael Thomason on 7/24/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerSectionLabel.h"
#import "UIDevice+Hack.h"
#import "UIColor+EverydayApps.h"
#import "RptqDocumentSection+Extras.h"
#import <CoreData/CoreData.h>

const CGFloat MADesignerSectionLabelFontSize = 10.0000f;

@interface MADDesignerSectionLabel ()
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign, readwrite) BOOL selected;
@property (nonatomic, strong) RptqDocumentSection *section;

@end

@implementation MADDesignerSectionLabel

- (instancetype)initWithSection:(RptqDocumentSection *)section {
    CGRect frame = CGRectZero;
    self = [super initWithFrame:frame];
    if (self) {
        [self setSelected:NO];
        
        self.scale = 1.0000f;

        UIColor *tintColor = [UIColor tintColorBlue];
        self.backgroundColor = [UIColor clearColor];
        self.textAlignment = NSTextAlignmentRight;
        self.lineBreakMode = NSLineBreakByClipping;
        self.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.textColor = tintColor;
        
        self.text = [section localizedDisplayName];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
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
    [super setContentScaleFactor:contentScaleFactor];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIColor *color = [UIColor tintColorBlue];
    if (self.selected) {
        self.textColor = [color colorWithAlphaComponent:0.5000f];
    } else {
        self.textColor = color;
    }
}

- (void)dimView {
    UIColor *tintColor = [UIColor tintColorBlue];
    self.textColor = [tintColor colorWithAlphaComponent:0.500f];
    self.selected = YES;
}

- (void)normalView {
    
    UIColor *tintColor = [UIColor tintColorBlue];
    self.textColor = tintColor;
    self.selected = NO;
}

//- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
//    return [super textRectForBounds:CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width - 10.0000f, bounds.size.height)
//             limitedToNumberOfLines:numberOfLines];
//}

- (void)tintColorDidChange {

}

@end
