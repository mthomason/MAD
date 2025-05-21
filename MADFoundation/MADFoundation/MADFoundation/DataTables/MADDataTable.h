//
//  MADDataTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDataTable_h
#define MAD_MADDataTable_h

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>

@class MADDataColumn;

extern NSString * const _Nonnull MADDataTableErrorDomain;

typedef NS_ENUM(short, MADDataTableParameters) {
	MADDataTableParametersType,
	MADDataTableParametersIdentifier,
	MADDataTableParametersNumberOfColumns,
};

@interface MADDataTable : NSObject <NSCoding, NSFastEnumeration>

#pragma mark - Properties

@property (nonatomic, copy, nonnull)   NSString *name;
@property (nonatomic, strong, nonnull) NSMutableArray <NSString *> *columnKeys;
@property (nonatomic, strong, nonnull) NSMutableArray <NSSortDescriptor *> *sortDescriptors;
@property (nonatomic, strong, nonnull) NSMutableDictionary <NSString *, MADDataColumn *> *columns;
@property (nonatomic, assign) NSUInteger rowCounter;
@property (nonatomic, assign) NSUInteger tag;

#pragma mark - Initializers

- (nonnull instancetype)initWithId:(NSUInteger)objectId;
- (nonnull instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache;
- (nonnull instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns;

#pragma mark - Caching

- (BOOL)cacheWithUrl:(nonnull NSURL *)url error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)loadFromCacheWithUrl:(nonnull NSURL *)url error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - Plist Operations

- (nonnull NSDictionary *)copyPlist;
- (BOOL)loadWithPlist:(nonnull NSDictionary *)plist error:(NSError * _Nullable __autoreleasing * _Nullable)outError;

#pragma mark - Row and Column Operations

- (void)addColumn:(nonnull MADDataColumn *)column;
- (bool)addRow:(nonnull NSArray *)row error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (void)addRowWithDataForFieldKeys:(nonnull NSDictionary<NSString *, id> *)row;
- (void)removeAllObjects;
- (nullable id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;
- (nullable id)objectAtRow:(NSUInteger)row;
- (void)sortUsingDescriptors:(nonnull NSArray<NSSortDescriptor *> *)sortDescriptors;

#pragma mark - Bulk Operations

- (void)beginBulkInsert;
- (void)endBulkInsert;

#pragma mark - Data Retrieval

- (nonnull NSArray *)allObjects;
- (nonnull NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit;
- (nonnull NSArray<NSDictionary *> *)objectsForGroupKeys:(nonnull NSArray<NSString *> *)groupKeys;
- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError * _Nullable __autoreleasing *_Nullable)error;

#pragma mark - Enumerators

- (nonnull NSEnumerator<MADDataColumn *> *)columnsEnumerator;
- (nonnull NSEnumerator *)objectEnumerator;
- (nonnull NSEnumerator *)enumeratorForKeyObjectsSorted;
- (nonnull NSEnumerator *)enumeratorForAllObjectsSorted;
- (nonnull NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly;

#pragma mark - Count and Metadata

- (NSUInteger)numberOfRows;
- (NSUInteger)numberOfColumns;
- (NSUInteger)count;
- (nonnull NSString *)newFilenameMDCache;

@end

#endif
