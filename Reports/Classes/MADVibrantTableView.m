//
//  MADVibrantTableView.m
//  MAD
//
//  Created by Michael Thomason on 10/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADVibrantTableView.h"
#import "MADVibrantTableViewCell.h"

@implementation MADVibrantTableView

- (void)awakeFromNib {
  
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:[MADVibrantTableViewCell blurEffectStyle]];
    UIVisualEffectView *visualEffectsView = [[UIVisualEffectView alloc] initWithEffect:effect];
    self.backgroundView = visualEffectsView;
    self.backgroundColor = [UIColor clearColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.estimatedRowHeight = 44.0000f;
    self.rowHeight = UITableViewAutomaticDimension;
    self.visualEffectsView = visualEffectsView;
    [super awakeFromNib];
}

@end
