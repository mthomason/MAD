//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDataColumn;

@interface MTDataTable : NSObject
    <NSCoding>

@property (nonatomic, strong, readonly) NSMutableArray *columnKeys;
@property (nonatomic, strong, readonly) NSMutableDictionary *columns;
@property (nonatomic, strong, readonly) NSMutableArray *sortIndex;
@property (nonatomic, strong, readwrite) NSURL *url;

- (id)initWithId:(NSUInteger)objectId;
- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns;

- (void)setObjectId:(NSUInteger)objectId;   //Object id needs to be set for caching.

- (void)cache;
- (void)removeAllObjects;

- (id)plist;

- (void)addColumn:(MTDataColumn *)column;
- (void)addRow:(NSArray *)row;
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row;

- (id)objectAtIndex:(NSInteger)index;
- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;
- (NSArray *)sortedRepresentationUsingDescriptors:(NSArray *)sortDescriptors;

- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

@end
