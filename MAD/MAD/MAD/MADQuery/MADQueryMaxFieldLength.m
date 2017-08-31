//
//  MADQueryMaxFieldLength.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryMaxFieldLength.h"

#import <Foundation/NSException.h>
#import <Foundation/NSError.h>

#import <MADAPI/MADDatabaseConnection.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>

#import "RptqDatabase.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "MADDatabase+Constructor.h"
#import "MADDatabaseField+Constructor.h"

#import "RptqDatabaseCredentals+Extras.h"
#import <MADAPI/MADQueryType.h>

@interface MADQueryMaxFieldLength ()
    @property (nonatomic, strong) id queryObject;
@end

@implementation MADQueryMaxFieldLength

@synthesize fields = _fields;
@synthesize fieldKeys = _fieldKeys;
@synthesize database = _database;

- (instancetype)initWithObject:(id)object {

    if (self = [super initWithObject:object]) {

        NSMutableArray *fieldKeys = [[NSMutableArray alloc] init];
        self.fieldKeys = fieldKeys;
        
        NSMutableDictionary *fieldInfo = [[NSMutableDictionary alloc] init];
        self.fields = fieldInfo;
        
        NSAssert([object respondsToSelector:@selector(array)], @"MADQueryMaxFieldLength expects to respond to array (hint, send an order set..");

        NSArray *array = [object array];
        
        NSAssert([[array firstObject] isKindOfClass:[RptqDatabaseSchemaField class]], @"Need RptqDatabaseSchemaField's!");

        self.queryObject = array;
        RptqDatabaseSchemaField *field = array.firstObject;

        id databaseConnection;
        databaseConnection = [MADDatabaseConnection newDatabaseConnectionWithCredentals:field.inTable.inDatabase.ownedByUser];
        MADDatabase *db = [MADDatabase newDatabaseWithConnection:databaseConnection];
        self.database = db;
    }
    
    return self;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
    NSError * __autoreleasing sqlError = NULL;
    [super getSql: &sqlError];
    if (sqlError && *error == NULL) {
        *error = sqlError;
    }
    NSAssert(sqlError == NULL, @"Error: %@", (sqlError).localizedDescription);
    
    NSString *sql = nil;
    NSArray *fields = [[NSArray alloc] initWithArray:self.queryObject];
    
    if (fields.count > 0) {

        NSMutableSet *tables = [[NSMutableSet alloc] init];
        NSMutableString *selectFields = [[NSMutableString alloc] initWithString:@""];
        
        for (RptqDatabaseSchemaField *field in fields) {
            
            MADDatabaseField *dbField = [MADDatabaseField newDatabaseFieldWithSchemaField:field];
            RptqDatabaseSchemaTable *table = field.inTable;

            [tables addObject:table];

            NSString *fieldAliasSafe = [self.database fieldAliasForField:field.name
                                                              andTableName:field.inTable.name];
            MADSafeQueryField *safeFieldName = [self.database newSafeQueryField:field.name
                                                             andTable:field.inTable.name];
            self.fields[fieldAliasSafe] = dbField;
            [self.fieldKeys addObject:fieldAliasSafe];
            
            [selectFields appendFormat: @" %@( %@(%@) ) %@ %@,",
                    [self.database sqlAggregateFunctionMax],
                    [self.database sqlAggregateFunctionLength], safeFieldName,
                    [self.database tableAliasConnector], fieldAliasSafe];
            
        }
        
        NSString *fieldsPart;
        if (selectFields.length > 0) {
            fieldsPart = [selectFields substringToIndex:selectFields.length - 1];
        } else {
            fieldsPart = @"";
        }
        
        NSMutableString *tableNamePart = [[NSMutableString alloc] initWithString:@""];
        NSInteger counter = 0;
        for (RptqDatabaseSchemaTable *table in tables) {
            if (counter > 0) {
                [tableNamePart appendString:@", "];
            }
            NSString *safeTableName = [self.database tableAliasForTable:table.toString];
            [tableNamePart appendString:safeTableName];
            counter++;
        }
        
        NSString *selectPart = [self.database selectPart];
        
        sql = [[NSString alloc] initWithFormat: @"%@ %@ %@ %@;",
                                                selectPart, fieldsPart,
                                                MADSqlTextFromPart, tableNamePart];

    }

    return sql;
}

- (MADQueryType)type {
    return MADQueryTypeMaxFieldLength;
}

@end
