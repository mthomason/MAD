//
//  MADVibrantTableView.m
//  MAD
//
//  Created by Michael Thomason on 10/20/14.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADVibrantTableView.h"

#import <UIKit/UIVisualEffectView.h>
#import <UIKit/UINibLoading.h>

#import "MADVibrantTableViewCell.h"

@implementation MADVibrantTableView

- (void)awakeFromNib {
    [super awakeFromNib];
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:[MADVibrantTableViewCell blurEffectStyle]];
    UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
    self.backgroundView = visualEffectsView;
    self.backgroundColor = [UIColor clearColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.estimatedRowHeight = 44.0;
    self.rowHeight = UITableViewAutomaticDimension;
    self.visualEffectsView = visualEffectsView;
}

@end
