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
#import "MTQuerySampleDataField.h"
#import "MTQuerySampleDataTable.h"
#import "MTQueryReport.h"
#import "MTQueryReportMySql.h"
#import "MTQueryReportSqlServer.h"
#import "MTQueryReportSqlite3.h"

#import "MTCache.h"
#import "MTDatabase.h"
#import "MTDatabaseField.h"

#import "MTGraph.h"

#import "RptqDatabaseSchemaTable.h"
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

@interface MTQuery ()

@property (nonatomic, strong, readwrite) MTDatabase *database;

@end

@implementation MTQuery

- (id)initWithObject:(id)object {
    self = [super init];
    if (self) {
        
        if ([object isKindOfClass:[RptqDatabase class]]) {
            
            MTCache *cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            [self setCache:cache];
            RptqUserCredentals *userCredentals = [(RptqDatabase *)object ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
            MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
            [self setDatabase:db];

        } else if ([object isKindOfClass:[RptqQuery class]]) {
            
            MTCache *cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            [self setCache:cache];
            RptqUserCredentals *userCredentals = [[(RptqQuery *)object inDatabase] ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
            MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
            [self setDatabase:db];

        } else if ([object isKindOfClass:[RptqDatabaseSchemaTable class]]) {
            
            MTCache *cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            [self setCache:cache];
            RptqUserCredentals *userCredentals = [[(RptqDatabaseSchemaTable *)object inDatabase] ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
            MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
            [self setDatabase:db];
            
        } else if ([object isKindOfClass:[RptqDatabaseSchemaField class]]) {

            MTCache *cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            [self setCache:cache];
            RptqUserCredentals *userCredentals = [[[(RptqDatabaseSchemaField *)object inTable] inDatabase] ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
            MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
            [self setDatabase:db];

        }
        
    }
    return self;
}

+ (id)queryFactory:(id)object {
    id result = nil;

    if ([object isKindOfClass:[RptqQuery class]]) {
        
        RptqDatabase *database = [(RptqQuery *)object inDatabase];
        RptqUserCredentals *userCredentals = [database ownedByUser];
        
        if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseConnectionMySql identifier]]) {
            
            result = [[MTQueryReportMySql alloc] initWithObject:object];
            
        } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseConnectionSqlServer identifier]]) {
            
            result = [[MTQueryReportSqlServer alloc] initWithObject:object];
            
        } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseConnectionSqlite3 identifier]]) {
            
            result = [[MTQueryReportSqlite3 alloc] initWithObject:object];
            
        }

    } else if ([object isKindOfClass:[RptqDatabaseSchemaTable class]]) {
        
        result = [[MTQuerySampleDataTable alloc] initWithObject:object];
        
    } else if ([object isKindOfClass:[RptqDatabaseSchemaField class]]) {
        
        result = [[MTQuerySampleDataField alloc] initWithObject:object];
        
    }
    return result;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)getSqlWithError:(NSError **)error {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)getSqlForAllFieldsInTable:(RptqDatabaseSchemaTable *)table {
    NSString *tableName = [table toString];
    return [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
}

- (NSString *)sqlLimitClause {
    return @"";
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

@end
