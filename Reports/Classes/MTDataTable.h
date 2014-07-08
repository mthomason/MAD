//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTable_h
#define Reports_MTDataTable_h

#import <Foundation/Foundation.h>
#import "Constants.h"

typedef NS_ENUM(NSUInteger, MTDataTableType) {
	MTDataTableTypeVirtual,
    MTDataTableTypePhysical,
};

typedef NS_ENUM(NSUInteger, MTDataTableParameters) {
    MTDataTableTypeOfTable,
	MTDataTableObjectId,
    MTDataTableNumberOfColumns,
};

@class MTDataColumn;

@interface MTDataTable : NSObject
    <NSCoding, NSFastEnumeration>

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSMutableArray *columnKeys;
@property (nonatomic, strong, readwrite) NSMutableArray *sortDescriptors;
@property (nonatomic, strong, readwrite) NSMutableDictionary *columns;  // The data for fast summeraztion.
@property (nonatomic, assign, readwrite) NSUInteger rowCounter;

+ (MTDataTable *)newDataTableForIdentifier:(NSString *)identifier;
+ (id)dataTableFactory:(NSDictionary *)parameters;

- (id)initWithId:(NSUInteger)objectId;
- (id)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache;
- (id)initWithNumberOfColumns:(NSUInteger)numberOfColumns;

- (void)setObjectId:(NSUInteger)objectId;   //Object id needs to be set for caching.

- (void)cache;
- (id)plist;

- (void)loadWithPlist:(id)plist;
- (void)loadFromCache;

- (void)addColumn:(MTDataColumn *)column;
- (void)addRow:(NSArray *)row;
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row;

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;

- (void)removeAllObjects;

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;
- (id)objectAtRow:(NSInteger)row;

- (NSEnumerator *)columnsEnumerator;
- (NSEnumerator *)objectEnumerator;

- (void)beginBulkInsert;
- (void)endBulkInsert;

- (NSArray *)allObjects;
- (NSArray *)objectAtRow:(NSInteger)row limit:(NSUInteger)limit;
- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys;

- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending;
- (NSEnumerator *)enumeratorForAllObjectsSorted;
- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly;
- (NSEnumerator *)enumeratorForRowIds:(NSIndexSet *)rowids;
- (NSEnumerator *)enumeratorForKeyObjectsSorted;

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId;

- (id)resultsForAggregateType:(MTAggregateGroupByType)groupByType
                     function:(MTAggregateFunctionType)function
                     fieldKey:(NSString *)fieldKey
                    groupKeys:(NSArray *)groupKeys
                       rowids:(NSIndexSet *)rowids;

@end

#endif
