//
//  UITableViewCellOverride.h
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellOverride_h
#define Reports_UITableViewCellOverride_h

#import <UIKit/UIKit.h>
#import "MTAutoLayoutTableViewCell.h"

@interface UITableViewCellOverride : MTAutoLayoutTableViewCell

+ (CGFloat)defaultHeight;

@end

#endif
