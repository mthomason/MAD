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
    CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, 320.0000f, 320.0000f);
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:[MADVibrantTableViewCell blurEffectStyle]];
    UIVibrancyEffect *veffect = [UIVibrancyEffect effectForBlurEffect:effect];
    UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:veffect];
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    
    label.textColor = [UIColor greenColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [visualEffectsView.contentView addSubview:label];
    [self.contentView addSubview:visualEffectsView];
    
    [label setContentCompressionResistancePriority:500
                                           forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow
                             forAxis:UILayoutConstraintAxisHorizontal];
    
    [visualEffectsView setContentCompressionResistancePriority:500 forAxis:UILayoutConstraintAxisHorizontal];
    [visualEffectsView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
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
    [self updateConstraintsIfNeeded];
    
}


- (void)invalidateConstraints {
    
    if (self.layoutConstraints.count > 0) {
        [self removeConstraints:self.layoutConstraints];
    }
    
    NSLayoutConstraint *layoutConstraint0 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                         attribute: NSLayoutAttributeLeading
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.effectView.contentView
                                                                         attribute: NSLayoutAttributeLeading
                                                                        multiplier: 1.0000f
                                                                          constant: 0.0000f];
    layoutConstraint0.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraint2 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                         attribute: NSLayoutAttributeTrailing
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.effectView.contentView
                                                                         attribute: NSLayoutAttributeTrailing
                                                                        multiplier: 1.0000f
                                                                          constant: 0.0000f];
    layoutConstraint2.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraint4 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                         attribute: NSLayoutAttributeTop
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.effectView.contentView
                                                                         attribute: NSLayoutAttributeTop
                                                                        multiplier: 1.0000f
                                                                          constant: 0.0000f];
    layoutConstraint4.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraint6 = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                         attribute: NSLayoutAttributeBottom
                                                                         relatedBy: NSLayoutRelationEqual
                                                                            toItem: self.effectView.contentView
                                                                         attribute: NSLayoutAttributeBottom
                                                                        multiplier: 1.0000f
                                                                          constant: 0.0000f];
    layoutConstraint6.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraintLabelLeadingMargin = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                          attribute: NSLayoutAttributeLeftMargin
                                                                                          relatedBy: NSLayoutRelationEqual
                                                                                             toItem: self.label
                                                                                          attribute: NSLayoutAttributeLeft
                                                                                         multiplier: 1.0000f
                                                                                           constant: 0.0000f];
    layoutConstraintLabelLeadingMargin.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraintLabelTrailing = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                     attribute: NSLayoutAttributeTrailingMargin
                                                                                     relatedBy: NSLayoutRelationEqual
                                                                                        toItem: self.label
                                                                                     attribute: NSLayoutAttributeTrailing
                                                                                    multiplier: 1.0000f
                                                                                      constant: 0.0000f];
    layoutConstraintLabelTrailing.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraintLabelTop = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                attribute: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat ? NSLayoutAttributeTopMargin : NSLayoutAttributeTop
                                                                                relatedBy: NSLayoutRelationEqual
                                                                                   toItem: self.label
                                                                                attribute: NSLayoutAttributeTop
                                                                               multiplier: 1.0000f
                                                                                 constant: 0.0000f];
    layoutConstraintLabelTop.priority = UILayoutPriorityDefaultHigh;
    
    NSLayoutConstraint *layoutConstraintLabelBottom = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                   attribute: self.marginStyle == MADTableViewCellMarginStyleBottom || self.marginStyle == MADTableViewCellMarginStyleFat ? NSLayoutAttributeBottomMargin : NSLayoutAttributeBottom
                                                                                   relatedBy: NSLayoutRelationEqual
                                                                                      toItem: self.label
                                                                                   attribute: NSLayoutAttributeBottom
                                                                                  multiplier: 1.0000f
                                                                                    constant: 0.0000f];
    layoutConstraintLabelBottom.priority = UILayoutPriorityDefaultHigh;
    
    NSArray *constraints = @[layoutConstraint0, layoutConstraint2,
                             layoutConstraint4, layoutConstraintLabelTop,
                             layoutConstraint6, layoutConstraintLabelBottom, layoutConstraintLabelLeadingMargin, layoutConstraintLabelTrailing];
    
    self.layoutConstraints = constraints;
    [self.contentView addConstraints:constraints];

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
