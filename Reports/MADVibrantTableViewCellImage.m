//
//  MADVibrantTableViewCellImage.m
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableViewCellImage.h"

@implementation MADVibrantTableViewCellImage
- (void)awakeFromNib {
    [self initalize];
    [self layoutIfNeeded];
    [super awakeFromNib];
    
    
}

- (void)initalize {
    self.updatingConstraints = NO;
    [self.imageView removeConstraints:self.imageView.constraints];
    [self.detailTextLabel removeConstraints:self.detailTextLabel.constraints];
    [self.textLabel removeConstraints:self.textLabel.constraints];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, 64.0000f, 64.0000f)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:imageView];
    self.imageViewMain = imageView;
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

        
        NSLayoutConstraint *imageHeight = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                       attribute: NSLayoutAttributeHeight
                                                                       relatedBy: NSLayoutRelationGreaterThanOrEqual
                                                                          toItem: self.imageViewMain
                                                                       attribute: NSLayoutAttributeHeight
                                                                      multiplier: 1.0000f
                                                                        constant: 0.0000f];
        
        NSLayoutConstraint *imageSizeWidth = [NSLayoutConstraint constraintWithItem:self.imageViewMain attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant:self.imageViewMain.image.size.width];
        NSLayoutConstraint *imageSizeHeight = [NSLayoutConstraint constraintWithItem:self.imageViewMain attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0000f constant:self.imageViewMain.image.size.height];
        
        NSLayoutConstraint *layoutConstraintLeftItem = [NSLayoutConstraint constraintWithItem: self.contentView
                                                                                    attribute: NSLayoutAttributeLeading
                                                                                    relatedBy: NSLayoutRelationEqual
                                                                                       toItem: self.imageViewMain
                                                                                    attribute: NSLayoutAttributeLeading
                                                                                   multiplier: 1.0000f
                                                                                     constant: 0.0000f];
        layoutConstraintLeftItem.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraintMiddleItemLeft = [NSLayoutConstraint constraintWithItem: self.imageViewMain
                                                                                          attribute: NSLayoutAttributeTrailing
                                                                                          relatedBy: NSLayoutRelationEqual
                                                                                             toItem: self.effectView.contentView
                                                                                          attribute: NSLayoutAttributeLeading
                                                                                         multiplier: 1.0000f
                                                                                           constant: 0.0000f];
        layoutConstraintMiddleItemLeft.priority = UILayoutPriorityRequired;
        
        
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
        
        NSLayoutConstraint *imageCenterY = [NSLayoutConstraint constraintWithItem: self.imageViewMain
                                                                        attribute: NSLayoutAttributeCenterY
                                                                        relatedBy: NSLayoutRelationEqual
                                                                           toItem: self.contentView
                                                                        attribute: NSLayoutAttributeCenterY
                                                                       multiplier: 1.0000f
                                                                         constant: 0.0000f];
        
        
        
        NSLayoutConstraint *layoutConstraintLabelLeadingMargin = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                                              attribute: NSLayoutAttributeLeadingMargin
                                                                                              relatedBy: NSLayoutRelationEqual
                                                                                                 toItem: self.label
                                                                                              attribute: NSLayoutAttributeLeading
                                                                                             multiplier: 1.0000f
                                                                                               constant: 0.0000f];
        layoutConstraintLabelLeadingMargin.priority = UILayoutPriorityRequired;
        
        NSLayoutConstraint *layoutConstraintLabelTrailing = [NSLayoutConstraint constraintWithItem: self.effectView.contentView
                                                                                         attribute: NSLayoutAttributeTrailing
                                                                                         relatedBy: NSLayoutRelationEqual
                                                                                            toItem: self.label
                                                                                         attribute: NSLayoutAttributeTrailing
                                                                                        multiplier: 1.0000f
                                                                                          constant: 4.0000f];
        layoutConstraintLabelTrailing.priority = UILayoutPriorityRequired;
        
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
        
        NSArray *constraints = @[layoutConstraintLeftItem, layoutConstraintMiddleItemLeft, imageCenterY, cellHeight, effectsHeight, layoutConstraint2,
                                 layoutConstraint4, layoutConstraintLabelTop, imageHeight, imageSizeWidth, imageSizeHeight,
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

- (void)layoutSubviews {
    [super layoutSubviews];
}

+ (UIBlurEffectStyle)blurEffectStyle {
    return UIBlurEffectStyleExtraLight;
}

@end
