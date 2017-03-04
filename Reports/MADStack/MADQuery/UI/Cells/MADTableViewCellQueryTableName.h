//
//  MADTableViewCellQueryTableName.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellTableName_h
#define Reports_UITableViewCellTableName_h

#import <UIKit/UITableViewCell.h>

@class NSManagedObjectID;

@interface MADTableViewCellQueryTableName : UITableViewCell

    @property (nonatomic, copy) NSManagedObjectID *tableID;

    + (CGFloat)defaultHeight;

@end

#endif
