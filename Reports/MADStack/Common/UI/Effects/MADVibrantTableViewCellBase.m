//
//  MADVibrantTableViewCellBase.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADVibrantTableViewCellBase.h"
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>

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

- (void)initialize {
    
    self.initalSetupComplete = NO;
    self.updatingConstraints = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    id <MADVibrantTableViewCellDelegate> vibrantTableViewCellDelegate = _vibrantTableViewCellDelegate;
    if (vibrantTableViewCellDelegate == nil) return;

    if (_initalSetupComplete) return;
    _initalSetupComplete = YES;
    
    UIBlurEffect *effect = [vibrantTableViewCellDelegate blurEffectForCell:self];
    UIVibrancyEffect *veffect = [UIVibrancyEffect effectForBlurEffect:effect];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:veffect];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 320.0, 320.0)];
    
    label.textColor = [UIColor greenColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [effectView.contentView addSubview:label];
    self.accessoryView.tintColor = [UIColor blackColor];
    
    [effectView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                  forAxis: UILayoutConstraintAxisHorizontal];
    [effectView setContentHuggingPriority: UILayoutPriorityDefaultLow
                                  forAxis: UILayoutConstraintAxisVertical];
    
    [label setContentCompressionResistancePriority: 500
                                           forAxis: UILayoutConstraintAxisHorizontal];
    
    [label setContentHuggingPriority: UILayoutPriorityDefaultLow
                             forAxis: UILayoutConstraintAxisHorizontal];
    
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.userInteractionEnabled = NO;
    effectView.userInteractionEnabled = NO;
    effectView.contentView.userInteractionEnabled = NO;
    
    [self.contentView addSubview:effectView];
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.userInteractionEnabled = YES;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    effectView.translatesAutoresizingMaskIntoConstraints = NO;
    effectView.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.effectView = effectView;
    self.label = label;
    
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    self.contentView.autoresizingMask = MADViewAutoresizingFlexable();
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    
    self.backgroundColor = [UIColor clearColor];
    
    _marginStyle = MADTableViewCellMarginStyleMiddle;
    

    if (self.accessoryView != nil) {
        self.accessoryView.tintColor = [UIColor blackColor];
        // [self.effectView.contentView addSubview: self.accessoryView];
    }
    // [self.contentView addSubview:visualEffectsView];

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
	return UIBlurEffectStyleRegular; //UIBlurEffectStyleExtraLight;
}

- (void)updateConstraints {
    [super updateConstraints];
}

- (void)invalidateConstraints { }

@end
