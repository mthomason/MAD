//
//  MADVibrantTableViewCellImage.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCellImage.h"

#import <UIKit/UINibLoading.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIButton.h>

@interface MADVibrantTableViewCellImage ()

@property (atomic, assign) BOOL initalSetupImageComplete;

@end

@implementation MADVibrantTableViewCellImage

- (void)awakeFromNib {
    [self initialize];
    [self layoutIfNeeded];
    [super awakeFromNib];
}

- (void)initialize {
    self.updatingConstraints = NO;
    self.initalSetupImageComplete = NO;
    [super initialize];
}


- (void)invalidateConstraints {
    
    if (self.updatingConstraints == NO && self.initalSetupImageComplete &&
        self.effectView != nil && self.label != nil && self.imageViewMain != nil) {
        self.updatingConstraints = YES;
        
        if (self.layoutConstraints.count > 0) {
            [self.contentView removeConstraints:self.layoutConstraints];
        }
        
        
        NSLayoutConstraint *ch;
        ch = [NSLayoutConstraint constraintWithItem: self.contentView
                                          attribute: NSLayoutAttributeHeight
                                          relatedBy: NSLayoutRelationGreaterThanOrEqual
                                             toItem: self.effectView.contentView
                                          attribute: NSLayoutAttributeHeight
                                         multiplier: 1.0000f
                                           constant: 0.0000f];
        
        NSLayoutConstraint *eh;
        eh = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                          attribute: NSLayoutAttributeHeight
                                          relatedBy: NSLayoutRelationGreaterThanOrEqual
                                             toItem: self.label
                                          attribute: NSLayoutAttributeHeight
                                         multiplier: 1.0000f
                                           constant: 0.0000f];

        
        NSLayoutConstraint *ih;
        ih = [NSLayoutConstraint constraintWithItem: self.contentView
                                          attribute: NSLayoutAttributeHeight
                                          relatedBy: NSLayoutRelationGreaterThanOrEqual
                                             toItem: self.imageViewMain
                                          attribute: NSLayoutAttributeHeight
                                         multiplier: 1.0000f
                                           constant: 2 * 4.0000f];
        
        NSLayoutConstraint *isw;
        isw = [NSLayoutConstraint constraintWithItem: self.imageViewMain
                                           attribute: NSLayoutAttributeWidth
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: nil
                                           attribute: NSLayoutAttributeNotAnAttribute
                                          multiplier: 1.0000f
                                            constant: self.imageViewMain.image.size.width];
        
        NSLayoutConstraint *ish;
        ish = [NSLayoutConstraint constraintWithItem: self.imageViewMain
                                           attribute: NSLayoutAttributeHeight
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: nil
                                           attribute: NSLayoutAttributeNotAnAttribute
                                          multiplier: 1.0000f
                                            constant: self.imageViewMain.image.size.height];
        
        NSLayoutConstraint *lcli;
        lcli = [NSLayoutConstraint constraintWithItem: self.contentView
                                            attribute: NSLayoutAttributeLeading
                                            relatedBy: NSLayoutRelationEqual
                                               toItem: self.imageViewMain
                                            attribute: NSLayoutAttributeLeading
                                           multiplier: 1.0000f
                                             constant: -4.0000f];
        lcli.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lcmil;
        lcmil = [NSLayoutConstraint constraintWithItem: self.imageViewMain
                                             attribute: NSLayoutAttributeTrailing
                                             relatedBy: NSLayoutRelationEqual
                                                toItem: self.effectView.contentView
                                             attribute: NSLayoutAttributeLeading
                                            multiplier: 1.0000f
                                              constant: 0.0000f];
        lcmil.priority = UILayoutPriorityRequired;
        
        
        NSLayoutConstraint *lc2;
        lc2 = [NSLayoutConstraint constraintWithItem: self.contentView
                                           attribute: NSLayoutAttributeTrailing
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: self.effectView.contentView
                                           attribute: NSLayoutAttributeTrailing
                                          multiplier: 1.0000f
                                            constant: 0.0000f];
        lc2.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lc4;
        lc4 = [NSLayoutConstraint constraintWithItem: self.contentView
                                           attribute: NSLayoutAttributeTop
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: self.effectView.contentView
                                           attribute: NSLayoutAttributeTop
                                          multiplier: 1.0000f
                                            constant: 0.0000f];
        lc4.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lc6;
        lc6 = [NSLayoutConstraint constraintWithItem: self.contentView
                                           attribute: NSLayoutAttributeBottom
                                           relatedBy: NSLayoutRelationEqual
                                              toItem: self.effectView.contentView
                                           attribute: NSLayoutAttributeBottom
                                          multiplier: 1.0000f
                                            constant: 0.0000f];
        lc6.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lcicy;
        lcicy = [NSLayoutConstraint constraintWithItem: self.imageViewMain
                                             attribute: NSLayoutAttributeCenterY
                                             relatedBy: NSLayoutRelationEqual
                                                toItem: self.contentView
                                             attribute: NSLayoutAttributeCenterY
                                            multiplier: 1.0000f
                                              constant: 0.0000f];
        
        
        
        NSLayoutConstraint *lcllm;
        lcllm = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                             attribute: NSLayoutAttributeLeadingMargin
                                             relatedBy: NSLayoutRelationEqual
                                                toItem: self.label
                                             attribute: NSLayoutAttributeLeading
                                            multiplier: 1.0000f
                                              constant: 0.0000f];
        lcllm.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lcla;
        lcla = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                            attribute: NSLayoutAttributeTrailing
                                            relatedBy: NSLayoutRelationEqual
                                               toItem: self.label
                                            attribute: NSLayoutAttributeTrailing
                                           multiplier: 1.0000f
                                             constant: 4.0000f];
        lcla.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lclt;
        lclt = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                            attribute: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat || self.marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeTop : NSLayoutAttributeTop
                                            relatedBy: NSLayoutRelationEqual
                                               toItem: self.label
                                            attribute: NSLayoutAttributeTop
                                           multiplier: 1.0000f
                                             constant: self.marginStyle == MADTableViewCellMarginStyleTop || self.marginStyle == MADTableViewCellMarginStyleFat ? -4.0000f : 0.0000f];
        lclt.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *lclb;
        lclb = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                            attribute: lclbAttribute1(self.marginStyle)
                                            relatedBy: NSLayoutRelationEqual
                                               toItem: self.label
                                            attribute: NSLayoutAttributeBottom
                                           multiplier: 1.0000f
                                             constant: lclbConstant(self.marginStyle)];
        lclb.priority = UILayoutPriorityDefaultHigh;
        
        NSArray *constraints = @[lcli, lcmil, lcicy, ch, eh, lc2,
                                 lc4, lclt, ih, isw, ish,
                                 lc6, lclb, lcllm, lcla];
        
        self.layoutConstraints = constraints;
        [self.contentView addConstraints:constraints];
    
        self.updatingConstraints = NO;
    }
    
}
static inline CGFloat lclbConstant(MADVibrantTableViewCellMarginStyle marginStyle);
static inline CGFloat lclbConstant(MADVibrantTableViewCellMarginStyle marginStyle) {
    return marginStyle == MADTableViewCellMarginStyleBottom || marginStyle == MADTableViewCellMarginStyleFat || marginStyle == MADTableViewCellMarginStyleMiddle ? -4.0000f : 0.000f;
}

