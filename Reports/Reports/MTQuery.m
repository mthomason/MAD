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
#import "MTQueryTest.h"
#import "MTQueryCustomSql.h"

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

- (id)initWithQueryType:(MTQueryType)type object:(id)object {
    switch (type) {
        case MTQueryTypeMaxFieldLength:
            self = [[MTQueryMaxFieldLength alloc] initWithObject:object];
            break;
        case MTQueryTypeCustomSql:
            self = [[MTQueryCustomSql alloc] initWithObject:object];
            break;
        case MTQueryTypeFull:
            self = [[MTQueryReport alloc] initWithObject:object];
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

- (id)initWithObject:(id)object {
    
    self = [super init];
    if (self) {
        
        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];

        MTDataTable *datatable = nil;
        RptqUserCredentals *userCredentals = nil;
        MTDatabaseConnection *databaseConnection = nil;

        [self setFields:fieldInfo];
        [self setFieldKeys:fieldKeys];

        NSManagedObjectID *objectId = nil;
        if ([object isKindOfClass:[RptqDatabase class]]) {

            objectId = [object objectID];
            userCredentals = [(RptqDatabase *)object ownedByUser];

        } else if ([object isKindOfClass:[RptqQuery class]]) {
            
            objectId = [object objectID];
            userCredentals = [[(RptqQuery *)object inDatabase] ownedByUser];

        } else if ([object isKindOfClass:[RptqDatabaseSchemaTable class]]) {
            
            objectId = [object objectID];
            userCredentals = [[(RptqDatabaseSchemaTable *)object inDatabase] ownedByUser];
            
        } else if ([object isKindOfClass:[RptqDatabaseSchemaField class]]) {

            objectId = [object objectID];
            userCredentals = [[[(RptqDatabaseSchemaField *)object inTable] inDatabase] ownedByUser];
            
        } else if ([object isKindOfClass:[RptqUserCredentals class]]) {

            objectId = [object objectID];
            userCredentals = object;
            
        } else if ([object isKindOfClass:[MTDatabaseConnection class]]) {
            
            databaseConnection = object;
            
        } else if ([object isKindOfClass:[NSOrderedSet class]]) {
            
            NSArray *array = [object array];
            [self setQueryObject: array];
            RptqDatabaseSchemaField *field = [array firstObject];
            userCredentals = [[[field inTable] inDatabase] ownedByUser];
            datatable = [[MTDataTable alloc] initWithId:[field hash]];
            
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
        
        if (objectId) {
            NSUInteger hash = [[[objectId URIRepresentation] absoluteString] hash];
            datatable = [[MTDataTable alloc] initWithId:hash];
        }

        [self setDatatable:datatable];

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
/*
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
}*/

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
