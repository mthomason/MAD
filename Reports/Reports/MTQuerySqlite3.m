//
//  MTQuerySqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQuerySqlite3.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "MTDatabase.h"

@implementation MTQuerySqlite3

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
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                     @"%@ %@ "
                     @"LIMIT 255;",
                     safeField, MTSqlFrom, safeTable];
    return sql;
}

- (NSString *)tableAliasConnector {
    return @" ";
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTQuerySqlite3 safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"\"%@\".\"%@\"", queryTable, fieldName];
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    // FIXME: Use backticks `` to make more robust.
    return [NSString stringWithFormat:@"\"%@\"", fieldOrTableName];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"\"%@\".\"%@\"", queryTable, fieldName];
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (NSString *)sqlLimitClause {
    return (YES) ? @"" : @"\nLIMIT 50";
}


@end
