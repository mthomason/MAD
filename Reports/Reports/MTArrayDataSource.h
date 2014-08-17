//
//  MTArrayDataSource.h
//  MAD
//
//  Created by Michael Thomason on 6/14/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTArrayDataSource_h
#define MAD_MTArrayDataSource_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MTDataSourceType) {
    MTDataSourceTypeTableView,
    MTDataSourceTypeCollectionView
};

typedef void (^MTCellConfigureBlock)(id cell, id item);

@interface MTArrayDataSource : NSObject

- (instancetype)initWithItems:(NSArray *)items
     cellIdentifier:(NSString *)cellIdentifier
 configureCellBlock:(MTCellConfigureBlock)cellConfigureBlock
            andType:(MTDataSourceType)type;


- (NSInteger)count;

- (id)itemAtIndex:(NSUInteger)index;
- (id)itemAtIndexPath:(NSIndexPath *)indexPath;

- (void)removeObjectsInArray:(NSArray *)array;
- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)removeItemAtIndex:(NSUInteger)index;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;

- (void)updateWithItems:(NSArray *)items;

@end

#endif
