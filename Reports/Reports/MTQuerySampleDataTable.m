//
//  MTQuerySampleDataTable.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MTQuerySampleDataTable.h"
#import "MTDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

@interface MTQuerySampleDataTable ()

@property (nonatomic, strong) RptqDatabaseSchemaTable *table;

@end

@implementation MTQuerySampleDataTable

- (NSString *)getSqlWithError:(NSError **)error {
    NSString *tableName = [[self database] safeIdentifier: [[self table] toString]];
    return [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
}

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        Class classRptqQuery = [RptqDatabaseSchemaTable class];
        if ([object isKindOfClass:classRptqQuery]) {
            [self setTable:object];
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
