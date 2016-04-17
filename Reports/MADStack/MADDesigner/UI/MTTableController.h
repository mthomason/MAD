//
//  MADTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTableController_h
#define MAD_MADTableController_h

#import "MADViewController.h"

@class MADDataFormatter, MTQuery;

@interface MADTableController : MADCollectionViewController

    @property (nonatomic, strong, readonly) MADDataFormatter *tableFormatter;

    - (instancetype)initWithQuery:(MTQuery *)query;
    - (NSUInteger)rowCount;
    - (NSUInteger)columnCount;

@end

#endif
