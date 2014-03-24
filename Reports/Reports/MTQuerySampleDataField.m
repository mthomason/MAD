//
//  MTQuerySampleDataField.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuerySampleDataField.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "MTDatabase.h"
#import "Constants.h"

@interface MTQuerySampleDataField ()

@end

@implementation MTQuerySampleDataField

- (NSString *)getSqlWithError:(NSError **)error {
    RptqDatabaseSchemaField *field = [self queryObject];
    NSString *safeField = [[self database] safeQuerySchemaField:field];
    NSString *safeTable = [[self database] safeIdentifier:field.inTable.name];
    NSString *sql = [NSString stringWithFormat:@"SELECT DISTINCT %@ "
                     @"%@ %@ "
                     @"LIMIT 100;",
                     safeField, MTSqlFrom, safeTable];
    return sql;
}

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        Class classRptqQuery = [RptqDatabaseSchemaField class];
        if ([object isKindOfClass:classRptqQuery]) {
            [self setQueryObject:object];
        }
    }
    return self;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {

    NSError *error = nil;
    NSString *sql = [self getSqlWithError:&error];

    if (error) {
        completion(NO, error, nil);
    } else {
        [[self database] executeSql:sql
                         completion:^(BOOL success, NSError *error, id results) {
                             completion(success, error, results);
                         }];
    }
    
}

@end
