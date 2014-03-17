//
//  UITableViewCellQueryLink.h
//  Reports
//
//  Created by Michael Thomason on 1/23/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellQueryLink_h
#define Reports_UITableViewCellQueryLink_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MTAutoLayoutTableViewCell.h"

@interface UITableViewCellQueryLink : MTAutoLayoutTableViewCell

@property (retain) NSManagedObjectID *tableID;

@property (nonatomic, assign) IBOutlet UILabel *labelTableLeft;
@property (nonatomic, assign) IBOutlet UILabel *labelTableRight;
@property (nonatomic, assign) IBOutlet UILabel *labelJoinArrow;
@property (nonatomic, assign) IBOutlet UILabel *labelJoinDesc;

+ (CGFloat)defaultHeight;

@end

#endif
