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
#import <Foundation/NSException.h>
#import <Foundation/NSURL.h>
#import "RptqDatabase+CoreDataClass.h"
#import "RptqDatabaseSchemaField+CoreDataClass.h"
#import "RptqDatabaseSchemaTable+CoreDataClass.h"
#import "MTDatabase.h"
#import "MTDataTable.h"
#import "MADDatabaseConnection.h"
#import "MADDatabaseProtocol.h"

@interface MTQuerySampleDataField ()
    <MTDatabaseProtocol>

@property (nonatomic, strong) MTDataTable *datatable;

@end

@implementation MTQuerySampleDataField


- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaField class]],
                 @"MTQuerySampleDataField expects RptqDatabaseSchemaField.");
        
        RptqUserCredentals *userCredentals;
        MADDatabaseConnection *databaseConnection;
        MTDatabase *db;
        
        userCredentals = ((RptqDatabaseSchemaField *)object).inTable.inDatabase.ownedByUser;
        databaseConnection = [MADDatabaseConnection newDatabaseConnectionForObject:userCredentals];
        
        db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        db.delegate = self;
        
        NSString *identifier = ((NSManagedObject *)object).objectID.URIRepresentation.absoluteString;
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier:identifier];
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

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return self.datatable;
}

- (MADQueryType)type {
    return MADQueryTypeSampleDataTable;
}

@end
