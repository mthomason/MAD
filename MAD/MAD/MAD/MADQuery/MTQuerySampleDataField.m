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
#import <CoreData/NSManagedObjectID.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTDatabase.h>
#import <MADFoundation/MTDataTable.h>
#import <MAD/MTDataTable+Factory.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabase.h>

@interface MTQuerySampleDataField ()
    <MTDatabaseProtocol>

    @property (nonatomic, strong) MTDataTable *datatable;

@end

@implementation MTQuerySampleDataField


- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaField class]], @"MTQuerySampleDataField expects RptqDatabaseSchemaField.");
        
        RptqUserCredentals * __weak userCredentals = ((RptqDatabaseSchemaField *)object).inTable.inDatabase.ownedByUser;
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUserCredentals:userCredentals];
        MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        db.delegate = self;
        
        NSLog(@"Identifier: %@ (%s)", ((NSManagedObject *)object).objectID.URIRepresentation.absoluteString, __func__);
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier: ((NSManagedObject *)object).objectID.URIRepresentation.absoluteString];
        self.datatable = dataTable;
        self.database = db;
        self.queryObject = object;
        
    }
    return self;
}


- (NSString *)getSqlWithError:(NSError **)error {
    [super getSqlWithError:error];
    NSString *key = [self.database fieldAliasForField: ((RptqDatabaseSchemaField *)self.queryObject).name
                                         andTableName: ((RptqDatabaseSchemaField *)self.queryObject).inTable.name];
    [self.fieldKeys addObject:key];
    return [self.database sqlSampleDataForField: ((RptqDatabaseSchemaField *)self.queryObject).name
                                       andTable: ((RptqDatabaseSchemaField *)self.queryObject).inTable.name];
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return self.datatable;
}

@end
