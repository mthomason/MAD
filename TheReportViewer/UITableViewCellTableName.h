//
//  UITableViewCellTableName.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface UITableViewCellTableName : UITableViewCell

@property (retain) NSManagedObjectID *tableID;

+ (CGFloat)defaultHeight;

@end