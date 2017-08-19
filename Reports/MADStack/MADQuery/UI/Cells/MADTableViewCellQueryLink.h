//
//  MADTableViewCellQueryLink.h
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellQueryLink_h
#define Reports_UITableViewCellQueryLink_h

#import "MTAutoLayoutTableViewCell.h"

@class NSManagedObjectID, UILabel;

@interface MADTableViewCellQueryLink : MTAutoLayoutTableViewCell

    @property (nonatomic, copy) NSManagedObjectID *linkID;

    @property (nonatomic, weak) IBOutlet UILabel *labelTableLeft;
    @property (nonatomic, weak) IBOutlet UILabel *labelTableRight;
    @property (nonatomic, weak) IBOutlet UILabel *labelJoinArrow;
    @property (nonatomic, weak) IBOutlet UILabel *labelJoinDesc;

    + (CGFloat)defaultHeight;

@end

#endif
