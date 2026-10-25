//
//  MADTableViewCellQueryTableName.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_UITableViewCellTableName_h
#define Reports_UITableViewCellTableName_h

#import <UIKit/UITableViewCell.h>


@interface MADTableViewCellQueryTableName : UITableViewCell

	@property (nonatomic, assign) int64_t tableID;

	+ (CGFloat)defaultHeight;

@end

#endif
