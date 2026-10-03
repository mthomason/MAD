//
//  MADDataTableFast.h
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright © 2025 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADDataTableFast_h
#define Reports_MADDataTableFast_h

#import <MADFoundation/MADDataTable.h>
#import <MADAPI/MADAliases.h>

@protocol MADCacheProtocol, MADDataProtocol, MADQueryDataBindingProtocol;
@class MADQuery, MADDatabaseSqlite3;

NS_ASSUME_NONNULL_BEGIN

@interface MADDataTableFast : MADDataTable <NSCoding, NSFastEnumeration>

@property (nonatomic, strong, readonly) MADDatabaseSqlite3 *databaseForSelects;

@property (nonatomic, weak) IBOutlet id <MADCacheProtocol> cacheDelegate;
@property (nonatomic, weak) IBOutlet id <MADDataProtocol> dataDelegate;

/// The cache file lives in this directory.  Pass one when no cache delegate is
/// available -- in a test, say -- and the table resolves its cache URL from it
/// instead of reaching for the application delegate.  `nil` keeps the existing
/// behaviour: the cache delegate's directory, or the app's local cache directory.
- (instancetype)initWithId:(NSUInteger)objectId cacheDirectory:(nullable NSURL *)cacheDirectory;

- (NSString *)tableName;
- (nullable NSString *)columnKeyForColumnName:(NSString *)columnName;
- (NSArray <NSDictionary <NSString *, MADResult *> *> *)whereClauseForGroupKeys:(NSArray <MADResult *> *)groupKeys;

- (__kindof NSObject <NSCopying, NSSecureCoding> *)runSelectQuery:(MADQuery <MADQueryDataBindingProtocol> *)query;

- (NSDictionary *)dataForRow:(NSUInteger)cacheId
					  column:(NSString *)columnIdentifier
					   error:(NSError * __autoreleasing *)error;

/// A page draw wraps its cell reads in one read transaction on the selects
/// connection so that each -dataForRow:column:error: call does not pay
/// autocommit's journal begin/commit on its own.  The renderer's draw loop
/// balances the pair; these never touch the inserts (writer) connection.
- (void)beginReadTransaction;
- (void)commitReadTransaction;

@end

NS_ASSUME_NONNULL_END

#endif
