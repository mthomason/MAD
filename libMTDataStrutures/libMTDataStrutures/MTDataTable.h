//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTDataColumn, MTDataTableLocation;

@interface MTDataTable : NSObject
    <NSCoding>

@property (nonatomic, strong, readonly) NSMutableArray *columnKeys;
@property (nonatomic, strong, readonly) NSMutableDictionary *columns;
@property (nonatomic, strong, readwrite) NSURL *url;

- (id)initWithId:(NSUInteger)objectId;
- (void)setObjectId:(NSUInteger)objectId;   //Object id needs to be set for caching.
- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns;
- (id)initWithPlist:(id)plist;

- (id)plist;

- (void)addColumn:(MTDataColumn *)column;
- (void)addRow:(NSArray *)row;
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row;

- (id)objectAtIndex:(NSInteger)index;
- (id)value:(MTDataTableLocation *)location;

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;

- (NSArray *)sortedRepresentationUsingDescriptors:(NSArray *)sortDescriptors;

- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

- (void)cache;

- (void)removeAllObjects;

@end
