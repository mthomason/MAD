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
#import <MADAPI/MADDatabaseConnection.h>
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import <MADAPI/MTDatabase.h>
#import "MTDatabase+Constructor.h"
#import "MADDataTable+Constructor.h"

#import "RptqDatabaseCredentals+Extras.h"

@interface MTQuerySampleDataField ()

    @property (nonatomic, strong) id queryObject;
    @property (nonatomic, strong) MADDataTable *datatable;

@end

@implementation MTQuerySampleDataField

@synthesize fieldKeys = _fieldKeys;

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
        self.fieldKeys = fieldKeys;

        NSAssert([object isKindOfClass:[RptqDatabaseSchemaField class]],
                 @"MTQuerySampleDataField expects RptqDatabaseSchemaField.");

        NSString *identifier = ((NSManagedObject *)object).objectID.URIRepresentation.absoluteString;
        MADDataTable *dataTable = [MADDataTable newDataTableForIdentifier:identifier];
        self.datatable = dataTable;
        self.queryObject = object;
        
    }
    return self;
}


- (NSString *)getSql:(NSError * __autoreleasing *)error {
    [super getSql:error];
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
