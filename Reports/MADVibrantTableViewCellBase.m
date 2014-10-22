//
//  MADVibrantTableViewCellBase.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCellBase.h"

@implementation MADVibrantTableViewCellBase

- (void)awakeFromNib {
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
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:[MADVibrantTableViewCellBase blurEffectStyle]];
    UIVibrancyEffect *veffect = [UIVibrancyEffect effectForBlurEffect:effect];
    UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:veffect];
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    
    label.textColor = [UIColor greenColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [visualEffectsView.contentView addSubview:label];
    [self.contentView addSubview:visualEffectsView];
    
    [visualEffectsView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                         forAxis: UILayoutConstraintAxisHorizontal];
    [visualEffectsView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                         forAxis: UILayoutConstraintAxisVertical];

    [label setContentCompressionResistancePriority: 500
                                           forAxis: UILayoutConstraintAxisHorizontal];
    
    [label setContentHuggingPriority: UILayoutPriorityDefaultLow
                             forAxis: UILayoutConstraintAxisHorizontal];
    
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
    
}


- (void)setMarginStyle:(MADVibrantTableViewCellMarginStyle)marginStyle {
    if (_marginStyle != marginStyle) {
        _marginStyle = marginStyle;
        [self invalidateConstraints];
    }
}

+ (UIBlurEffectStyle)blurEffectStyle {
    return UIBlurEffectStyleExtraLight;
}

- (void)updateConstraints {
    [super updateConstraints];
}

- (void)invalidateConstraints { }

@end