static inline NSLayoutAttribute lclbAttribute1(MADVibrantTableViewCellMarginStyle marginStyle);
static inline NSLayoutAttribute lclbAttribute1(MADVibrantTableViewCellMarginStyle marginStyle) {
    return marginStyle == MADTableViewCellMarginStyleBottom || marginStyle == MADTableViewCellMarginStyleFat || marginStyle == MADTableViewCellMarginStyleMiddle ? NSLayoutAttributeBottomMargin : NSLayoutAttributeBottom;
}

- (void)updateConstraints {
    [super updateConstraints];

    [self invalidateConstraints];

    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_initalSetupImageComplete) return;
    
    id <MADVibrantTableViewCellDelegate> vibrantTableViewCellDelegate;
    vibrantTableViewCellDelegate = self.vibrantTableViewCellDelegate;
    if (vibrantTableViewCellDelegate != nil) {
        _initalSetupImageComplete = YES;
        
        NSArray<__kindof NSLayoutConstraint *> *constraints;
        constraints = self.imageView.constraints;
        if (constraints) {
            [self.imageView removeConstraints:constraints];
        }
        
        constraints = self.detailTextLabel.constraints;
        if (constraints) {
            [self.detailTextLabel removeConstraints:constraints];
        }
        
        constraints = self.textLabel.constraints;
        if (constraints) {
            [self.textLabel removeConstraints:constraints];
        }
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                      16.0000f, 16.0000f)];
        UIImage *image = [UIImage imageNamed:@"MADImageChevronRightTall"];
        [button setBackgroundImage: image
                          forState: UIControlStateNormal];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGPointZero.x,
                                                                               CGPointZero.y,
                                                                               16.0000f,
                                                                               16.0000f)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:imageView];
        _imageViewMain = imageView;
        
        UIImageView *imageViewIndicator = [[UIImageView alloc] initWithImage:image];
        imageViewIndicator.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 16.0000f, 16.0000f);
        UIBlurEffect *blurEffect = [vibrantTableViewCellDelegate blurEffectForCell:self];
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        UIVisualEffectView *visualEffectView;
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        [visualEffectView.contentView addSubview:button];
        visualEffectView.frame = CGRectMake(CGPointZero.x, CGPointZero.y, 16.0000f, 16.0000f);
        self.accessoryView = visualEffectView;

        
    }
}

+ (UIBlurEffectStyle)blurEffectStyle {
    return UIBlurEffectStyleExtraLight;
}

@end
