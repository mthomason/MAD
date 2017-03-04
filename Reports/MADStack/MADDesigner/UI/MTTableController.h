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

@class MADDataFormatter, MTQuery;

@interface MADTableController : UICollectionViewController

    @property (nonatomic, strong, readonly) MADDataFormatter *tableFormatter;

    - (instancetype)initWithQuery:(MTQuery *)query;
    - (NSUInteger)rowCount;
    - (NSUInteger)columnCount;

@end

#endif
