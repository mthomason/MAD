//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

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

+ (id)dataTableFactory:(NSDictionary *)parameters;

- (id)initWithId:(NSUInteger)objectId;
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

- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending;
- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId;

@end
