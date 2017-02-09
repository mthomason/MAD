//
//  MTQuery.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuery.h"

#import <Foundation/NSNull.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSError.h>

#import <MADQueryCacheSelectLimitOffsetParamaters.h>

#import <MADFoundation/MADDataColumn.h>

#import "MTQueryCacheSelectRowId.h"
#import "MTQuerySampleDataField.h"
#import "MTQuerySampleDataTable.h"
#import "MTQueryFull.h"
#import "MTQueryMaxFieldLength.h"
#import "MTQueryTest.h"
#import "MTQueryCustomNoResults.h"
#import "MTQueryCacheDropTable.h"
#import "MTQueryCacheAddColumn.h"
#import "MTQueryCacheAddRow.h"
#import "MTQueryCacheDeleteAllFromTable.h"
#import "MTQueryCacheVacuum.h"
#import "MTQueryCacheBeginTransaction.h"
#import "MTQueryCacheEndTransaction.h"
#import "MTQueryCacheSyncDefault.h"
#import "MTQueryCacheSyncOff.h"
#import "MTQueryCacheJournalModeDefault.h"
#import "MTQueryCacheJournalModeOverride.h"
#import "MTQueryCacheIndexCreate.h"
#import "MTQueryCacheIndexDrop.h"
#import "MTQueryCacheSelectLimitOffset.h"
#import "MTQueryCacheSelectGroupKeys.h"
#import "MTQuerySelectItemsForGroup.h"
#import "MTQueryCacheSelectRowIds.h"
#import "MTQueryCacheAggregateFunction.h"

#import "MADQueryCacheDeleteAllFromTableParameters.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "MTDatabaseDataBinding.h"

#import "MTDatabaseSqlite3.h"   //FIXME: Should only be included in Cache subset

#import "MADQueryCacheFullParameters.h"

NSString * const MTQueryKeyPredicateColumn  = @"c";
NSString * const MTQueryKeyPredicateValue   = @"v";
NSString * const MADIdentifierROWID         = @"ROWID";

@interface MTQuery ()

@property (nonatomic, assign, readwrite) MADQueryType type;

@end

@implementation MTQuery

- (void)dealloc {
    _dataDelegate = nil;
}

