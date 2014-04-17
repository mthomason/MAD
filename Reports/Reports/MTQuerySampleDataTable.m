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
#import "RptqUserCredentals.h"
#import "RptqDatabase.h"
#import "MTDatabaseField.h"
#import "MTDataTable.h"
#import "MTDatabaseConnection.h"

@interface MTQuerySampleDataTable ()

@end

@implementation MTQuerySampleDataTable

- (id)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaTable class]], @"MTQuerySampleDataTable expects RptqDatabaseSchemaTable.");


        NSManagedObjectID *objectId = [object objectID];
        NSUInteger hash = [[[objectId URIRepresentation] absoluteString] hash];
        MTDataTable *datatable = [[MTDataTable alloc] initWithId:hash];
        [self setDatatable:datatable];

        RptqUserCredentals *userCredentals = [[(RptqDatabaseSchemaTable *)object inDatabase] ownedByUser];
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
        MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
        [self setDatabase:db];
        [self setQueryObject:object];

    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];

    NSMutableString *sql = [[NSMutableString alloc] initWithString:[[self database] selectPart]];
    RptqDatabaseSchemaTable *table = [self queryObject];
    
    [sql appendString:[[self database] sqlAllFieldsInTable:table]];
    
    NSString *safeTableName = [[self database] tableAliasForTable:table];

    if ([[self fieldKeys] count] <= 0) {
        for (RptqDatabaseSchemaField *field in [table hasFields]) {
            MTDatabaseField *dbField = [RptqDatabaseSchemaField databaseFieldForSchemaField:field];
            NSString *fieldAlias = [[self database] fieldAliasForField:field withSafeTableName:safeTableName];
            [[self fields] setObject:dbField forKey:fieldAlias];
            [[self fieldKeys] addObject:fieldAlias];
        }
    }
    
    NSOrderedSet *fields = [[self queryObject] hasFields];
    MTQuery *queryMaxFieldLenght = [[MTQuery alloc] initWithQueryType:MTQueryTypeMaxFieldLength object:fields];
    [[queryMaxFieldLenght database] executeQuery:queryMaxFieldLenght completion:^(BOOL success, NSError *errorFl) {
        if (success && [[queryMaxFieldLenght datatable] numberOfRows] > 0) {
            
            [fields enumerateObjectsUsingBlock:^(RptqDatabaseSchemaField *field, NSUInteger idx, BOOL *stop) {
                
                NSString *safeTableName = [[queryMaxFieldLenght database] tableAliasForTable:[field inTable]];
                NSString *okey = [[queryMaxFieldLenght database] fieldAliasForField:field withSafeTableName:safeTableName];
                NSString *ckey = [[queryMaxFieldLenght database] fieldAliasForField:field];
                NSDictionary *widthsByField = [[queryMaxFieldLenght datatable] objectAtIndex:0];
                NSInteger maxSize = [[widthsByField objectForKey:ckey] integerValue];
                MTDatabaseField *f = [[self fields] objectForKey:okey];
                f.calculatedWidth = maxSize;
            }];
        }
    }];
    
    [sql appendString:MTSqlFrom];
    [sql appendString:safeTableName];
    return sql;
}

@end
