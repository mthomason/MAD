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

#import "MTDatabase.h"
#import "MTDatabaseField.h"

#import "MTGraph.h"

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

#import "NSError+UserInterface.h"

#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"

#import "RptqDatabase.h"
#import "RptqUserCredentals.h"

#import "MTDataTable.h"

NSString * const MTQueryKeyType = @"MTQueryKeyType";
NSString * const MTQueryKeyObject = @"MTQueryKeyObject";

@interface MTQuery ()

@end

@implementation MTQuery

- (id)initWithQueryType:(MTQueryType)type object:(id)object {

    switch (type) {
        
        case MTQueryTypeCacheSelectItemsForGroupKeys:
            self = [[MTQuerySelectItemsForGroup alloc] initWithObject:object];
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
    
    return self;
}

- (BOOL)returnsResults {
    return YES;
}

- (BOOL)partOfTransactionSet {
    return NO;
}

- (id)initWithObject:(id)object {
    
    self = [super init];
    if (self) {
        
        NSMutableArray *binaryBindings = [[NSMutableArray alloc] init];
        [self setBinaryBindings:binaryBindings];

        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];

        [self setFields:fieldInfo];
        [self setFieldKeys:fieldKeys];

    }
    return self;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error))completion {
    @autoreleasepool {
        [[self database] executeQuery:self completion:^(BOOL success, NSError *error) {
            [[self datatable] cache];
            completion(success, error);
        }];
    }
}

- (void)performQueryWithDatabase:(MTDatabase *)database completion:(void (^)(BOOL success, NSError *error))completion {
    [self setDatabase:database];
    @autoreleasepool {
        [[self database] executeQuery:self completion:^(BOOL success, NSError *error) {
            [[self datatable] cache];
            completion(success, error);
        }];
    }
}

- (NSString *)getSqlWithError:(NSError **)error {
    [[self fields] removeAllObjects];
    [[self fieldKeys] removeAllObjects];
    return @"";
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error {
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

- (NSArray *)sortedHasQueryGroups {
    return [NSArray array];
}

- (NSArray *)sortDescriptors {
    return [NSArray array];
}

- (NSString *)fieldKeyForIndex:(NSUInteger)index {
    return (index < [[self fieldKeys] count]) ? [[self fieldKeys] objectAtIndex:index] : nil;
}

@end
