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
    <MTDatabaseProtocol>

@property (nonatomic, strong) MTDataTable *dataTableMaxFieldLength;

@end

@implementation MTQuerySampleDataTable

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaTable class]], @"MTQuerySampleDataTable expects RptqDatabaseSchemaTable.");

        RptqUserCredentals *userCredentals = [[(RptqDatabaseSchemaTable *)object inDatabase] ownedByUser];
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
        MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier:[[[object objectID] URIRepresentation] absoluteString]];
        [self setDatabase:db];
        [self setDataTableMaxFieldLength:dataTable];
        [self setQueryObject:object];

    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];

    NSMutableString *sql = [[NSMutableString alloc] initWithString:[[self database] selectPartWithLimitedResults:255]];
    RptqDatabaseSchemaTable *table = [self queryObject];
    
    [sql appendString:[[self database] sqlAllFieldsInTable:table]];
    
    NSString *safeTableName = [[self database] tableAliasForTable:table.toString];

    if ([[self fieldKeys] count] <= 0) {
        for (RptqDatabaseSchemaField *field in [table hasFields]) {
            MTDatabaseField *dbField = [field databaseFieldWrapper];
            NSString *fieldAlias = [[self database] fieldAliasForField:field.name withSafeTableName:safeTableName];
            [self fields][fieldAlias] = dbField;
            [[self fieldKeys] addObject:fieldAlias];
        }
    }
    
    NSOrderedSet *fields = [[self queryObject] hasFields];
    MTQuery *queryMaxFieldLenght = [[MTQuery alloc] initWithQueryType:MTQueryTypeMaxFieldLength object:fields];
    [queryMaxFieldLenght database].delegate = self;
    [[queryMaxFieldLenght database] executeQuery:queryMaxFieldLenght completion:^(BOOL success, NSError *errorFl) {
        if (success && [[self dataTableMaxFieldLength] numberOfRows] > 0) {
            
            [fields enumerateObjectsUsingBlock:^(RptqDatabaseSchemaField *field, NSUInteger idx, BOOL *stop) {
                
                NSString *safeTableName = [queryMaxFieldLenght.database tableAliasForTable:field.inTable.toString];
                NSString *okey = [queryMaxFieldLenght.database fieldAliasForField:field.name withSafeTableName:safeTableName];
                NSString *ckey = [queryMaxFieldLenght.database fieldAliasForField:field.name andTableName:field.inTable.name];
                NSDictionary *widthsByField = [[self dataTableMaxFieldLength] objectAtRow:0];
                NSNumber *widthByField = widthsByField[ckey];
                NSInteger maxSize = ((NSNull *)widthByField == [NSNull null]) ? 0 : [widthByField integerValue];
                MTDatabaseField *f = [self fields][okey];
                f.calculatedWidth = maxSize;
            }];
        }
    }];
    
    [sql appendString:MTSqlFrom];
    [sql appendString:safeTableName];
    NSString *sqlLimit = [[self database] sqlLimitClause:255];
    [sql appendString:sqlLimit];
    return sql;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self dataTableMaxFieldLength];
}

@end
