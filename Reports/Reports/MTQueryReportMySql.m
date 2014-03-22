//
//  MTQueryMySql.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MTQueryReportMySql.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate.h"


@implementation MTQueryReportMySql

- (NSString *)sqlLimitClause {
    return (YES) ? @"" : @"\nLIMIT 50";
}

- (void)cacheReportQueryForDocument:(RptqDocument *)document
                         completion:(void (^)(BOOL success, NSError *error, id results))completion {
    
    @autoreleasepool {
        
        NSError *__autoreleasing error = nil;
        NSString *sql = [self getSqlWithError:&error];
        
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
    NSString *safeField = [[self database] safeQuerySchemaField:schemaField];
    NSString *safeTable = [[self database] safeIdentifier:schemaField.inTable.name];
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                     @"%@ %@ "
                     @"LIMIT 100;",
                     safeField, MTSqlFrom, safeTable];
    return sql;
}

@end
