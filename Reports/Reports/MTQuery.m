//
//  MTQuery.m
//  MAD
//
//  Created by Michael Thomason on 3/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuery.h"
#import "MTQuerySampleDataField.h"
#import "MTQuerySampleDataTable.h"
#import "MTQueryFull.h"
#import "MTQueryMaxFieldLength.h"
#import "MTQueryTest.h"
#import "MTQueryCustomNoResults.h"

#import "MTDatabase.h"
#import "MTDatabaseField.h"

#import "MTGraph.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqQueryField.h"
#import "RptqQueryPredicate.h"
#import "RptqQueryPredicate+Extras.h"

#import "NSError+UserInterface.h"

#import "MTDatabaseConnectionMySql.h"
#import "MTDatabaseConnectionSqlite3.h"
#import "MTDatabaseConnectionSqlServer.h"

#import "RptqDatabase.h"
#import "RptqUserCredentals.h"

#import "MTDataTable.h"

NSString * const MTQueryKeyType = @"MTQueryKeyType";
NSString * const MTQueryKeyObject = @"MTQueryKeyObject";

@interface MTQuery ()

@end

@implementation MTQuery

- (id)initWithQueryType:(MTQueryType)type object:(id)object {
    switch (type) {
        case MTQueryTypeMaxFieldLength:
            self = [[MTQueryMaxFieldLength alloc] initWithObject:object];
            break;
        case MTQueryTypeCustomSql:
            self = [[MTQueryCustomNoResults alloc] initWithObject:object];
            break;
        case MTQueryTypeFull:
            self = [[MTQueryFull alloc] initWithObject:object];
            break;
        case MTQueryTypeConnectionTest:
            self = [[MTQueryTest alloc] initWithObject:object];
            break;
        case MTQueryTypeSampleDataField:
            self = [[MTQuerySampleDataField alloc] initWithObject:object];
            break;
        case MTQueryTypeSampleDataTable:
            self = [[MTQuerySampleDataTable alloc] initWithObject:object];
            break;
            
        default:
            break;
    }
    
    return self;
}

- (BOOL)returnsResults {
    return YES;
}

- (id)initWithObject:(id)object {
    
    self = [super init];
    if (self) {
        
        NSMutableArray *binaryBindings = [[NSMutableArray alloc] init];
        [self setBinaryBindings:binaryBindings];

        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];

        [self setFields:fieldInfo];
        [self setFieldKeys:fieldKeys];

    }
    return self;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error))completion {
    
    @autoreleasepool {
        [[self database] executeQuery:self completion:^(BOOL success, NSError *error) {
            [[self datatable] cache];
            completion(success, error);
        }];
    }
}

- (NSString *)getSqlWithError:(NSError **)error {
    [[self fields] removeAllObjects];
    [[self fieldKeys] removeAllObjects];
    return @"";
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error {
    return @"";
}

- (NSString *)getSqlForAllFieldsInTable:(RptqDatabaseSchemaTable *)table {
    NSString *tableName = [table toString];
    return [NSString stringWithFormat:@"SELECT * FROM %@", tableName];
}

- (NSString *)sqlGroupByExpressionWithQuery:(RptqQuery *)query {
    //Group is done on the reporting client side, so we do not add group by information here.
    return @"";
}

- (NSArray *)sortedHasQueryGroups {
    return [NSArray array];
}

- (NSArray *)sortDescriptors {
    return [NSArray array];
}

- (NSString *)fieldKeyForIndex:(NSUInteger)index {
    return (index < [[self fieldKeys] count]) ? [[self fieldKeys] objectAtIndex:index] : nil;
}

@end
