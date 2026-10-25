//
//  UITableViewCellQueryGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_UITableViewCellQueryGroup_h
#define Reports_UITableViewCellQueryGroup_h

#import "MTAutoLayoutTableViewCell.h"

@class UILabel;

@interface MADTableViewCellQueryGroup : MTAutoLayoutTableViewCell

	@property (nonatomic, assign) int64_t groupID;

	@property (nonatomic, weak) IBOutlet UILabel *labelDetail;
	@property (nonatomic, weak) IBOutlet UILabel *labelMain;

	+ (CGFloat)defaultHeight;

@end

#endif
