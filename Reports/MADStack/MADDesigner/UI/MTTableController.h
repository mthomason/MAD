//
//  MTTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTableController_h
#define MAD_MADTableController_h

#import "MADViewController.h"

@class MADDataFormatter;
@class MTQuerySampleDataTable;

@interface MADTableController : MADCollectionViewController

    @property (nonatomic, strong, readonly) MADDataFormatter *tableFormatter;

    - (instancetype)initWithQuery:(MTQuerySampleDataTable *)query;
    - (NSUInteger)rowCount;
    - (NSUInteger)columnCount;

@end

#endif
