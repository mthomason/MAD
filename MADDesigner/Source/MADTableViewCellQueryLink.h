//
//  MADTableViewCellQueryLink.h
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_UITableViewCellQueryLink_h
#define Reports_UITableViewCellQueryLink_h

#import "MTAutoLayoutTableViewCell.h"

@class UILabel;

@interface MADTableViewCellQueryLink : MTAutoLayoutTableViewCell

	@property (nonatomic, assign) int64_t linkID;

	@property (nonatomic, weak) IBOutlet UILabel *labelTableLeft;
	@property (nonatomic, weak) IBOutlet UILabel *labelTableRight;
	@property (nonatomic, weak) IBOutlet UILabel *labelJoinArrow;
	@property (nonatomic, weak) IBOutlet UILabel *labelJoinDesc;

	+ (CGFloat)defaultHeight;

@end

#endif
