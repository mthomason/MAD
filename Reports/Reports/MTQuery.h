//
//  MTQuery.h
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTQuery_h
#define Reports_MTQuery_h

#import <Foundation/Foundation.h>

#pragma mark Types of queries

typedef NS_ENUM(NSUInteger, MTQueryType) {
	MTQueryTypeMaxFieldLength,
    MTQueryTypeCustomSql,
    MTQueryTypeFull,
    MTQueryTypeConnectionTest,
    MTQueryTypeSampleDataField,
    MTQueryTypeSampleDataTable,
    MTQueryTypeCacheAddColumn,
    MTQueryTypeCacheAddRow,
    MTQueryTypeCacheDeleteAllFromTable,
    MTQueryTypeCacheDropTable,
    MTQueryTypeCacheVacuum,
    MTQueryTypeCacheBeginTransaction,
    MTQueryTypeCacheEndTransaction,
    MTQueryTypeCacheSyncModeOff,
    MTQueryTypeCacheSyncModeDefault,
    MTQueryTypeCacheJournalModeOverride,
    MTQueryTypeCacheJournalModeDefault,
    MTQueryTypeCacheIndexCreateParameters,
    MTQueryTypeCacheIndexDropParameters,
    MTQueryTypeCacheSelectLimitOffset,
    MTQueryTypeCacheSelectRowId,
    MTQueryTypeCacheSelectRowIds,
    MTQueryTypeCacheSelectGroupKeys,
    MTQueryTypeCacheSelectItemsForGroupKeys,
    MTQueryTypeCacheAggregateFunction
};

#pragma mark Types of specific paramamters accepted for each query

typedef NS_ENUM(NSUInteger, MTQueryCacheAggregateFunctionParamaters) {
    MTQueryCacheAggregateFunctionParamatersTableName,
    MTQueryCacheAggregateFunctionParamatersGroupByType,
    MTQueryCacheAggregateFunctionParamatersRowids,
    MTQueryCacheAggregateFunctionParamatersAggregateFunctionType,
    MTQueryCacheAggregateFunctionParamatersFieldKey,
    MTQueryCacheAggregateFunctionParamatersWhere,
    MTQueryCacheAggregateFunctionParamatersFieldDescriptors,
    
};

typedef NS_ENUM(NSUInteger, MTQueryCacheSelectLimitOffsetParamaters) {
    MTQueryCacheSelectLimitOffsetParamatersLimit,
    MTQueryCacheSelectLimitOffsetParamatersOffset,
    MTQueryCacheSelectLimitOffsetParamatersTableNames,
    MTQueryCacheSelectLimitOffsetParamatersColumnKeys,
    MTQueryCacheSelectLimitOffsetParamatersSortDesc,
    MTQueryCacheSelectLimitOffsetParamatersWhere
};

typedef NS_ENUM(NSUInteger, MTQueryCacheFullParameters) {
	MTQueryCacheFullReportName,
    MTQueryCacheFullQuerySchema,
};

typedef NS_ENUM(NSUInteger, MTQueryCacheAddColumnParameters) {
	MTQueryCacheAddColumnDataColumn,
    MTQueryCacheAddColumnTableName,
    MTQueryCacheAddColumnUrl,
    MTQueryCacheAddColumnColumnName,
    MTQueryCacheAddColumnCreateTable,
    MTQueryCacheAddColumnUnique
};

typedef NS_ENUM(NSUInteger, MTQueryCacheAddRowParameters) {
	MTQueryCacheAddRowUrl,
    MTQueryCacheAddRowData,
    MTQueryCacheAddRowTableName,
    MTQueryCacheAddRowColumns,
    MTQueryCacheAddRowColumnKeys
};

typedef NS_ENUM(NSUInteger, MTQueryCacheIndexDropParameters) {
    MTQueryCacheIndexDropIndexName,
};

typedef NS_ENUM(NSUInteger, MTQueryCacheIndexCreateParameters) {
    MTQueryCacheIndexCreateIndexName,
    MTQueryCacheIndexCreateTableName,
    MTQueryCacheIndexCreateSortDescriptors
};

typedef NS_ENUM(NSUInteger, MTQueryCacheDeleteAllFromTableParameters) {
    MTQueryCacheDeleteAllFromTableConnection,
    MTQueryCacheDeleteAllFromTableTableName
};

typedef NS_ENUM(NSUInteger, MTQueryCacheDropTableParameters) {
    MTQueryCacheDropTableConnection,
    MTQueryCacheDropTableTableName
};

typedef NS_ENUM(NSUInteger, MTQueryCacheVacuumParameters) {
    MTQueryCacheVacuumConnection,
};

typedef NS_ENUM(NSUInteger, MTQueryCacheConnectionParameters) {
    MTQueryCacheConnection,
};

typedef NS_ENUM(NSUInteger, MTQuerySelectParameters) {
	MTQuerySelectConnection,
    MTQuerySelectTableName,
    MTQuerySelectFieldKeys,
    MTQuerySelectFieldDescriptors,
    MTQuerySelectLimit,
    MTQuerySelectOffset,
    MTQuerySelectSortDescriptors,
    MTQuerySelectPredicates,
    MTQuerySelectRowId,
    MTQuerySelectRowIds,
    MTQuerySelectSortAccending
};

extern NSString * const MTQueryKeyType;
extern NSString * const MTQueryKeyObject;

@class MTDatabase, MTDatabaseConnection, MTDataTable;

@interface MTQuery : NSObject

@property (nonatomic, strong, readwrite) MTDatabase *database;
@property (nonatomic, strong, readwrite) MTDataTable *datatable;
@property (nonatomic, strong) id queryObject;
@property (nonatomic, strong) NSMutableDictionary *fields;
@property (nonatomic, strong) NSMutableArray *fieldKeys;

@property (nonatomic, strong) NSMutableArray *binaryBindings; // Used by database to bind NSData to insert statements

- (id)initWithQueryType:(MTQueryType)type object:(id)object;

- (NSString *)getSqlWithError:(NSError **)error;
- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error;    //Only on MTQueryFull

- (void)performQuery:(void (^)(BOOL success, NSError *error))completion;
- (void)performQueryWithDatabase:(MTDatabase *)database completion:(void (^)(BOOL success, NSError *error))completion;

@property (nonatomic, strong) NSDictionary *columns;    //MTDataColumns by key

@end

@interface MTQuery (Private)    //Intended for use by MTQuery subclasses only


- (NSString *)whereClauseWithRowIds:(NSIndexSet *)rowids;
- (NSString *)whereClauseWithParameters:(NSArray *)whereClause;             //For "cache" sqltie3
- (NSString *)orderByClauseWithSortDescriptors:(NSArray *)sortDescriptors;  //For "cache" sqltie3
- (NSInteger)columnTypeForColumnHanle:(NSString *)columnHandle;             //For "cache" sqltie3

- (id)initWithObject:(id)object;
- (NSArray *)sortedHasQueryGroups;
- (NSArray *)sortDescriptors;
- (NSString *)fieldKeyForIndex:(NSUInteger)index;

- (BOOL)returnsResults;

- (BOOL)partOfTransactionSet;

@end

#endif
