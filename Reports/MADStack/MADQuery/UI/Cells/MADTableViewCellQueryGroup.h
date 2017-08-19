//
//  UITableViewCellQueryGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellQueryGroup_h
#define Reports_UITableViewCellQueryGroup_h

#import "MTAutoLayoutTableViewCell.h"

@class NSManagedObjectID, UILabel;

@interface MADTableViewCellQueryGroup : MTAutoLayoutTableViewCell

    @property (nonatomic, copy) NSManagedObjectID *groupID;

    @property (nonatomic, weak) IBOutlet UILabel *labelDetail;
    @property (nonatomic, weak) IBOutlet UILabel *labelMain;

    + (CGFloat)defaultHeight;

@end

#endif
