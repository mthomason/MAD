//
//  MADTableViewCellQueryTableName.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_UITableViewCellTableName_h
#define Reports_UITableViewCellTableName_h

#import <UIKit/UITableViewCell.h>

@class NSManagedObjectID;

@interface MADTableViewCellQueryTableName : UITableViewCell

	@property (nonatomic, assign) int64_t tableID;

	+ (CGFloat)defaultHeight;

@end

#endif
