//
//  MADVibrantTableViewCellBase.h
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MADTableViewCellMargin.h"

@protocol MADVibrantTableViewCellDelegate <NSObject>

- (UIBlurEffect *)blurEffectForCell:(UITableViewCell *)cell;

@end

@interface MADVibrantTableViewCellBase : UITableViewCell

@property (nonatomic, weak) id <MADVibrantTableViewCellDelegate> vibrantTableViewCellDelegate;

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, weak) UIVisualEffectView *effectView;
@property (nonatomic, assign) MADVibrantTableViewCellMarginStyle marginStyle;

@property (nonatomic, strong) NSArray *layoutConstraints;
@property (atomic, assign) BOOL updatingConstraints;

+ (UIBlurEffectStyle)blurEffectStyle;

- (void)updateConstraints;
- (void)initalize;

@end
