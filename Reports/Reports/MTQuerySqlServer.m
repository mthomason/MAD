//
//  MTQuerySqlServer.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuerySqlServer.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

NSString * const MTSqlSelectTop100 = @"SELECT DISTINCT TOP 100";

@implementation MTQuerySqlServer

- (NSString *)tableAliasConnector {
    return @" AS ";
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"[%@].[%@]", queryTable, fieldName];
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTQuerySqlServer safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"[%@].[%@]", queryTable, fieldName];
}

- (NSString *) safeIdentifier:(NSString *)fieldOrTableName {
    return [NSString stringWithFormat:@"[%@]", fieldOrTableName];
}

- (NSString *)selectPart {
    return (YES) ? @"SELECT\n" : @"SELECT TOP 50\n";
}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion: (void (^)(BOOL success, NSError *error, id results))completion {
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *rquery = [[database hasQueries] anyObject];
    NSString *queryString = [self getSqlForQuery:rquery];
    
    [[self database] executeSql:queryString
                     completion:^(BOOL success, NSError *error, id results) {
                         // FIXME: Return something.
                         completion(success, error, results);
                     }];
    
    
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    
    NSString *sql = [self sqlSampleDataForField:schemaField];
    
    [[self database] executeSql:sql
                     completion:^(BOOL success, NSError *error, id results) {
                         completion(success, error, results);
                     }];
}

- (NSString *)sqlSampleDataForField:(RptqDatabaseSchemaField *)schemaField {
    NSString *safeField = [self safeQuerySchemaField:schemaField];
    NSString *safeTable = [self safeIdentifier:schemaField.inTable.name];
    NSString *sql = [NSString stringWithFormat:@"%@ %@ "
                     @"%@"
                     @" %@ ORDER BY %@;",
                     MTSqlSelectTop100, safeField, MTSqlFrom, safeTable, safeField];

    return sql;
}

@end
