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

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"

#import <MADFoundation/MTDataTable.h>
#import <MADFoundation/MADDataColumn.h>

#import "MTDatabaseDataBinding.h"

#import "MTDatabaseSqlite3.h"   //FIXME: Should only be included in Cache subset

#import <Foundation/NSNull.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

NSString * const MTQueryKeyType             = @"MTQueryKeyType";
NSString * const MTQueryKeyObject           = @"MTQueryKeyObject";
NSString * const MTQueryKeyPredicateColumn  = @"c";
NSString * const MTQueryKeyPredicateValue   = @"v";
NSString * const MADIdentifierROWID         = @"ROWID";

@interface MTQuery ()

@property (nonatomic, assign, readwrite) MTQueryType type;

@end

@implementation MTQuery

- (id)initWithQueryType:(MTQueryType)type object:(id)object {

    switch (type) {
            
        case MTQueryTypeCacheSelectRowIds:
            self = [[MTQueryCacheSelectRowIds alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheSelectItemsForGroupKeys:
            self = [[MTQuerySelectItemsForGroup alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheAggregateFunction:
            self = [[MTQueryCacheAggregateFunction alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheSelectGroupKeys:
            self = [[MTQueryCacheSelectGroupKeys alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheSelectRowId:
            self = [[MTQueryCacheSelectRowId alloc] initWithObject:object];
            break;

        case MTQueryTypeMaxFieldLength:
            self = [[MTQueryMaxFieldLength alloc] initWithObject:object];
            break;

        case MTQueryTypeCustomSql:
            self = [[MTQueryCustomNoResults alloc] initWithObject:object];
            break;
        
        case MTQueryTypeFull:
            self = [[MTQueryFull alloc] initWithObject:object];
            break;
        
        case MTQueryTypeConnectionTest:
            self = [[MTQueryTest alloc] initWithObject:object];
            break;
        
        case MTQueryTypeSampleDataField:
            self = [[MTQuerySampleDataField alloc] initWithObject:object];
            break;
        
        case MTQueryTypeSampleDataTable:
            self = [[MTQuerySampleDataTable alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheAddColumn:
            self = [[MTQueryCacheAddColumn alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheAddRow:
            self = [[MTQueryCacheAddRow alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheDropTable:
            self = [[MTQueryCacheDropTable alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheDeleteAllFromTable:
            self = [[MTQueryCacheDeleteAllFromTable alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheVacuum:
            self = [[MTQueryCacheVacuum alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheBeginTransaction:
            self = [[MTQueryCacheBeginTransaction alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheEndTransaction:
            self = [[MTQueryCacheEndTransaction alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheSyncModeOff:
            self = [[MTQueryCacheSyncOff alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheSyncModeDefault:
            self = [[MTQueryCacheSyncDefault alloc] initWithObject:object];
            break;
        
        case MTQueryTypeCacheJournalModeOverride:
            self = [[MTQueryCacheJournalModeOverride alloc] initWithObject:object];
            break;

        case MTQueryTypeCacheJournalModeDefault:
            self = [[MTQueryCacheJournalModeDefault alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheIndexCreateParameters:
            self = [[MTQueryCacheIndexCreate alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheIndexDropParameters:
            self = [[MTQueryCacheIndexDrop alloc] initWithObject:object];
            break;
            
        case MTQueryTypeCacheSelectLimitOffset:
            self = [[MTQueryCacheSelectLimitOffset alloc] initWithObject:object];
            break;
            
        default:
            NSAssert(false, @"Did you forget a constructor?");
            break;
    }
    if (self) {
        [self setType:type];
    }
    return self;
}

- (BOOL)returnsResults {
    return YES;
}

- (BOOL)partOfTransactionSet { return NO; }

- (id)initWithObject:(id)object {
    
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

- (bool)performQueryWithError:(NSError * __autoreleasing *)error {
    NSError * __autoreleasing qerror = NULL;
    bool success = [self.database executeQuery:self withError:&qerror];
    if (!success && error == NULL) {
        *error = qerror;
    }
    return success;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [self.fields removeAllObjects];
    [self.fieldKeys removeAllObjects];
    return @"";
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields managedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error {
    return @"";
}

- (NSString *)getSqlForAllFieldsInTable:(RptqDatabaseSchemaTable *)table {
    NSString *tableName = [table toString];
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
    if ([whereClause count] > 0) {
        NSUInteger counter = 0, counterBinings = 0;
        for (NSDictionary *condition in whereClause) {
            [sql appendString: (counter == 0) ? @" WHERE " : @" AND "];
            NSString *columnHandle = condition[@"c"];
            NSString *columnValue = condition[@"v"];
            
            
            MTDatabaseDataBinding *databinding;
            if ([[NSNull null] isEqual: columnValue]) {
                databinding = [[MTDatabaseDataBinding alloc] initWithDataType: MTDataTypeNull
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
    if ([sortDescriptors count] > 0) {
        NSUInteger sortCounter = 0;
        [sql appendString:@" ORDER BY "];
        
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            if (sortCounter != 0) [sql appendString:@", "];
            MADDataColumn *dataColumn = nil;
            if (self.columns) {
                dataColumn = self.columns[[sortDescriptor key]];
            }
            NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
            NSString *sortDirection = [MTDatabaseSqlite3 sortDescForColumnType: dataColumn.nativeType
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
    if ([rowids count] > 0) {
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

- (MTDataType)columnTypeForColumnHanle:(NSString *)columnHandle {
    MADDataColumn * __weak column = self.columns[columnHandle];
    return column.type;
}

+ (MADQueryDefinition *)newQueryDefinitionSelect:(NSArray *)columnKeys tableName:(NSString *)tableName sortDescriptors:(NSArray *)sortDescriptors {
    NSNumber *keyColumnKeys = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersColumnKeys];
    NSNumber *keyTableName = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersTableNames];
    NSNumber *keySortDescriptors = [[NSNumber alloc] initWithShort: MTQueryCacheSelectLimitOffsetParamatersSortDesc];
    id definition = [[MADQueryDefinition alloc] initWithObjectsAndKeys: columnKeys, keyColumnKeys,
                                                                tableName, keyTableName,
                                                                sortDescriptors, keySortDescriptors,
                                                                nil];
    return definition;
}

+ (MADQueryDefinition *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                 withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset
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
+ (MADQueryDefinition *)newQueryDefinitionSelect:(NSDictionary *)queryDefinationSelect
                                 withLimit:(NSUInteger)limit andOffset:(NSUInteger)offset {
    return [self newQueryDefinitionSelect:queryDefinationSelect withLimit:limit
                                andOffset:offset dropRowid:NO];
}

+ (MADQueryDefinition *)newQueryDefinitionCacheDeleteAllFromTable:(NSString *)table {
    NSNumber *tableNameKey = [[NSNumber alloc] initWithShort: MTQueryCacheDeleteAllFromTableTableName];
    id result = [[MADQueryDefinition alloc] initWithObjectsAndKeys:table, tableNameKey, nil];
    return result;
}

+ (NSDictionary *)newQueryDefinitionFull:(RptqQuery *)query {
    NSNumber *key = [[NSNumber alloc] initWithShort: MTQueryCacheFullQuerySchema];
    id result = [[MADQueryDefinition alloc] initWithObjectsAndKeys:query, key, nil];
    return result;
}

@end
