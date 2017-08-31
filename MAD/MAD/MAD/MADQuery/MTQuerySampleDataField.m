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
#import <MADAPI/MADDatabase.h>
#import "MADDatabase+Constructor.h"
#import "MADDataTable+Constructor.h"

#import "RptqDatabaseCredentals+Extras.h"
#import <MADAPI/MADQueryType.h>

@interface MTQuerySampleDataField ()

    @property (nonatomic, strong) id queryObject;

@end

@implementation MTQuerySampleDataField

@dynamic fields;
@synthesize fieldKeys = _fieldKeys;
@synthesize dataTable = _dataTable;
@synthesize database = _database;

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
        self.fieldKeys = fieldKeys;

        NSAssert([object isKindOfClass:[RptqDatabaseSchemaField class]],
                 @"MTQuerySampleDataField expects RptqDatabaseSchemaField.");

        NSString *identifier = ((NSManagedObject *)object).objectID.URIRepresentation.absoluteString;
        MADDataTable *dataTable = [MADDataTable newDataTableForIdentifier:identifier];
        self.dataTable = dataTable;
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

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
    return self.dataTable;
}

- (MADQueryType)type {
    return MADQueryTypeSampleDataTable;
}

- (NSMutableDictionary <NSString *, id> *)fields {
    return nil;
}

@end
