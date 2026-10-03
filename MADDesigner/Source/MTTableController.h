//
//  MADTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADTableController_h
#define MAD_MADTableController_h

#import <UIKit/UICollectionViewController.h>

@class MADDataFormatter, MADDatabase, MADQuery, NSManagedObjectID;
@protocol MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol;

@interface MADTableController : UICollectionViewController

@property (nonatomic, strong, readonly) MADDataFormatter *tableFormatter;

- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol, MADQueryDatabaseRangeProtocol> *)query
					 database:(MADDatabase *)database
					  tableID:(int64_t)tableID;
- (NSUInteger)rowCount;
- (NSUInteger)columnCount;

@end

#endif
