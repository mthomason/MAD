//
//  MADVibrantTableViewCellBase.h
//  MAD
//
//  Created by Michael Thomason on 10/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADVibrantTableViewCellBase_h
#define MAD_Designer_MADVibrantTableViewCellBase_h

#import "MADTableViewCellMargin.h"
#import <UIKit/UITableViewCell.h>
#import <UIKit/UIVisualEffectView.h>

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

#endif
