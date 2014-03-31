//
//  MTQuerySqlite3.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryReportSqlite3.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "MTDatabase.h"
#import "MTCache.h"

@implementation MTQueryReportSqlite3

- (void)performQuery: (void (^)(BOOL success, NSError *error, id results))completion {

    NSError *__autoreleasing error = nil;
    NSString *sql = [self getSqlWithError:&error];
    
    if (error) {
        
        completion(NO, error, nil);
        
    } else {
        [[self database] executeSql:sql completion:^(BOOL success, NSError *error, id results) {
            [[self cache] cacheData:results];
            completion(success, error, results);
        }];
    }
}

- (void)sampleDataForSchemaField:(RptqDatabaseSchemaField *)schemaField
                      completion: (void (^)(BOOL success, NSError *error, NSArray *resultStrings))completion {
    
    NSString *sql = [self sqlSampleDataForField:schemaField];
    
    [[self database] executeSql:sql
                     completion:^(BOOL success, NSError *error, id results) {
                         [[self cache] cacheData:results];
                         completion(success, error, results);
                     }];
}

- (NSString *)sqlSampleDataForField:(RptqDatabaseSchemaField *)schemaField {
    NSString *safeField = [[self database] safeQuerySchemaField:schemaField];
    NSString *safeTable = [[self database] safeIdentifier:schemaField.inTable.name];
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                     @"%@ %@ "
                     @"LIMIT 255;",
                     safeField, MTSqlFrom, safeTable];
    return sql;
}

- (NSString *)sqlLimitClause {
    return (YES) ? @"" : @"\nLIMIT 50";
}


@end
