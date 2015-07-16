//
//  MADVibrantTableViewCellBase.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCellBase.h"

@interface MADVibrantTableViewCellBase ()

@property (atomic, assign) BOOL initalSetupComplete;

@end

@implementation MADVibrantTableViewCellBase

- (void)awakeFromNib {
    self.accessoryType = UITableViewCellAccessoryNone;
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)setVibrantTableViewCellDelegate:(id<MADVibrantTableViewCellDelegate>)vibrantTableViewCellDelegate {
    if (_vibrantTableViewCellDelegate != vibrantTableViewCellDelegate) {
        _vibrantTableViewCellDelegate = vibrantTableViewCellDelegate;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        [self updateConstraintsIfNeeded];
    }
}

- (void)initalize {
    
    self.initalSetupComplete = NO;
    self.updatingConstraints = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.initalSetupComplete == NO && self.vibrantTableViewCellDelegate != nil) {
        self.initalSetupComplete = YES;
        CGRect rect = CGRectMake(CGPointZero.x, CGPointZero.y, 320.0000f, 320.0000f);
        
        UIBlurEffect *effect = [self.vibrantTableViewCellDelegate blurEffectForCell:self];
        UIVibrancyEffect *veffect = [UIVibrancyEffect effectForBlurEffect:effect];
        UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:veffect];
        UILabel *label = [[UILabel alloc] initWithFrame:rect];
        
        label.textColor = [UIColor greenColor];
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        [visualEffectsView.contentView addSubview:label];
        self.accessoryView.tintColor = [UIColor blackColor];
        
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
        label.userInteractionEnabled = NO;
        visualEffectsView.userInteractionEnabled = NO;
        visualEffectsView.contentView.userInteractionEnabled = NO;

        [self.contentView addSubview:visualEffectsView];
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.userInteractionEnabled = YES;
        self.effectView = visualEffectsView;
        self.label = label;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        self.effectView.translatesAutoresizingMaskIntoConstraints = NO;
        self.effectView.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        self.selectionStyle = UITableViewCellSelectionStyleGray;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
        
        self.backgroundColor = [UIColor clearColor];
        
        _marginStyle = MADTableViewCellMarginStyleMiddle;

    }
    
    if (self.accessoryView != nil) {
        self.accessoryView.tintColor = [UIColor blackColor];
//        [self.effectView.contentView addSubview: self.accessoryView];
    }
//    [self.contentView addSubview:visualEffectsView];

}

- (void)setMarginStyle:(MADVibrantTableViewCellMarginStyle)marginStyle {
    if (_marginStyle != marginStyle) {
        _marginStyle = marginStyle;
        if (self.initalSetupComplete) {
            [self invalidateConstraints];
        }
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
