//
//  MADVibrantTableViewCell.m
//  MAD
//
//  Created by Michael Thomason on 10/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCell.h"

@interface MADVibrantTableViewCell ()

@property (nonatomic, strong) NSArray *layoutConstraints;
@property (atomic, assign) BOOL updatingConstraints;

@end

@implementation MADVibrantTableViewCell

- (void)setMarginStyle:(MADVibrantTableViewCellMarginStyle)marginStyle {
    if (_marginStyle != marginStyle) {
        _marginStyle = marginStyle;
        [self invalidateConstraints];
    }
}

- (void)awakeFromNib {
    [self initalize];
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
    CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, 320.0000f, 320.0000f);
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:[MADVibrantTableViewCell blurEffectStyle]];
    UIVibrancyEffect *veffect = [UIVibrancyEffect effectForBlurEffect:effect];
    UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:veffect];
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    
    label.textColor = [UIColor greenColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [visualEffectsView.contentView addSubview:label];
    [self.contentView addSubview:visualEffectsView];
    
    [visualEffectsView setContentHuggingPriority:UILayoutPriorityDefaultLow
                             forAxis:UILayoutConstraintAxisHorizontal];
    [visualEffectsView setContentHuggingPriority:UILayoutPriorityDefaultLow
                                         forAxis:UILayoutConstraintAxisVertical];
    [label setContentCompressionResistancePriority:500 forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    self.effectView = visualEffectsView;
    self.label = label;
    self.label.translatesAutoresizingMaskIntoConstraints = NO;
    self.effectView.translatesAutoresizingMaskIntoConstraints = NO;
    self.effectView.contentView.translatesAutoresizingMaskIntoConstraints = NO;

    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    self.backgroundColor = [UIColor clearColor];
    _marginStyle = MADTableViewCellMarginStyleMiddle;
    [self invalidateConstraints];
    
}


- (void)invalidateConstraints {
    if (self.updatingConstraints == NO) {
        self.updatingConstraints = YES;
        
        if (self.layoutConstraints.count > 0) {
            [self.contentView removeConstraints:self.layoutConstraints];
        }
        
        NSLayoutConstraint *cellHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                         toItem:self.effectView.contentView
                                                                      attribute:NSLayoutAttributeHeight
                                                                     multiplier:1.0000f
                                                                       constant:0.0000f];
        NSLayoutConstraint *effectsHeight = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                            toItem:self.label
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1.0000f constant:0.0000f];
        
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

    [self invalidateConstraints];
    
    [super updateConstraints];

}

- (void)layoutIfNeeded {
    [super layoutIfNeeded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

+ (UIBlurEffectStyle)blurEffectStyle {
    return UIBlurEffectStyleExtraLight;
}

@end
