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
#import <MADFoundation/MTDataTable.h>
#import "MTDataTable+Factory.h"
#import "MTDatabaseConnection.h"
#import <CoreData/NSManagedObjectID.h>

@interface MTQuerySampleDataTable ()
    <MTDatabaseProtocol>

    @property (nonatomic, strong) MTDataTable *dataTableMaxFieldLength;
    @property (nonatomic, copy, readwrite) MTDatabaseConnection *databaseConnection;

@end

@implementation MTQuerySampleDataTable

- (instancetype)initWithDatabaseConnection:(MTDatabaseConnection *)databaseConnection
                       databaseSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable {
 
    if (self = [super initWithObject:nil]) {
    
        MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier: databaseSchemaTable.objectID.URIRepresentation.absoluteString];
        self.database = db;
        self.dataTableMaxFieldLength = dataTable;
        self.queryObject = databaseSchemaTable;
        self.databaseConnection = databaseConnection.copy;

    }
    return self;
    
}

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {
        
        NSAssert([object isKindOfClass:[RptqDatabaseSchemaTable class]], @"MTQuerySampleDataTable expects RptqDatabaseSchemaTable.");

        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUserCredentals:((RptqDatabaseSchemaTable *)object).inDatabase.ownedByUser];
        MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier: ((RptqDatabaseSchemaTable *)object).objectID.URIRepresentation.absoluteString];
        self.database = db;
        self.dataTableMaxFieldLength = dataTable;
        self.queryObject = object;
        self.databaseConnection = databaseConnection.copy;
    }
    return self;
}

- (instancetype)initWithDatabaseSchemaTable:(RptqDatabaseSchemaTable *)object {

    if (self = [super initWithObject:object]) {
                
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForUserCredentals:((RptqDatabaseSchemaTable *)object).inDatabase.ownedByUser];
        MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        MTDataTable *dataTable = [MTDataTable newDataTableForIdentifier: ((RptqDatabaseSchemaTable *)object).objectID.URIRepresentation.absoluteString];
        self.database = db;
        self.dataTableMaxFieldLength = dataTable;
        self.queryObject = object;
        
    }
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSError *sqlError = nil;
    [super getSqlWithError:&sqlError];
    *error = sqlError;

    NSString *selectPart = [self.database selectPartWithLimitedResults:255];
    NSMutableString *sql = [[NSMutableString alloc] initWithString:selectPart];
    RptqDatabaseSchemaTable *table = self.queryObject;
    
    [sql appendString:[MTQuerySampleDataTable sqlAllFieldsInTable: table usingDatabase: self.database]];
    
    NSString *safeTableName = [self.database tableAliasForTable:table.toString];

    if (self.fieldKeys.count <= 0) {
        for (RptqDatabaseSchemaField *field in table.hasFields) {
            MTDatabaseField *dbField = [field databaseFieldWrapper];
            NSString *fieldAlias = [self.database fieldAliasForField:field.name withSafeTableName:safeTableName];
            self.fields[fieldAlias] = dbField;
            [self.fieldKeys addObject:fieldAlias];
        }
    }
    
    NSOrderedSet *fields = table.hasFields;
    MTQuery *queryMaxFieldLenght = [[MTQuery alloc] initWithQueryType: MTQueryTypeMaxFieldLength
                                                               object: fields];
    queryMaxFieldLenght.database.delegate = self;

    NSError * __autoreleasing blockError;
    bool success = [queryMaxFieldLenght.database executeQuery:queryMaxFieldLenght withError:&blockError];
    if (success && self.dataTableMaxFieldLength.numberOfRows > 0) {
        
        for (RptqDatabaseSchemaField *field in fields) {
            NSString *safeTableName = [queryMaxFieldLenght.database tableAliasForTable:field.inTable.toString];
            NSString *okey = [queryMaxFieldLenght.database fieldAliasForField: field.name withSafeTableName: safeTableName];
            NSString *ckey = [queryMaxFieldLenght.database fieldAliasForField: field.name andTableName: field.inTable.name];
            NSDictionary *widthsByField = [self.dataTableMaxFieldLength objectAtRow:0];
            NSNumber *widthByField = widthsByField[ckey];
            NSUInteger maxSize = ((NSNull *)widthByField == [NSNull null]) ? 0 : widthByField.unsignedIntegerValue;
            MTDatabaseField *f = self.fields[okey];
            f.calculatedWidth = maxSize;
        }
    }
    
    *error = blockError;
    
    [sql appendString:MADSqlTextFromPart];
    [sql appendString:safeTableName];
    NSString *sqlLimit = [self.database sqlLimitClause:255];
    [sql appendString:sqlLimit];
    return sql;
}

+ (NSString *)sqlAllFieldsInTable: (RptqDatabaseSchemaTable *)schemaTable
                    usingDatabase: (MTDatabase *)database {
    NSUInteger *fieldCounter = 0;
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    NSString *safeTableName = [database tableAliasForTable:schemaTable.toString];
    NSString *fieldAlias;
    RptqDatabaseSchemaField *field;
    for (field in [schemaTable hasFields]) {
        
        fieldAlias = [database fieldAliasForField:field.name
                                withSafeTableName:safeTableName];
        
        if (fieldCounter > 0)  [sql appendString:@",\n"];
        [sql appendFormat: @"\t%@", fieldAlias];
        
        fieldCounter++;
    }
    return sql;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self dataTableMaxFieldLength];
}

@end
