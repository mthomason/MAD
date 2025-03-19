//
//  MADDataTable.h
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDataTable_h
#define MAD_MADDataTable_h

#import <Foundation/Foundation.h>

@class MADDataColumn, NSMutableArray<ObjectType>,
	NSDictionary<__covariant KeyType, __covariant ObjectType>,
	NSMutableDictionary<KeyType, ObjectType>, NSSortDescriptor;

typedef NS_ENUM(short, MADDataTableParameters) {
	MADDataTableParametersType,
	MADDataTableParametersIdentifier,
	MADDataTableParametersNumberOfColumns,
};

@interface MADDataTable : NSObject <NSCoding, NSFastEnumeration>

#pragma mark - Properties

/// The name of the data table.
@property (nonatomic, copy, nonnull)   NSString *name;

/// Keys for all columns in the table.
@property (nonatomic, strong, nonnull) NSMutableArray <NSString *> *columnKeys;

/// Sort descriptors to define table sorting.
@property (nonatomic, strong, nonnull) NSMutableArray <NSSortDescriptor *> *sortDescriptors;

/// Dictionary of columns, keyed by their names.
@property (nonatomic, strong, nonnull) NSMutableDictionary <NSString *, MADDataColumn *> *columns;

/// Counter to keep track of rows.
@property (nonatomic, assign) NSUInteger rowCounter;

/// Tag to identify the table (optional usage).
@property (nonatomic, assign) NSUInteger tag;

#pragma mark - Initializers

/// Initializes a data table with a unique ID.
- (nonnull instancetype)initWithId:(NSUInteger)objectId;

/// Initializes a data table with optional cache loading.
- (nonnull instancetype)initWithId:(NSUInteger)objectId fromCache:(BOOL)fromCache;

/// Initializes a data table with a specific number of columns.
- (nonnull instancetype)initWithNumberOfColumns:(NSUInteger)numberOfColumns;

#pragma mark - Caching

/// Caches the current table to a specified URL.
/// @param url The file URL where the table will be cached.
/// @return YES if caching is successful, NO otherwise.
- (BOOL)cacheWithUrl:(nonnull NSURL *)url;

/// Loads the table from a cached plist.
/// @param url The file URL from which to load the cache.
- (void)loadFromCacheWithUrl:(nonnull NSURL *)url;

#pragma mark - Plist Operations

/// Creates a copy of the table as a plist dictionary.
- (nonnull NSDictionary *)copyPlist;

/// Loads data into the table from a plist dictionary.
- (void)loadWithPlist:(nonnull NSDictionary *)plist;

#pragma mark - Row and Column Operations

/// Adds a column to the table.
/// @param column The column to add.
- (void)addColumn:(nonnull MADDataColumn *)column;

/// Adds a row to the table.
/// @param row The data for the row to add.
/// @param error An optional error pointer for failure reporting.
- (bool)addRow:(nonnull NSArray *)row error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/// Adds a row with data mapped to specific field keys.
/// @param row A dictionary mapping field keys to data values.
- (void)addRowWithDataForFieldKeys:(nonnull NSDictionary<NSString *, id> *)row;

/// Removes all rows and columns from the table.
- (void)removeAllObjects;

/// Fetches the object at the specified row and column.
/// @param row The row index.
/// @param column The column index.
/// @return The object at the specified location, or nil if not found.
- (nullable id)objectAtRow:(NSUInteger)row column:(NSUInteger)column;

/// Fetches the object at the specified row.
/// @param row The row index.
/// @return The object at the specified row, or nil if not found.
- (nullable id)objectAtRow:(NSUInteger)row;

/// Sorts the table using the specified sort descriptors.
/// @param sortDescriptors The array of sort descriptors.
- (void)sortUsingDescriptors:(nonnull NSArray<NSSortDescriptor *> *)sortDescriptors;

#pragma mark - Bulk Operations

/// Prepares the table for bulk insertion of rows.
- (void)beginBulkInsert;

/// Finalizes bulk insertion of rows.
- (void)endBulkInsert;

#pragma mark - Data Retrieval

/// Fetches all objects in the table.
- (nonnull NSArray *)allObjects;

/// Fetches objects at the specified row with a limit.
/// @param row The starting row index.
/// @param limit The maximum number of rows to fetch.
/// @return An array of objects.
- (nonnull NSArray *)objectAtRow:(NSUInteger)row limit:(NSUInteger)limit;

/// Fetches objects grouped by the specified keys.
/// @param groupKeys The keys to group by.
/// @return An array of dictionaries for the groups.
- (nonnull NSArray<NSDictionary *> *)objectsForGroupKeys:(nonnull NSArray<NSString *> *)groupKeys;

/// Retrieves data for a specific row.
/// @param rowID The ID of the row to fetch.
/// @return A dictionary containing the row data, or nil if not found.
- (nullable NSDictionary<NSString *, id> *)dataForRow:(NSUInteger)rowID;

#pragma mark - Enumerators

/// Returns an enumerator for all columns.
- (nonnull NSEnumerator<MADDataColumn *> *)columnsEnumerator;

/// Returns an enumerator for all objects in the table.
- (nonnull NSEnumerator *)objectEnumerator;

/// Returns an enumerator for all objects sorted by keys.
- (nonnull NSEnumerator *)enumeratorForKeyObjectsSorted;

/// Returns an enumerator for all objects sorted by rows.
- (nonnull NSEnumerator *)enumeratorForAllObjectsSorted;

/// Returns an enumerator for row IDs only.
- (nonnull NSEnumerator *)enumeratorForAllObjectsSortedRowIdOnly;

#pragma mark - Count and Metadata

/// Returns the total number of rows in the table.
- (NSUInteger)numberOfRows;

/// Returns the total number of columns in the table.
- (NSUInteger)numberOfColumns;

/// Returns the total number of objects in the table.
- (NSUInteger)count;

/// Generates a new filename for caching.
- (nonnull NSString *)newFilenameMDCache;

@end

#endif
