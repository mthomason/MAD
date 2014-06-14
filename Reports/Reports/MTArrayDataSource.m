//
//  MTArrayDataSource.m
//  MAD
//
//  Created by Michael Thomason on 6/14/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTArrayDataSource.h"
#import "MTArrayDataSourcePrivate.h"
#import "MTArrayDataSourceCollectionView.h"
#import "MTArrayDataSourceTableView.h"

@implementation MTArrayDataSource

- (id)initWithItems:(NSArray *)items
     cellIdentifier:(NSString *)cellIdentifier
 configureCellBlock:(MTCellConfigureBlock)cellConfigureBlock
            andType:(MTDataSourceType)type {
    
    switch (type) {
        case MTDataSourceTypeCollectionView: {
            MTArrayDataSourceCollectionView *dataSource = [[MTArrayDataSourceCollectionView alloc] init];
            self = dataSource;
            break;
        }
        case MTDataSourceTypeTableView: {
            MTArrayDataSourceTableView *dataSource = [[MTArrayDataSourceTableView alloc] init];
            self = dataSource;
            break;
        }
        default:
            break;
    }

    if (self) {
        
        NSMutableArray *itemsm = [NSMutableArray arrayWithArray:items];
        [self setItems: itemsm];
        
        NSString *identifer = [NSString stringWithString:cellIdentifier];
        [self setCellIdentifier: identifer];
        
        MTCellConfigureBlock block = [cellConfigureBlock copy];
        [self setConfigureCellBlock: block];
        
    }
    return self;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemAtIndex:[indexPath row]];
}

- (id)itemAtIndex:(NSUInteger)index {
    return self.items[index];
}

- (void)updateWithItems:(NSArray *)items {
    NSMutableArray *itemsm = [NSMutableArray arrayWithArray:items];
    [self setItems:itemsm];
}

- (NSInteger)count {
    return [[self items] count];
}

- (void)removeItemAtIndex:(NSUInteger)index {
    [[self items] removeObjectAtIndex:index];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes {
    [[self items] removeObjectsAtIndexes:indexes];
}

- (void)removeItemAtIndexPath:(NSIndexPath *)indexPath {
    [self removeItemAtIndex:(NSUInteger)indexPath.row];
}

@end
