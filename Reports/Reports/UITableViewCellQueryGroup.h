//
//  UITableViewCellQueryGroup.h
//  Reports
//
//  Created by Michael Thomason on 2/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface UITableViewCellQueryGroup : UITableViewCell

@property (retain) NSManagedObjectID *tableID;

@property (nonatomic, assign) IBOutlet UILabel *labelDetail;
@property (nonatomic, assign) IBOutlet UILabel *labelMain;

@end