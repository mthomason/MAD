//
//  UITableViewCellTableName.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewCellTableName_h
#define Reports_UITableViewCellTableName_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface UITableViewCellTableName : UITableViewCell

@property (nonatomic, strong) NSManagedObjectID *tableID;

+ (CGFloat)defaultHeight;

@end

#endif
