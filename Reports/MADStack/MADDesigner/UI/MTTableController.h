//
//  MADTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTableController_h
#define MAD_MADTableController_h

#import <UIKit/UICollectionViewController.h>

@class MADDataFormatter, MTDatabase, MTQuery, NSManagedObjectID;

@interface MADTableController : UICollectionViewController

    @property (nonatomic, strong, readonly) MADDataFormatter *tableFormatter;

    - (instancetype)initWithQuery:(MTQuery *)query database:(MTDatabase *)database
                          tableID:(NSManagedObjectID *)tableID;
    - (NSUInteger)rowCount;
    - (NSUInteger)columnCount;

@end

#endif
