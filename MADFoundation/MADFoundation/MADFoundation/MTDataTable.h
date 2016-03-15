//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDataTable_h
#define Reports_MTDataTable_h

#import <Foundation/NSObject.h>
#import <MADFoundation/NSFileManager+Common.h>
#import <MADFoundation/MTCacheProtocol.h>
#import <MADFoundation/MADDataProtocol.h>

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

@property (nonatomic, weak) IBOutlet id <MTCacheProtocol> cacheDelegate;
@property (nonatomic, weak) IBOutlet id <MADDataProtocol> dataDelegate;

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSMutableArray *columnKeys;
@property (nonatomic, strong, readwrite) NSMutableArray *sortDescriptors;
@property (nonatomic, strong, readwrite) NSMutableDictionary *columns;  // The data for fast summeraztion.
@property (nonatomic, assign, readwrite) NSUInteger rowCounter;
@property (nonatomic, assign) NSUInteger tag;

- (instancetype)initWithId:(NSUInteger)objectId;
- (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache;
- (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns;

- (NSURL *)urlForGroupIdentifier:(NSString *)groupIdentifier;

- (bool)cachePlist:(id)data forGroupIdentifier:(NSString *)groupIdentifier;
- (bool)cacheForGroupIdentifier:(NSString *)groupIdentifier;
- (NSDictionary *)plist;

- (void)loadWithPlist:(id)plist;
- (void)loadFromCacheWithGroupIdentifier:(NSString *)groupIdentifier;

- (void)addColumn:(MTDataColumn *)column;
- (void)addRow:(NSArray *)row;
- (void)addRowWithDataForFieldKeys:(NSDictionary *)row;

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors;

- (void)removeAllObjects;

- (id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;
- (id)objectAtRow:(NSUInteger)row;

- (NSEnumerator *)columnsEnumerator;
- (NSEnumerator *)objectEnumerator;

- (void)beginBulkInsert;
- (void)endBulkInsert;

- (NSArray *)allObjects;
- (NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit;
- (NSArray *)objectsForGroupKeys:(NSArray *)groupKeys;

- (NSUInteger)count;
- (NSUInteger)numberOfColumns;
- (NSUInteger)numberOfRows;

- (NSEnumerator *)enumeratorForGroupLevel:(NSUInteger)groupLevel withKeys:(NSArray *)keys accending:(BOOL)accending;
- (NSEnumerator *)enumeratorForAllObjectsSorted;
- (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly;
- (NSEnumerator *)enumeratorForKeyObjectsSorted;

- (NSDictionary *)dataForCacheId:(NSNumber *)cacheId;

@end

#endif
