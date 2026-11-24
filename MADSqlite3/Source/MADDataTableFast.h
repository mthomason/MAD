//
//  MADDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDataTableFast_h
#define Reports_MADDataTableFast_h

#import <MADFoundation/MADDataTable.h>
#import <MADAPI/MADAliases.h>

@protocol MADCacheProtocol, MADDataProtocol, MADQueryDataBindingProtocol;
@class MADQuery, MADDatabaseSqlite3;

NS_ASSUME_NONNULL_BEGIN

@interface MADDataTableFast : MADDataTable <NSCoding, NSFastEnumeration>

/// The selects connection.  A table built without a cache directory or a cache
/// delegate has none -- `nil` -- and only its in-memory surface is usable.
@property (nonatomic, strong, readonly, nullable) MADDatabaseSqlite3 *databaseForSelects;

@property (nonatomic, weak) IBOutlet id <MADCacheProtocol> cacheDelegate;
@property (nonatomic, weak) IBOutlet id <MADDataProtocol> dataDelegate;

/// The generation token used for the row file's name (`<identifier>.maddb`).  The
/// table keeps its `tag`, and so its `t<tag>` name, which lets a staged generation
/// be written beside the live one and published by swapping the column map.  Set
/// it before the table first opens a connection.
@property (nonatomic, copy, nullable) NSString *cacheFileIdentifier;

/// The row database file this table reads and writes.
@property (nonatomic, strong, readonly, nullable) NSURL *rowDatabaseURL;

/// The cache file lives in this directory.  Pass one when no cache delegate is
/// available -- in a test, say -- and the table resolves its cache URL from it
/// instead of reaching for the application delegate.  `nil` keeps the existing
/// behaviour: the cache delegate's directory, or the app's local cache directory.
- (instancetype)initWithId:(NSUInteger)objectId cacheDirectory:(nullable NSURL *)cacheDirectory;

- (NSString *)tableName;
- (nullable NSString *)columnKeyForColumnName:(NSString *)columnName;
- (NSArray <NSDictionary <NSString *, MADResult *> *> *)whereClauseForGroupKeys:(NSArray <MADResult *> *)groupKeys;

/// The first column's value for the query's first row, or nil when the query yields
/// no row (or cannot run).
- (nullable __kindof NSObject <NSCopying, NSSecureCoding> *)runSelectQuery:(MADQuery <MADQueryDataBindingProtocol> *)query;

/// The cell's row, or nil with `error` set when the column is unknown or the read
/// fails -- the same nil-on-failure shape as the base `-dataForRow:error:`.
- (nullable NSDictionary *)dataForRow:(NSUInteger)cacheId
							   column:(NSString *)columnIdentifier
								error:(NSError * __autoreleasing *)error;

/// Overrides MADDataTableCursoring.  A table with no columns has nothing to walk, so
/// this subclass answers nil where the protocol's declaration promises an enumerator.
- (nullable NSEnumerator *)objectEnumerator;

/// A page draw wraps its cell reads in one read transaction on the selects
/// connection so that each -dataForRow:column:error: call does not pay
/// autocommit's journal begin/commit on its own.  The renderer's draw loop
/// balances the pair; these never touch the inserts (writer) connection.
- (void)beginReadTransaction;
- (void)commitReadTransaction;

/// Finalize prepared statements and close both SQLite connections (the inserts
/// writer and the selects reader), so the row file and column map can be removed
/// immediately.  Windows cannot delete a file while a handle to it is open, and
/// the reader otherwise stays open for the table's whole lifetime.  Idempotent.
- (void)closeConnections;

@end

NS_ASSUME_NONNULL_END

#endif
