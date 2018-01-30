//
//  MADQuerySampleDataTable.m
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQuerySampleDataTable.h"

#import <CoreData/NSManagedObjectID.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSError.h>

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADDataTablePlist.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqDatabase.h"

#import "MADQuery+Extras.h"

#import "MADDatabase+Constructor.h"
#import "MADDataTable+Constructor.h"
#import "MADDatabaseField+Constructor.h"

#import "RptqDatabaseCredentals+Extras.h"

@interface MADQuerySampleDataTable ()
    <MADDatabaseResultsProtocol>

    @property (nonatomic, strong) id queryObject;
    @property (nonatomic, strong) MADDataTable *dataTableMaxFieldLength;

@end

@implementation MADQuerySampleDataTable

@synthesize credential = _credential;
@synthesize fields = _fields;
@synthesize fieldKeys = _fieldKeys;
@synthesize dataTable = _dataTable;
@synthesize database = _database;

- (instancetype)initWithObject:(id)object {
    if (self = [super initWithObject:object]) {
        
        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        self.fields = fieldInfo;

        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
        self.fieldKeys = fieldKeys;

        NSAssert([object isKindOfClass:[RptqDatabaseSchemaTable class]],
                 @"MADQuerySampleDataTable expects RptqDatabaseSchemaTable.");

        MADDataTable *dataTable = [MADDataTable newDataTableForIdentifier: ((RptqDatabaseSchemaTable *)object).objectID.URIRepresentation.absoluteString];
        self.dataTableMaxFieldLength = dataTable;
        self.queryObject = object;

    }
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    NSError * __autoreleasing sqlError = NULL;
    [super getSql: &sqlError];
    if (sqlError && error != NULL) {
      *error = sqlError;
    }
    NSAssert(sqlError == NULL, @"Error: %@", sqlError.localizedDescription);

    NSString *selectPart = [self.database selectPartWithLimitedResults:255];
    NSMutableString *sql = [[NSMutableString alloc] initWithString:selectPart];
    RptqDatabaseSchemaTable *table = self.queryObject;
    
    [sql appendString:[MADQuerySampleDataTable sqlAllFieldsInTable: table
                                                    usingDatabase: self.database]];
    
    NSString *safeTableName = [self.database tableAliasForTable:table.toString];

    if (self.fieldKeys.count <= 0) {
        for (RptqDatabaseSchemaField *field in table.hasFields) {
            MADDatabaseField *databaseField = [MADDatabaseField newDatabaseFieldWithSchemaField:field];
            NSString *fieldAlias = [self.database fieldAliasForField:field.name
                                                   withSafeTableName:safeTableName];
            self.fields[fieldAlias] = databaseField;
            [self.fieldKeys addObject:fieldAlias];
        }
    }
    
    NSOrderedSet *fields = table.hasFields;
    MADQuery <MADQueryDatabaseProtocol> *queryMaxFieldLenght;
    queryMaxFieldLenght = (MADQuery <MADQueryDatabaseProtocol> *)[[MADQuery alloc] initWithQueryType: MADQueryTypeMaxFieldLength
                                                                                              object: fields];
    queryMaxFieldLenght.database.delegate = self;

    NSError * __autoreleasing blockError = NULL;
    BOOL success = [queryMaxFieldLenght.database executeQuery: queryMaxFieldLenght
                                                withDataTable: self.dataTableMaxFieldLength
                                                     andError: &blockError];
    NSAssert(blockError == NULL, @"Error: %@", blockError.localizedDescription);
    if (success && self.dataTableMaxFieldLength.numberOfRows > 0) {
        
        for (RptqDatabaseSchemaField *field in fields) {
            NSString *tableName = [queryMaxFieldLenght.database tableAliasForTable:field.inTable.toString];
            NSString *okey = [queryMaxFieldLenght.database fieldAliasForField: field.name
                                                            withSafeTableName: tableName];
            NSString *ckey = [queryMaxFieldLenght.database fieldAliasForField: field.name
                                                                 andTableName: field.inTable.name];
            NSDictionary *widthsByField = [self.dataTableMaxFieldLength objectAtRow:0];
            NSNumber *widthByField = widthsByField[ckey];
            NSUInteger maxSize = ((NSNull *)widthByField == [NSNull null]) ? 0 : widthByField.unsignedIntegerValue;
            MADDatabaseField *databaseField = self.fields[okey];
            databaseField.calculatedWidth = maxSize;
        }
    }
    
    [sql appendString:MADSqlTextFromPart];
    [sql appendString:safeTableName];
    
    NSString *sqlLimit = [self.database sqlLimitClause:255];
    [sql appendString:sqlLimit];
    
    return sql;
}

+ (NSString *)sqlAllFieldsInTable: (RptqDatabaseSchemaTable *)schemaTable
                    usingDatabase: (MADDatabase *)database {
    NSUInteger *fieldCounter = 0;
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    NSString *safeTableName = [database tableAliasForTable:schemaTable.toString];
    NSString *fieldAlias;
    RptqDatabaseSchemaField *field;
    for (field in schemaTable.hasFields) {
        
        fieldAlias = [database fieldAliasForField:field.name
                                withSafeTableName:safeTableName];
        
        if (fieldCounter > 0)  [sql appendString:@",\n"];
        [sql appendFormat: @"\t%@", fieldAlias];
        
        fieldCounter++;
    }
    return sql;
}

- (MADDataTable *)dataTableForQuery:(MADQuery *)query {
    return self.dataTableMaxFieldLength;
}

@end
