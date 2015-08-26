//
//  MTTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTTableController_h
#define MAD_MTTableController_h

#import <UIKit/UIKit.h>
#import "MADViewController.h"

@class MTDataFormatter, MTQuery;

@interface MTTableController : MADCollectionViewController

@property (nonatomic, strong, readonly) MTDataFormatter *tableFormatter;

- (instancetype)initWithQuery:(MTQuery *)query;
- (NSUInteger)rowCount;
- (NSUInteger)columnCount;

@end

#endif
