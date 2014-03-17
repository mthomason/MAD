//
//  UITableViewCellQueryGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellQueryGroup_h
#define Reports_UITableViewCellQueryGroup_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MTAutoLayoutTableViewCell.h"

@interface UITableViewCellQueryGroup : MTAutoLayoutTableViewCell

@property (retain) NSManagedObjectID *tableID;

@property (nonatomic, assign) IBOutlet UILabel *labelDetail;
@property (nonatomic, assign) IBOutlet UILabel *labelMain;

+ (CGFloat)defaultHeight;

@end

#endif
