//
//  MTQuerySampleDataField.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQuerySampleDataField.h"
#import <CoreData/NSManagedObjectID.h>
#import <Foundation/NSException.h>
#import <Foundation/NSURL.h>
#import <MADFoundation/MADDataTable.h>
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaTable.h"
#import "MTDatabase.h"
#import "MADDatabaseConnection.h"
#import "MADDatabaseResultsProtocol.h"
#import "MTDatabase+Constructor.h"
#import "MADDataTable+Constructor.h"

#import "RptqDatabaseCredentals+Extras.h"

@interface MTQuerySampleDataField ()
    <MADDatabaseResultsProtocol>

    @property (nonatomic, strong) MADDataTable *datatable;

@end

@implementation MTQuerySampleDataField


- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaField class]],
                 @"MTQuerySampleDataField expects RptqDatabaseSchemaField.");
        
        RptqDatabaseCredentals *userCredentals;
        MADDatabaseConnection *databaseConnection;
        MTDatabase *db;
        
        userCredentals = ((RptqDatabaseSchemaField *)object).inTable.inDatabase.ownedByUser;
        databaseConnection = [MADDatabaseConnection newDatabaseConnectionWithCredentals:userCredentals];
        
        db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        db.delegate = self;
        
        NSString *identifier = ((NSManagedObject *)object).objectID.URIRepresentation.absoluteString;
        MADDataTable *dataTable = [MADDataTable newDataTableForIdentifier:identifier];
        self.datatable = dataTable;
        self.database = db;
        self.queryObject = object;
        
    }
    return self;
}


- (NSString *)getSqlWithError:(NSError * __autoreleasing *)error {
    [super getSqlWithError:error];
    NSString *key = [self.database fieldAliasForField: ((RptqDatabaseSchemaField *)self.queryObject).name
                                         andTableName: ((RptqDatabaseSchemaField *)self.queryObject).inTable.name];
    [self.fieldKeys addObject:key];
    return [self.database sqlSampleDataForField: ((RptqDatabaseSchemaField *)self.queryObject).name
                                       andTable: ((RptqDatabaseSchemaField *)self.queryObject).inTable.name];
}

- (MADDataTable *)dataTableForQuery:(MTQuery *)query {
    return self.datatable;
}

- (MADQueryType)type {
    return MADQueryTypeSampleDataTable;
}

@end
