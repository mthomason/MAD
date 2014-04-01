//
//  MTQueryMaxFieldLength.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryMaxFieldLength.h"
#import "MTDatabase.h"
#import "MTDatabaseField.h"
#import "MTCache.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

@implementation MTQueryMaxFieldLength

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    
    NSString *sql = nil;
    NSArray *fields = [[NSArray alloc] initWithArray:[self queryObject]];
    
    if ([fields count] > 0) {

        NSMutableSet *tables = [[NSMutableSet alloc] init];
        
        NSMutableString *selectFields = [[NSMutableString alloc] initWithString:@""];
        
        for (RptqDatabaseSchemaField *field in fields) {
            
            MTDatabaseField *dbField = [RptqDatabaseSchemaField databaseFieldForSchemaField:field];
            RptqDatabaseSchemaTable *table = [field inTable];
            //NSString *safeTableName = [[self database] tableAliasForTable:table];
            [tables addObject:table];

            NSString *fieldAliasSafe = [[self database] fieldAliasForField:field];

            NSString *safeFieldName = [[self database] safeQuerySchemaField:field];
            [[self fields] setObject:dbField forKey:fieldAliasSafe];
            [[self fieldKeys] addObject:fieldAliasSafe];
            
            [selectFields appendFormat: @" %@( %@(%@) ) %@ %@,",
                    [[self database] sqlAggregateFunctionMax],
                    [[self database] sqlAggregateFunctionLength], safeFieldName,
                    [[self database] tableAliasConnector], fieldAliasSafe];
            
        }
        
        NSString *fieldsPart;
        if ([selectFields length] > 0) {
            fieldsPart = [selectFields substringToIndex:[selectFields length] - 1];
        } else {
            fieldsPart = @"";
        }
        
        NSMutableString *tableNamePart = [[NSMutableString alloc] initWithString:@""];
        NSInteger counter = 0;
        for (RptqDatabaseSchemaTable *table in tables) {
            if (counter > 0) {
                [tableNamePart appendString:@", "];
            }
            NSString *safeTableName = [[self database] tableAliasForTable:table];
            [tableNamePart appendString:safeTableName];
            counter++;
        }
        
        NSString *selectPart = [[self database] selectPart];
        
        sql = [NSString stringWithFormat:@"%@ %@ %@ %@;", selectPart, fieldsPart, MTSqlFrom, tableNamePart];

    }

    return sql;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {
    
    NSError *error = nil;
    NSString *sql = [self getSqlWithError:&error];
    
    if (error) {
        completion(NO, error, nil);
    } else {
        
        [[self database] executeSql:sql
                         completion:^(BOOL success, NSError *error, id results) {
                             [[self cache] cacheData:results];
                             completion(success, error, results);
                         }];
    }
    
}

@end
