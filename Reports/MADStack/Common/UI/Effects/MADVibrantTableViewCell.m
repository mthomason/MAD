//
//  MADVibrantTableViewCell.m
//  MAD
//
//  Created by Michael Thomason on 10/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCell.h"
#import <UIKit/UIVisualEffectView.h>

#import <UIKit/UINibLoading.h>

@interface MADVibrantTableViewCell ()


@end

@implementation MADVibrantTableViewCell

- (void)awakeFromNib {
    [self initialize];
    [super awakeFromNib];
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)initialize {
    self.updatingConstraints = NO;
    [super initialize];
}


- (void)invalidateConstraints {
    UIVisualEffectView *effectView = self.effectView;
    if (self.updatingConstraints == NO && effectView != nil && self.label != nil) {
        self.updatingConstraints = YES;
        
        if (self.layoutConstraints.count > 0) {
            [self.contentView removeConstraints:self.layoutConstraints];
        }
        
        NSLayoutConstraint *cellHeight, *effectsHeight, *layoutConstraint0, *layoutConstraint2,
                           *layoutConstraint4, *layoutConstraint6,
                           *labelLeadingMargin, *labelTrailingMargin,
                           *layoutConstraintLabelTop, *layoutConstraintLabelBottom;
        
        cellHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                  attribute: NSLayoutAttributeHeight
                                                  relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                     toItem: effectView.contentView
                                                  attribute: NSLayoutAttributeHeight
                                                 multiplier: 1.0000f
                                                   constant: 0.0000f];
        
        effectsHeight = [NSLayoutConstraint constraintWithItem: effectView.contentView
                                                     attribute: NSLayoutAttributeHeight
                                                     relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                        toItem: self.label
                                                     attribute: NSLayoutAttributeHeight
                                                    multiplier: 1.0000f
                                                      constant: 0.0000f];
        
        layoutConstraint0 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                         attribute: NSLayoutAttributeLeading
                                                         relatedBy: NSLayoutRelationEqual
                                                            toItem: effectView.contentView
                                                         attribute: NSLayoutAttributeLeading
                                                        multiplier: 1.0000f
                                                          constant: 0.0000f];
        layoutConstraint0.priority = UILayoutPriorityRequired;
        
        layoutConstraint2 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                         attribute: NSLayoutAttributeTrailing
                                                         relatedBy: NSLayoutRelationEqual
                                                            toItem: effectView.contentView
                                                         attribute: NSLayoutAttributeTrailing
                                                        multiplier: 1.0000f
                                                          constant: 0.0000f];
        layoutConstraint2.priority = UILayoutPriorityRequired;
        
        layoutConstraint4 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                         attribute: NSLayoutAttributeTop
                                                         relatedBy: NSLayoutRelationEqual
                                                            toItem: effectView.contentView
                                                         attribute: NSLayoutAttributeTop
                                                        multiplier: 1.0000f
                                                          constant: 0.0000f];
        layoutConstraint4.priority = UILayoutPriorityRequired;
        
        layoutConstraint6 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                         attribute: NSLayoutAttributeBottom
                                                         relatedBy: NSLayoutRelationEqual
                                                            toItem: effectView.contentView
                                                         attribute: NSLayoutAttributeBottom
                                                        multiplier: 1.0000f
                                                          constant: 0.0000f];
        layoutConstraint6.priority = UILayoutPriorityRequired;
        
        labelLeadingMargin = [NSLayoutConstraint constraintWithItem: effectView.contentView
                                                                          attribute: NSLayoutAttributeLeading
                                                                          relatedBy: NSLayoutRelationEqual
                                                                             toItem: self.label
                                                                          attribute: NSLayoutAttributeLeading
                                                                         multiplier: 1.0000f
                                                                           constant: -4.0000f];
        labelLeadingMargin.priority = UILayoutPriorityDefaultHigh;
        
        labelTrailingMargin = [NSLayoutConstraint constraintWithItem: effectView.contentView
                                                                     attribute: NSLayoutAttributeTrailing
                                                                     relatedBy: NSLayoutRelationEqual
                                                                        toItem: self.label
                                                                     attribute: NSLayoutAttributeTrailing
                                                                    multiplier: 1.0000f
                                                                      constant: 4.0000f];
        labelTrailingMargin.priority = UILayoutPriorityDefaultHigh;
        
        layoutConstraintLabelTop = [NSLayoutConstraint constraintWithItem: effectView.contentView
                                                                attribute: self.marginStyle == MADTableViewCellMarginStyleTop ||
                                                                           self.marginStyle == MADTableViewCellMarginStyleFat ||
                                                                           self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeTop : NSLayoutAttributeTop
                                                                relatedBy: NSLayoutRelationEqual
                                                                   toItem: self.label
                                                                attribute: NSLayoutAttributeTop
                                                               multiplier: 1.0000f
                                                                 constant: self.marginStyle == MADTableViewCellMarginStyleTop ||
                                                                           self.marginStyle == MADTableViewCellMarginStyleFat ? -4.0000f : 0.0000f];
        layoutConstraintLabelTop.priority = UILayoutPriorityRequired;
        
        layoutConstraintLabelBottom = [NSLayoutConstraint constraintWithItem: effectView.contentView
                                                                   attribute: self.marginStyle == MADTableViewCellMarginStyleBottom ||
                                                                              self.marginStyle == MADTableViewCellMarginStyleFat ||
                                                                              self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeBottomMargin : NSLayoutAttributeBottom
                                                                   relatedBy: NSLayoutRelationEqual
                                                                      toItem: self.label
                                                                   attribute: NSLayoutAttributeBottom
                                                                  multiplier: 1.0000f
                                                                    constant: self.marginStyle == MADTableViewCellMarginStyleBottom ||
                                                                              self.marginStyle == MADTableViewCellMarginStyleFat ||
                                                                              self.marginStyle == MADTableViewCellMarginStyleMiddle ? -4.0000f : 0.000f];
        layoutConstraintLabelBottom.priority = UILayoutPriorityDefaultHigh;
        
        NSArray *constraints = @[cellHeight, effectsHeight, layoutConstraint0, layoutConstraint2,
                                 layoutConstraint4, layoutConstraintLabelTop,
                                 layoutConstraint6, layoutConstraintLabelBottom,
                                 labelLeadingMargin, labelTrailingMargin];
        
        self.layoutConstraints = constraints;
        [self.contentView addConstraints:constraints];
        
        self.updatingConstraints = NO;
    }
    
}

- (void)updateConstraints {
    [super updateConstraints];
    [self invalidateConstraints];
}

@end
