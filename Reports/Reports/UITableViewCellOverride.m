//
//  UITableViewCellOverride.m
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellOverride.h"
#import "Constants.h"

@implementation UITableViewCellOverride

+ (CGFloat)defaultHeight {
    return MNSTableViewCellOverrideHeightDefault;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
