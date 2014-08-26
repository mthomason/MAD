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
#import "MTDataTable.h"
#import "RptqDatabase.h"
#import "MTDatabaseConnection.h"

@interface MTQuerySampleDataField ()
<MTDatabaseProtocol>

@property (nonatomic, strong) MTDataTable *datatable;

//- (instancetype)initWithObject:(id)object NS_DESIGNATED_INITIALIZER;

@end

@implementation MTQuerySampleDataField


- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaField class]], @"MTQuerySampleDataField expects RptqDatabaseSchemaField.");
        
        RptqUserCredentals *userCredentals = [[[(RptqDatabaseSchemaField *)object inTable] inDatabase] ownedByUser];
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory:userCredentals];
        MTDatabase *db = [MTDatabase databaseFactory:databaseConnection];
        db.delegate = self;
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier:[[[object objectID] URIRepresentation] absoluteString]];
        [self setDatatable:dataTable];
        [self setDatabase:db];
        [self setQueryObject:object];
        
    }
    return self;
}


- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    NSString *key = [[self database] fieldAliasForField:[self queryObject]];
    [[self fieldKeys] addObject:key];
    return [[self database] sqlSampleDataForField:[self queryObject]];
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self datatable];
}

@end
