//
//  MTQuerySampleDataTable.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuerySampleDataTable.h"
#import "MTDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "MTDatabaseField.h"
#import "MTCache.h"

@interface MTQuerySampleDataTable ()

@end

@implementation MTQuerySampleDataTable

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];

    NSMutableString *sql = [[NSMutableString alloc] initWithString:[[self database] selectPart]];
    RptqDatabaseSchemaTable *table = [self queryObject];
    NSString *safeTableName = [[self database] safeIdentifier: [table toString]];
    
    NSUInteger *fieldCounter = 0;
    
    for (RptqDatabaseSchemaField *field in [table hasFields]) {
        
        if (fieldCounter != 0)  [sql appendString:@",\n"];
        NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
        NSString *fieldName = [[self database] safeIdentifier: [field name]];
        NSString *fieldAlias = [tableAlias stringByAppendingString:fieldName];
        [sql appendFormat: @"\t%@", fieldAlias];
        MTDatabaseField *dbField = [RptqDatabaseSchemaField databaseFieldForSchemaField:field];
        [[self fields] setObject:dbField forKey:fieldAlias];
        fieldCounter++;
    }
    
    
    [sql appendString:MTSqlFrom];
    [sql appendString:safeTableName];
    return sql;
}

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        Class classRptqQuery = [RptqDatabaseSchemaTable class];
        if ([object isKindOfClass:classRptqQuery]) {
            [self setQueryObject:object];
        }
    }
    return self;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {
    
    NSError *error = nil;
    NSString *sql = [self getSqlWithError:&error];
    
    __block NSMutableArray *fieldNames = [[NSMutableArray alloc] init];
    [[self fields] enumerateKeysAndObjectsUsingBlock:^(id key, MTDatabaseField *field, BOOL *stop) {
        [fieldNames addObject:[field name]];
    }];
    [[self database] maxLengthForFields:fieldNames inTable:[[self queryObject] toString] completion:^(BOOL success, NSError *error, NSArray *widths) {
        if (success) {
            for (MTDatabaseField *field in [[self fields] objectEnumerator]) {
                NSString *name = [field name];
                NSString *key = [[self database]safeIdentifier: name];
                NSInteger maxSize = [[[widths objectAtIndex:0] objectForKey:key] integerValue];
                field.calculatedWidth = maxSize;
            }
            
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
    }];
    
    
}

@end
