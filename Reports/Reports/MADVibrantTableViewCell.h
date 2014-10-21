//
//  MADVibrantTableViewCell.h
//  MAD
//
//  Created by Michael Thomason on 10/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MADVibrantTableViewCellMarginStyle) {
    MADTableViewCellMarginStyleTop,
    MADTableViewCellMarginStyleMiddle,
    MADTableViewCellMarginStyleBottom,
    MADTableViewCellMarginStyleFat
};

@interface MADVibrantTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, weak) UIVisualEffectView *effectView;
@property (nonatomic, assign) MADVibrantTableViewCellMarginStyle marginStyle;

+ (UIBlurEffectStyle)blurEffectStyle;

@end
