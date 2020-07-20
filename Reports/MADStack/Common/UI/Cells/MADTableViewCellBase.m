//
//  MADTableViewCellBase.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/23/15.
//  Copyright © 2020 Everyday Apps LLC. All rights reserved.
//

#import "MADTableViewCellBase.h"
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>

@interface MADTableViewCellBase ()

    @property (atomic, assign) BOOL initalSetupComplete;

@end

@implementation MADTableViewCellBase

- (void)awakeFromNib {
    self.accessoryType = UITableViewCellAccessoryNone;
    [self initialize];
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        CGRect rect = MADRectOfSize(MADSizeSquare(320.0));
        
        UIView *visualEffectsView = [[UIView alloc] initWithFrame:rect];
        UILabel *label = [[UILabel alloc] initWithFrame:rect];
        
        label.textColor = [UIColor blackColor];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [self.contentView addSubview:label];
        self.accessoryView.tintColor = [UIColor blackColor];
        
        [visualEffectsView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                             forAxis: UILayoutConstraintAxisHorizontal];
        [visualEffectsView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                             forAxis: UILayoutConstraintAxisVertical];
        
        [label setContentCompressionResistancePriority: 500.0
                                               forAxis: UILayoutConstraintAxisHorizontal];
        
        [label setContentHuggingPriority: UILayoutPriorityDefaultLow
                                 forAxis: UILayoutConstraintAxisHorizontal];
        
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.userInteractionEnabled = NO;
        visualEffectsView.userInteractionEnabled = NO;
        [self.contentView addSubview:visualEffectsView];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.userInteractionEnabled = YES;
        self.label = label;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
        self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
        
        self.backgroundColor = [UIColor clearColor];
        
        _marginStyle = MADTableViewCellMarginStyleMiddle;
        
    }
    return self;
}

- (void)layoutIfNeeded {
    [super layoutIfNeeded];
    
}

- (void)updateConstraintsIfNeeded {
    [super updateConstraintsIfNeeded];
    
}

- (void)initialize {
    self.initalSetupComplete = NO;
    self.updatingConstraints = NO;
}


- (void)updateConstraints {
    if (self.updatingConstraints == NO && self.label != nil) {
        self.updatingConstraints = YES;
        
        if (self.layoutConstraints.count > 0) {
            [self.contentView removeConstraints:self.layoutConstraints];
        }
        
        NSLayoutConstraint *effectsHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                         attribute: NSLayoutAttributeHeight
                                                                         relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                                            toItem: self.label
                                                                         attribute: NSLayoutAttributeHeight
                                                                        multiplier: 1.0
                                                                          constant: 0.0];
        
        
        
        
        NSLayoutConstraint *layoutConstraintLabelLeadingMargin = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                              attribute: NSLayoutAttributeLeading
                                                                                              relatedBy: NSLayoutRelationEqual
                                                                                                 toItem: self.label
                                                                                              attribute: NSLayoutAttributeLeading
                                                                                             multiplier: 1.0
                                                                                               constant: -4.0];
        layoutConstraintLabelLeadingMargin.priority = UILayoutPriorityDefaultHigh;
        
        NSLayoutConstraint *layoutConstraintLabelTrailing = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                         attribute: NSLayoutAttributeTrailing
                                                                                         relatedBy: NSLayoutRelationEqual
                                                                                            toItem: self.label
                                                                                         attribute: NSLayoutAttributeTrailing
                                                                                        multiplier: 1.0
                                                                                          constant: 4.0];
        layoutConstraintLabelTrailing.priority = UILayoutPriorityDefaultHigh;
        
        NSLayoutConstraint *layoutConstraintLabelTop = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                    attribute: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeTop : NSLayoutAttributeTop
                                                                                    relatedBy: NSLayoutRelationEqual
                                                                                       toItem: self.label
                                                                                    attribute: NSLayoutAttributeTop
                                                                                   multiplier: 1.0
                                                                                     constant: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat ? -4.0 : 0.0];
        layoutConstraintLabelTop.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraintLabelBottom = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                       attribute: self.marginStyle == MADTableViewCellMarginStyleBottom || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeBottomMargin : NSLayoutAttributeBottom
                                                                                       relatedBy: NSLayoutRelationEqual
                                                                                          toItem: self.label
                                                                                       attribute: NSLayoutAttributeBottom
                                                                                      multiplier: 1.0
                                                                                        constant: self.marginStyle == MADTableViewCellMarginStyleBottom || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? -4.0 : 0.0];
        layoutConstraintLabelBottom.priority = UILayoutPriorityDefaultHigh;
        
        NSArray *constraints = @[effectsHeight, layoutConstraintLabelTop, layoutConstraintLabelBottom, layoutConstraintLabelLeadingMargin, layoutConstraintLabelTrailing];
        self.layoutConstraints = constraints;
        [self.contentView addConstraints:constraints];
        
        self.updatingConstraints = NO;
    }
    [super updateConstraints];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.accessoryView != nil) {
        self.accessoryView.tintColor = [UIColor blackColor];
    }
}

- (void)setMarginStyle:(MADVibrantTableViewCellMarginStyle)marginStyle {
    if (_marginStyle != marginStyle) {
        _marginStyle = marginStyle;
        if (self.initalSetupComplete) {
            [self setNeedsUpdateConstraints];
        }
    }
}

@end
