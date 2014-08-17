//
//  MTTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

@class MTDataFormatter, MTQuery;

@interface MTTableController : UICollectionViewController

@property (nonatomic, strong, readonly) MTDataFormatter *tableFormatter;

- (instancetype)initWithQuery:(MTQuery *)query NS_DESIGNATED_INITIALIZER;
- (NSUInteger)rowCount;
- (NSUInteger)columnCount;

@end
