//
//  MADVibrantTableViewCell.m
//  MAD
//
//  Created by Michael Thomason on 10/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCell.h"

@interface MADVibrantTableViewCell ()


@end

@implementation MADVibrantTableViewCell

- (void)awakeFromNib {
    [self initalize];
    [self invalidateConstraints];
    [self layoutIfNeeded];
    
    [super awakeFromNib];
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)initalize {
    self.updatingConstraints = NO;
    [super initalize];
}


- (void)invalidateConstraints {
    if (self.updatingConstraints == NO) {
        self.updatingConstraints = YES;
        
        if (self.layoutConstraints.count > 0) {
            [self.contentView removeConstraints:self.layoutConstraints];
        }
        
        NSLayoutConstraint *cellHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                      attribute: NSLayoutAttributeHeight
                                                                      relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                                         toItem: self.effectView.contentView
                                                                      attribute: NSLayoutAttributeHeight
                                                                     multiplier: 1.0000f
                                                                       constant: 0.0000f];
        
        NSLayoutConstraint *effectsHeight = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                         attribute: NSLayoutAttributeHeight
                                                                         relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                                            toItem: self.label
                                                                         attribute: NSLayoutAttributeHeight
                                                                        multiplier: 1.0000f
                                                                          constant: 0.0000f];
        
        NSLayoutConstraint *layoutConstraint0 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                             attribute: NSLayoutAttributeLeading
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self.effectView.contentView
                                                                             attribute: NSLayoutAttributeLeading
                                                                            multiplier: 1.0000f
                                                                              constant: 0.0000f];
        layoutConstraint0.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraint2 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                             attribute: NSLayoutAttributeTrailing
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self.effectView.contentView
                                                                             attribute: NSLayoutAttributeTrailing
                                                                            multiplier: 1.0000f
                                                                              constant: 0.0000f];
        layoutConstraint2.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraint4 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                             attribute: NSLayoutAttributeTop
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self.effectView.contentView
                                                                             attribute: NSLayoutAttributeTop
                                                                            multiplier: 1.0000f
                                                                              constant: 0.0000f];
        layoutConstraint4.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraint6 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                             attribute: NSLayoutAttributeBottom
                                                                             relatedBy: NSLayoutRelationEqual
                                                                                toItem: self.effectView.contentView
                                                                             attribute: NSLayoutAttributeBottom
                                                                            multiplier: 1.0000f
                                                                              constant: 0.0000f];
        layoutConstraint6.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraintLabelLeadingMargin = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                                              attribute: NSLayoutAttributeLeading
                                                                                              relatedBy: NSLayoutRelationEqual
                                                                                                 toItem: self.label
                                                                                              attribute: NSLayoutAttributeLeading
                                                                                             multiplier: 1.0000f
                                                                                               constant: -4.0000f];
        layoutConstraintLabelLeadingMargin.priority = UILayoutPriorityDefaultHigh;
        
        NSLayoutConstraint *layoutConstraintLabelTrailing = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                                         attribute: NSLayoutAttributeTrailing
                                                                                         relatedBy: NSLayoutRelationEqual
                                                                                            toItem: self.label
                                                                                         attribute: NSLayoutAttributeTrailing
                                                                                        multiplier: 1.0000f
                                                                                          constant: 4.0000f];
        layoutConstraintLabelTrailing.priority = UILayoutPriorityDefaultHigh;
        
        NSLayoutConstraint *layoutConstraintLabelTop = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                                    attribute: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeTop : NSLayoutAttributeTop
                                                                                    relatedBy: NSLayoutRelationEqual
                                                                                       toItem: self.label
                                                                                    attribute: NSLayoutAttributeTop
                                                                                   multiplier: 1.0000f
                                                                                     constant: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat ? -4.0000f : 0.0000f];
        layoutConstraintLabelTop.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraintLabelBottom = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                                       attribute: self.marginStyle == MADTableViewCellMarginStyleBottom || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeBottomMargin : NSLayoutAttributeBottom
                                                                                       relatedBy: NSLayoutRelationEqual
                                                                                          toItem: self.label
                                                                                       attribute: NSLayoutAttributeBottom
                                                                                      multiplier: 1.0000f
                                                                                        constant: self.marginStyle == MADTableViewCellMarginStyleBottom || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? -4.0000f : 0.000f];
        layoutConstraintLabelBottom.priority = UILayoutPriorityDefaultHigh;
        
        NSArray *constraints = @[cellHeight, effectsHeight, layoutConstraint0, layoutConstraint2,
                                 layoutConstraint4, layoutConstraintLabelTop,
                                 layoutConstraint6, layoutConstraintLabelBottom, layoutConstraintLabelLeadingMargin, layoutConstraintLabelTrailing];
        
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
