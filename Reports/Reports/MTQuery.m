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
#import "MTQueryReport.h"
#import "MTQueryMaxFieldLength.h"

#import "MTCache.h"
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

@property (nonatomic, strong, readwrite) MTDatabase *database;

@end

@implementation MTQuery

- (id)initWithObject:(id)object {
    self = [super init];
    if (self) {
        
        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        [self setFields:fieldInfo];
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
        [self setFieldKeys:fieldKeys];

        MTCache *cache = nil;
        RptqUserCredentals *userCredentals = nil;
        MTDatabaseConnection *databaseConnection = nil;
        
        if ([object isKindOfClass:[RptqDatabase class]]) {

            cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            userCredentals = [(RptqDatabase *)object ownedByUser];

        } else if ([object isKindOfClass:[RptqQuery class]]) {
            
            cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            userCredentals = [[(RptqQuery *)object inDatabase] ownedByUser];

        } else if ([object isKindOfClass:[RptqDatabaseSchemaTable class]]) {
            
            cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            userCredentals = [[(RptqDatabaseSchemaTable *)object inDatabase] ownedByUser];
            
        } else if ([object isKindOfClass:[RptqDatabaseSchemaField class]]) {

            cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            userCredentals = [[[(RptqDatabaseSchemaField *)object inTable] inDatabase] ownedByUser];
            
        } else if ([object isKindOfClass:[RptqUserCredentals class]]) {
        
            cache = [[MTCache alloc] initWithObjectID:[object objectID]];
            userCredentals = object;
            
        } else if ([object isKindOfClass:[MTDatabaseConnection class]]) {
            
            databaseConnection = object;

        } else if ([object isKindOfClass:[NSDictionary class]]) {
            
            
            MTQueryType type = [object[MTQueryKeyType] integerValue];
            switch (type) {
                case MTQueryTypeMaxFieldLength: {
                    NSOrderedSet *queryObject = object[MTQueryKeyObject];
                    NSArray *array = [queryObject array];
                    [self setQueryObject: array];
                    RptqDatabaseSchemaField *field = [(NSArray *)queryObject firstObject];
                    userCredentals = [[[field inTable] inDatabase] ownedByUser];
                    break;
                }
                default:
                    NSAssert(false, @"Nothing I ever heard of?");
                    break;
            }
            
        } else {
            NSAssert(false, @"What type of query do you want?");
        }
        
        [self setCache:cache];


        if (databaseConnection == nil) {
            NSAssert(userCredentals != nil, @"What type of query do you want?");
            databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
        } else {
            
        }

        MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
        [self setDatabase:db];
        
    }
    return self;
}

+ (id)queryFactory:(id)object {
    id result = nil;

    if ([object isKindOfClass:[RptqQuery class]]) {
        
        result = [[MTQueryReport alloc] initWithObject:object];
        
    } else if ([object isKindOfClass:[RptqDatabaseSchemaTable class]]) {
        
        result = [[MTQuerySampleDataTable alloc] initWithObject:object];
        
    } else if ([object isKindOfClass:[RptqDatabaseSchemaField class]]) {
        
        result = [[MTQuerySampleDataField alloc] initWithObject:object];
        
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        
        MTQueryType type = [object[MTQueryKeyType] integerValue];
        switch (type) {
            case MTQueryTypeMaxFieldLength:
                result = [[MTQueryMaxFieldLength alloc] initWithObject:object];
                break;
            default:
                NSAssert(false, @"Nothing I ever heard of?");
                break;
        }
        
    } else {
        NSAssert(false, @"What type of query do you want?");
    }
    
    return result;
}

- (void)performQuery:(void (^)(BOOL success, NSError *error, id results))completion {
    
    @autoreleasepool {
        [[self database] executeQuery:self completion:^(BOOL success, NSError *error, MTDataTable *results) {
            [[self cache] cacheData:results];
            completion(success, error, results);
        }];
    }
}

- (NSString *)getSqlWithError:(NSError **)error {
    [[self fields] removeAllObjects];
    [[self fieldKeys] removeAllObjects];
    return @"";
}

- (NSString *)getSqlOnlyActiveFields:(BOOL)onlyActiveFields error:(NSError **)error {
    @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                   reason: [NSString stringWithFormat:@"Not implemented: %@.", NSStringFromSelector(_cmd)]
                                 userInfo: nil];
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
