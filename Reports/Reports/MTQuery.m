//
//  MTQuery.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuery.h"
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

#import "MTQueryReportMySql.h"
#import "MTQueryReportSqlServer.h"
#import "MTQueryReportSqlite3.h"

@interface MTQuery ()

@property (nonatomic, strong, readwrite) MTDatabase *database;

@end

@implementation MTQuery

- (id)initWithObject:(id)object {
    self = [super init];
    if (self) {
        
        Class classRptqDatabase = [RptqDatabase class];
        if ([object isKindOfClass:classRptqDatabase]) {
            
            RptqUserCredentals *userCredentals = [(RptqDatabase *)object ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
            MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
            [self setDatabase:db];

        } else if ([object isKindOfClass:[RptqQuery class]]) {
            
            RptqUserCredentals *userCredentals = [[(RptqQuery *)object inDatabase] ownedByUser];
            MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
            MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
            [self setDatabase:db];
        }
        
    }
    return self;
}

+ (id)queryFactory:(id)object {
    id result = nil;

    Class classRptqQuery = [RptqQuery class];
    if ([object isKindOfClass:classRptqQuery]) {
        
        RptqQuery *rptqQuery = object;
        RptqDatabase *database = [rptqQuery inDatabase];
        RptqUserCredentals *userCredentals = [database ownedByUser];
        
        if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseConnectionMySql identifier]]) {
            
            result = [[MTQueryReportMySql alloc] initWithObject:rptqQuery];
            
        } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseConnectionSqlServer identifier]]) {
            
            result = [[MTQueryReportSqlServer alloc] initWithObject:rptqQuery];
            
        } else if ([[userCredentals database_driver_type] isEqualToString:[MTDatabaseConnectionSqlite3 identifier]]) {
            
            result = [[MTQueryReportSqlite3 alloc] initWithObject:rptqQuery];
            
        }

    }
    return result;
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTQuery safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"%@.%@", queryTable, fieldName];
}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(BOOL success, NSError *error, id results))completion {
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

- (NSString *)tableAliasConnector {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
}

- (NSString *)safeIdentifier:(NSString *)s {
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

- (NSString *)selectPart {
    return @"SELECT\n";
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

@end
