//
//  UITableViewCellTableName.m
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewCellTableName.h"
#import "Constants.h"

@implementation UITableViewCellTableName

- (void)dealloc {
    [_tableID release];
    [super dealloc];
}

+ (CGFloat)defaultHeight {
    return MNSTableViewCellTableNameHeightDefault;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