- (instancetype)initWithQueryType:(MADQueryType)type object:(id)parameters {
    id query;
    
    switch (type) {
            
        case MADQueryTypeCacheSelectRowIds:
            query = [[MTQueryCacheSelectRowIds alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSelectItemsForGroupKeys:
            query = [[MADQuerySelectItemsForGroup alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheAggregateFunction:
            query = [[MTQueryCacheAggregateFunction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSelectGroupKeys:
            query = [[MTQueryCacheSelectGroupKeys alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSelectRowId:
            query = [[MTQueryCacheSelectRowId alloc] initWithObject:parameters];
            break;

        case MADQueryTypeMaxFieldLength:
            query = [[MTQueryMaxFieldLength alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCustomSql:
            query = [[MTQueryCustomNoResults alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeFull:
            query = [[MTQueryFull alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeConnectionTest:
            query = [[MTQueryTest alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeSampleDataField:
            query = [[MTQuerySampleDataField alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeSampleDataTable:
            query = [[MTQuerySampleDataTable alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheAddColumn:
            query = [[MTQueryCacheAddColumn alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheAddRow:
            query = [[MTQueryCacheAddRow alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheDropTable:
            query = [[MTQueryCacheDropTable alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheDeleteAllFromTable:
            query = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheVacuum:
            query = [[MTQueryCacheVacuum alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheBeginTransaction:
            query = [[MTQueryCacheBeginTransaction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheEndTransaction:
            query = [[MTQueryCacheEndTransaction alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSyncModeOff:
            query = [[MTQueryCacheSyncOff alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheSyncModeDefault:
            query = [[MTQueryCacheSyncDefault alloc] initWithObject:parameters];
            break;
        
        case MADQueryTypeCacheJournalModeOverride:
            query = [[MTQueryCacheJournalModeOverride alloc] initWithObject:parameters];
            break;

        case MADQueryTypeCacheJournalModeDefault:
            query = [[MTQueryCacheJournalModeDefault alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheIndexCreateParameters:
            query = [[MTQueryCacheIndexCreate alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheIndexDropParameters:
            query = [[MTQueryCacheIndexDrop alloc] initWithObject:parameters];
            break;
            
        case MADQueryTypeCacheSelectLimitOffset:
            query = [[MTQueryCacheSelectLimitOffset alloc] initWithObject:parameters];
            break;
            
        default:
            NSAssert(NO, @"Did you forget a constructor?");
            break;
    }
    return query;
}

- (void)update {

}

- (BOOL)returnsResults {
    return YES;
}

- (BOOL)partOfTransactionSet { return NO; }

- (instancetype)initWithObject:(id)object {
    
    if (self = [super init]) {
        
        NSMutableArray *binaryBindings = [[NSMutableArray alloc] init];
        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];

        self.binaryBindings = binaryBindings;
        self.fields = fieldInfo;
        self.fieldKeys = fieldKeys;

    }
    return self;
}

- (BOOL)performQueryWithError:(NSError * __autoreleasing *)error {
    NSError * __autoreleasing * qerror = NULL;
    BOOL success = [self.database executeQuery:self withError:qerror];
    if (!success && qerror != NULL && error != NULL) {
        error = qerror;
    }
    NSAssert(qerror == NULL, @"Error: %@", (*error).localizedDescription);
    return success;
}

- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    [self.fields removeAllObjects];
    [self.fieldKeys removeAllObjects];
    return @"";
}

- (NSString *)getSqlForAllFieldsInTable:(RptqDatabaseSchemaTable *)table {
    NSString *tableName = table.toString;
    return [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
}

- (NSString *)sqlGroupByExpressionWithQuery:(RptqQuery *)query {
    //Group is done on the reporting client side, so we do not add group by information here.
    return @"";
}

- (NSString *)fieldKeyForIndex:(NSUInteger)index {
    return (index < self.fieldKeys.count) ? self.fieldKeys[index] : nil;
}

- (NSMutableDictionary *)fields {
    return _fields == nil ? _fields = [NSMutableDictionary new] : _fields;
}
- (NSMutableArray *)fieldKeys {
    return _fieldKeys == nil ? _fieldKeys = [NSMutableArray new] : _fieldKeys;
}

#pragma mark - Helper functions for the query cache
// FIXME: These are not yet useable for anything but Sqlite3.

- (NSString *)whereClauseWithParameters:(NSArray *)whereClause {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    if (whereClause.count > 0) {
        NSUInteger counter = 0, counterBinings = 0;
        for (NSDictionary *condition in whereClause) {
            [sql appendString: (counter == 0) ? @" WHERE " : @" AND "];
            NSString *columnHandle = condition[@"c"];
            NSString *columnValue = condition[@"v"];
            
            
            MTDatabaseDataBinding *databinding;
            if ([[NSNull null] isEqual: columnValue]) {
                databinding = [[MTDatabaseDataBinding alloc] initWithDataType: MADDataTypeNull
                                                                   fieldIndex: counterBinings
                                                                        value: columnValue];
            } else {
                databinding = [[MTDatabaseDataBinding alloc] initWithDataType: [self columnTypeForColumnHanle:columnHandle]
                                                                   fieldIndex: counterBinings
                                                                        value: columnValue];
            }
            [self.binaryBindings addObject:databinding];
            [sql appendFormat:@"%@ = ?", columnHandle];
            counterBinings++;
            counter++;
        }
    }
    return sql;
}

- (NSString *)orderByClauseWithSortDescriptors:(NSArray *)sortDescriptors {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    if (sortDescriptors.count > 0) {
        NSUInteger sortCounter = 0;
        [sql appendString:@" ORDER BY "];
        
        NSString *key;
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            if (sortCounter != 0) [sql appendString:@", "];
            MADDataColumn *dataColumn = nil;
            if (self.columns) {
                if ((key = sortDescriptor.key)) {
                    dataColumn = self.columns[key];
                }
            }
            NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
            MADSqlite3SortDescription *sortDirection;
            sortDirection = [MTDatabaseSqlite3 newSqlite3SortDescriptionForColumnType: dataColumn.nativeType
                                                                            ascending: sortDescriptor.ascending];
            [sql appendFormat:@"%@ %@", sortDescriptor.key, sortDirection];
            sortCounter++;
        }
    }
    return sql;
}

- (NSString *)whereClauseWithRowIds:(NSArray *)rowids {
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    BOOL firstTime = YES;
    if (rowids.count > 0) {
        for (NSNumber *rowido in rowids) {
            [sql appendString: firstTime == NO ? @" OR " : @" WHERE "];
            [sql appendFormat:@"rowid = %lu", (unsigned long)rowido.unsignedIntegerValue];
            firstTime = NO;
        }
    } else {
        [sql setString:@" WHERE rowid = -1 "];
    }
    return sql;
}

- (MADDataType)columnTypeForColumnHanle:(NSString *)columnHandle {
    MADDataColumn * __weak column = self.columns[columnHandle];
    return column.type;
}

+ (NSDictionary *)newQueryDefinitionSelect: (NSArray *)columnKeys
                                 tableName: (NSString *)tableName
                           sortDescriptors: (NSArray *)sortDescriptors {

    NSNumber *keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumnKeys];
    NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersTableNames];
    NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersSortDesc];

    NSDictionary *definition;
    definition = [[NSDictionary alloc] initWithObjectsAndKeys: columnKeys, keyColumnKeys,
                                                               tableName, keyTableName,
                                                               sortDescriptors, keySortDescriptors,
                                                               nil];
    return definition;
}

+ (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                 withLimit:(NSUInteger)limit
                                 andOffset:(NSUInteger)offset
                                 dropRowid:(BOOL)droprowid {
    
    NSMutableDictionary *queryDefination = [[NSMutableDictionary alloc] initWithDictionary:queryDefinationSelect];
    NSNumber *limitw = [[NSNumber alloc] initWithUnsignedInteger: limit];
    NSNumber *offsetw = [[NSNumber alloc] initWithUnsignedInteger: offset];
    NSNumber *keyLimit = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersLimit];
    NSNumber *keyOffset = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersOffset];
    queryDefination[keyLimit] = limitw;
    queryDefination[keyOffset] = offsetw;
    if (droprowid) {
        NSNumber *keyDropRow = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersDropRowid];
        NSNumber *dropRowidObj = @YES;
        queryDefination[keyDropRow] = dropRowidObj;
    }
    return  queryDefination;

}
+ (NSDictionary *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                 withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset {
    return [self newQueryDefinitionSelect:queryDefinationSelect withLimit:limit
                                andOffset:offset dropRowid:NO];
}

+ (NSDictionary *)newQueryDefinitionCacheDeleteAllFromTable:(NSString *)table {
    NSNumber *tableNameKey = [[NSNumber alloc] initWithShort: MTQueryCacheDeleteAllFromTableTableName];
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:table, tableNameKey, nil];
    return result;
}

+ (NSDictionary *)newQueryDefinitionFull:(RptqQuery *)query {
    NSNumber *key = [[NSNumber alloc] initWithShort: MTQueryCacheFullQuerySchema];
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:query, key, nil];
    return result;
}

@end
