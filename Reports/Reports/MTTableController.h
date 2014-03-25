//
//  MTTableController.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTDataFormatter, MTQuery;

@interface MTTableController : UICollectionViewController

@property (nonatomic, strong, readonly) MTDataFormatter *tableFormatter;

- (id)initWithQuery:(MTQuery *)query;
- (NSUInteger)rowCount;
- (NSUInteger)columnCount;

@end
