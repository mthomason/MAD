//
//  MADTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADTableController_h
#define MAD_MADTableController_h

#import <UIKit/UIKit.h>

@class MADDataFormatter, MADDatabase, MADQuery, NSManagedObjectID;
@protocol MADQueryDatabaseProtocol;

@interface MADTableController : UICollectionViewController

	@property (nonatomic, strong, readonly) MADDataFormatter *tableFormatter;

	- (instancetype)initWithQuery:(MADQuery <MADQueryDatabaseProtocol> *)query
						 database:(MADDatabase *)database
						  tableID:(NSManagedObjectID *)tableID;
	- (NSUInteger)rowCount;
	- (NSUInteger)columnCount;

@end

#endif
