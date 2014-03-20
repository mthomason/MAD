//
//  MTQueryMySql.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryMySql.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate.h"


@implementation MTQueryMySql

- (NSString *)tableAliasConnector {
    return @" AS ";
}

- (NSString *)safeQueryField:(RptqQueryField *)queryField {
    return [MTQueryMySql safeQueryField:queryField];
}

+ (NSString *)safeQueryField:(RptqQueryField *)queryField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[queryField inQueryTable] queryAlias];
    NSString *fieldName = [[queryField databaseSchemaField] name];
    return [NSString stringWithFormat:@"`%@`.`%@`", queryTable, fieldName];
}

- (NSString *)safeQuerySchemaField:(RptqDatabaseSchemaField *)schemaField {
    // FIXME: Use backticks `` to make more robust.
    NSString *queryTable = [[schemaField inTable] name];
    NSString *fieldName = [schemaField name];
    return [NSString stringWithFormat:@"`%@`.`%@`", queryTable, fieldName];
}

- (NSString *)safeIdentifier:(NSString *)fieldOrTableName {
    // FIXME: Use backticks `` to make more robust.
    return [NSString stringWithFormat:@"`%@`", fieldOrTableName];
}

- (NSString *)selectPart {
    return @"SELECT\n";
}

- (NSString *)sqlLimitClause {
    return (YES) ? @"" : @"\nLIMIT 50";
}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion:(void (^)(BOOL success, NSError *error, id results))completion {
    
    @autoreleasepool {
        
        RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
        
        RptqQuery *rquery = [[database hasQueries] anyObject];
        NSError *__autoreleasing error = nil;
        NSString *sql = [self getSqlForQuery:rquery error:&error];
        
        if (error) {
            
            completion(NO, error, nil);

        } else {

            [[self database] executeSql:sql completion:^(BOOL success, NSError *error, id results) {
                completion(success, error, results);
            }];
            
        }
        
    }
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
                     @"LIMIT 100;",
                     safeField, MTSqlFrom, safeTable];
    return sql;
}

@end
