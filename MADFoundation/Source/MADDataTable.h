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

#pragma mark - Storage protocols

// MADDataTable is a class cluster: the base class owns the metadata, the plist
// shape and NSCoding, and each subclass owns the actual row storage.  These three
// protocols are that split written down, so a driver can be handed "something I
// can write rows into" without also being handed the ability to read them back --
// which is what the SQL Server driver needs and all it needs.
//
// MADDataTable itself lists all three; it satisfies every @required member with an
// assertion (MADDataTable.m), so a subclass that forgets an override is caught in
// Debug rather than silently discarding rows.

/// Everything that mutates stored rows, plus the column metadata a writer needs in
/// order to describe the rows it is about to write.  The metadata lives here rather
/// than in a protocol of its own because the MySQL fetch is the only caller that
/// reads it back, and it reads it *while writing*: on the first row it corrects a
/// column's type from the value it actually received (MysqlFetch+DataTable.m).
@protocol MADDataTableWriting <NSObject>
@required
- (void)removeAllObjects;
- (void)addColumn:(nonnull MADDataColumn *)column;
@property (nonatomic, strong, nonnull, readonly) NSMutableArray <NSString *> *columnKeys;
@property (nonatomic, strong, nonnull, readonly) NSMutableDictionary <NSString *, MADDataColumn *> *columns;
- (bool)addRow:(nonnull NSArray *)row error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (void)addRowWithDataForFieldKeys:(nonnull NSDictionary<NSString *, id> *)row;
- (void)sortUsingDescriptors:(nonnull NSArray<NSSortDescriptor *> *)sortDescriptors;
/// Optional: a subclass that does not need a bulk-insert fast path may ignore these.
@optional
- (void)beginBulkInsert;
- (void)endBulkInsert;
@end

/// Random access to stored rows, and the row/column counts.
@protocol MADDataTableReading <NSObject>
@required
- (nullable id)objectAtRow:(NSUInteger)row;
- (nullable id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;
- (nonnull NSArray *)allObjects;
- (nonnull NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit;
- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID error:(NSError * _Nullable __autoreleasing *_Nullable)error;
- (NSUInteger)numberOfRows;
- (NSUInteger)numberOfColumns;
- (NSUInteger)count;
@end

/// Sequential access to stored rows.
@protocol MADDataTableCursoring <NSObject>
@required
- (nonnull NSEnumerator<MADDataColumn *> *)columnsEnumerator;
- (nonnull NSEnumerator *)objectEnumerator;
/// Optional: these three are sqlite-only.  MADDataTableVirtual stores its rows in
/// memory and has no sorted cursor or group-key lookup, so it cannot honour them.
@optional
- (nonnull NSEnumerator *)enumeratorForKeyObjectsSorted;
- (nonnull NSEnumerator *)enumeratorForAllObjectsSorted;
- (nonnull NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly;
- (nonnull NSArray<NSDictionary *> *)objectsForGroupKeys:(nonnull NSArray<NSString *> *)groupKeys;
@end

@interface MADDataTable : NSObject <NSCoding, NSFastEnumeration,
									MADDataTableWriting, MADDataTableReading, MADDataTableCursoring>

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

#pragma mark - Count and Metadata
// The row/column accessors, the enumerators and the write port are declared by
// <MADDataTableWriting>, <MADDataTableReading> and <MADDataTableCursoring> above.

- (nonnull NSString *)newFilenameMDCache;

@end

#endif
