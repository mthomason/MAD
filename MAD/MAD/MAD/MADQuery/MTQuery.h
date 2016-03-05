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
#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MADDataProtocol.h>

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
    MTQueryCacheAggregateFunctionParamatersPredicates,
    MTQueryCacheAggregateFunctionParamatersFieldDescriptors,
    
};

typedef NS_ENUM(NSUInteger, MTQueryCacheSelectLimitOffsetParamaters) {
    MTQueryCacheSelectLimitOffsetParamatersLimit,
    MTQueryCacheSelectLimitOffsetParamatersOffset,
    MTQueryCacheSelectLimitOffsetParamatersTableNames,
    MTQueryCacheSelectLimitOffsetParamatersColumnKeys,
    MTQueryCacheSelectLimitOffsetParamatersColumns,
    MTQueryCacheSelectLimitOffsetParamatersSortDesc,
    MTQueryCacheSelectLimitOffsetParamatersWhere,
    MTQueryCacheSelectLimitOffsetParamatersDropRowid
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
    MTQueryCacheIndexCreateSortDescriptors,
    MTQueryCacheIndexCreateColumns,
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
    MTQuerySelectSortAccending,
    MTQuerySelectColumns
};

extern NSString * const _Nonnull MTQueryKeyType;
extern NSString * const _Nonnull MTQueryKeyObject;

extern NSString * const _Nonnull MTQueryKeyPredicateColumn;
extern NSString * const _Nonnull MTQueryKeyPredicateValue;
extern NSString * const _Nonnull MADIdentifierROWID;

@class MTDatabase, MTDataTable, RptqQuery;

@interface MTQuery : NSObject

@property (nonatomic, weak) id <MADDataProtocol> dataDelegate;

@property (nonatomic, strong, readwrite, nullable) MTDatabase *database;

@property (nonatomic, strong, nullable) id queryObject;
@property (nonatomic, strong, nullable) NSMutableDictionary *fields;
@property (nonatomic, strong, nullable) NSMutableArray *fieldKeys;

@property (nonatomic, assign, readonly) MTQueryType type;

@property (nonatomic, strong, nullable) NSMutableArray *binaryBindings; // Used by database to bind NSData to insert statements

- (id _Null_unspecified)initWithQueryType:(MTQueryType)type object:(id _Null_unspecified)object;

- (NSString * _Nullable)getSqlWithError:(NSError * _Nullable * _Nullable)error;
- (NSString * _Nullable)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError * _Nullable * _Nullable)error;    //Only on MTQueryFull

- (void)performQuery:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;
- (void)performQueryWithDatabase:(MTDatabase * _Null_unspecified)database completion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completion;

@property (nonatomic, strong) NSDictionary * _Null_unspecified columns;    //MTDataColumns by key

@end

@interface MTQuery (Private)    //Intended for use by MTQuery subclasses only

- (NSString * _Nonnull)whereClauseWithRowIds:(NSArray * _Nullable)rowids;
- (NSString * _Nonnull)whereClauseWithParameters:(NSArray * _Nullable)whereClause;             //For "cache" sqltie3
- (NSString * _Nonnull)orderByClauseWithSortDescriptors:(NSArray * _Nullable)sortDescriptors;  //For "cache" sqltie3
- (NSUInteger)columnTypeForColumnHanle:(NSString * _Nonnull)columnHandle;            //For "cache" sqltie3

- (instancetype _Nonnull)initWithObject:(id _Null_unspecified)object;
- (NSString * _Nullable)fieldKeyForIndex:(NSUInteger)index;

- (BOOL)returnsResults;

- (BOOL)partOfTransactionSet;

+ (NSDictionary * _Nonnull)queryDefinitionFull:(RptqQuery * _Null_unspecified)query;
+ (NSDictionary * _Nonnull)queryDefinitionSelect:(NSDictionary * _Null_unspecified)queryDefinationSelect withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset dropRowid:(BOOL)droprowid;
+ (NSDictionary * _Nonnull)queryDefinitionSelect:(NSArray * _Null_unspecified)columnKeys tableName:(NSString * _Null_unspecified)tableName sortDescriptors:(NSArray * _Null_unspecified)sortDescriptors;
+ (NSDictionary * _Nonnull)queryDefinitionSelect:(NSDictionary * _Null_unspecified)queryDefinationSelect withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset;
+ (NSDictionary * _Nonnull)queryDefinitionCacheDeleteAllFromTable:(NSString * _Null_unspecified)table;

@end

#endif
