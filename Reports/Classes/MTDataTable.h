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
    <NSCoding, NSFastEnumeration>

@property (nonatomic, strong, readwrite) NSURL *url;

- (id)initWithId:(NSUInteger)objectId;
- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns;
- (void)setObjectId:(NSUInteger)objectId;   //Object id needs to be set for caching.

- (void)cache;
- (id)plist;

- (void)addColumn:(MTDataColumn *)column;
- (void)addRow:(NSArray *)row;
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row;

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;

- (void)removeAllObjects;

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;
- (id)objectAtRow:(NSInteger)row;

- (NSEnumerator *)columnsEnumerator;
- (NSEnumerator *)objectEnumerator;

- (NSArray *)allObjects;
- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

@end
