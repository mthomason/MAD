//
//  MTQuerySqlServer.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MTQueryReportSqlServer.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

NSString * const MTSqlSelectTop100 = @"SELECT DISTINCT TOP 100";

@implementation MTQueryReportSqlServer

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {
    
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
    NSString *sql = [NSString stringWithFormat:@"%@ %@ "
                     @"%@"
                     @" %@ ORDER BY %@;",
                     MTSqlSelectTop100, safeField, MTSqlFrom, safeTable, safeField];

    return sql;
}

@end
