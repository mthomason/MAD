//
//  MTTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDataTablePlist_h
#define MAD_MADDataTablePlist_h

#import <Foundation/NSObject.h>
#import <Foundation/NSEnumerator.h>

@class MADDataColumn, NSMutableArray<ObjectType>,
       NSDictionary<__covariant KeyType, __covariant ObjectType>,
       NSMutableDictionary<KeyType, ObjectType>, NSSortDescriptor;

typedef NS_ENUM(short, MADDataTableParameters) {
    MADDataTableParametersType,
	MADDataTableParametersIdentifier,
    MADDataTableParametersNumberOfColumns,
};

@interface MADDataTablePlist : NSObject
  <NSCoding,
    NSFastEnumeration>

    @property (nonatomic, readwrite, copy)   NSString *name;
    @property (nonatomic, readwrite, strong) NSMutableArray *columnKeys;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSSortDescriptor *> *sortDescriptors;
    @property (nonatomic, readwrite, strong) NSMutableDictionary <NSString *, MADDataColumn *> *columns;
    @property (nonatomic, readwrite, assign) NSUInteger rowCounter;
    @property (nonatomic, readwrite, assign) NSUInteger tag;

    - (instancetype)initWithId:(NSUInteger)objectId;
    - (instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache;
    - (instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns;

    - (BOOL)cacheWithUrl:(NSURL *)url;

    - (NSDictionary *)copyPlist;
    - (void)loadWithPlist:(NSDictionary *)plist;
    - (void)loadFromCacheWithUrl:(NSURL *)url;

    - (void)addColumn:(MADDataColumn *)column;
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
    - (NSArray <__kindof NSDictionary *> *)objectsForGroupKeys:(NSArray *)groupKeys;

    - (NSUInteger)count;
    - (NSUInteger)numberOfColumns;
    - (NSUInteger)numberOfRows;

    - (NSEnumerator *)enumeratorForAllObjectsSorted;
    - (NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly;
    - (NSEnumerator *)enumeratorForKeyObjectsSorted;

    - (NSDictionary *)copyDataForCacheId:(NSUInteger)cacheId;

    - (NSString *)newFilenameMDCache;

@end

#endif
