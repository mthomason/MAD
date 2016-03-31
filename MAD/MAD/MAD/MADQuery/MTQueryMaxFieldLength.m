//
//  MTQueryMaxFieldLength.m
//  MAD
//
//  Created by Michael Thomason on 4/1/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryMaxFieldLength.h"
#import <MADFoundation/MTDataTable.h>
#import "MTDatabase.h"
#import "MTDatabaseField.h"
#import "RptqDatabase.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "MTDatabaseConnection.h"

@interface MTQueryMaxFieldLength ()

@end

@implementation MTQueryMaxFieldLength

- (instancetype)initWithObject:(id)object {
    self = [super initWithObject:object];
    if (self) {
        
        NSAssert([object respondsToSelector:@selector(array)], @"MTQueryMaxFieldLength expects to respond to array (hint, send an order set..");

        NSArray *array = [object array];
        
        NSAssert([[array firstObject] isKindOfClass:[RptqDatabaseSchemaField class]], @"Need RptqDatabaseSchemaField's!");

        [self setQueryObject: array];
        RptqDatabaseSchemaField *field = [array firstObject];

        RptqUserCredentals *userCredentals = [[[field inTable] inDatabase] ownedByUser];
        MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionForObject:userCredentals];
        MTDatabase *db = [MTDatabase newDatabaseWithConnection:databaseConnection];
        self.database = db;
    }
    
    return self;
}

- (NSString *)getSqlWithError:(NSError **)error {
    NSError *sqlError = nil;
    [super getSqlWithError:&sqlError];
    *error = sqlError;
    
    NSString *sql = nil;
    NSArray *fields = [[NSArray alloc] initWithArray:[self queryObject]];
    
    if ([fields count] > 0) {

        NSMutableSet *tables = [[NSMutableSet alloc] init];
        
        NSMutableString *selectFields = [[NSMutableString alloc] initWithString:@""];
        
        for (RptqDatabaseSchemaField *field in fields) {
            
            MTDatabaseField *dbField = [field databaseFieldWrapper];
            RptqDatabaseSchemaTable *table = [field inTable];
            [tables addObject:table];

            NSString *fieldAliasSafe = [self.database fieldAliasForField:field.name
                                                              andTableName:field.inTable.name];
            NSString *safeFieldName = [self.database safeQueryField:field.name
                                                             andTable:field.inTable.name];
            [self fields][fieldAliasSafe] = dbField;
            [[self fieldKeys] addObject:fieldAliasSafe];
            
            [selectFields appendFormat: @" %@( %@(%@) ) %@ %@,",
                    [self.database sqlAggregateFunctionMax],
                    [self.database sqlAggregateFunctionLength], safeFieldName,
                    [self.database tableAliasConnector], fieldAliasSafe];
            
        }
        
        NSString *fieldsPart;
        if ([selectFields length] > 0) {
            fieldsPart = [selectFields substringToIndex:[selectFields length] - 1];
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
        
        sql = [NSString stringWithFormat:@"%@ %@ %@ %@;", selectPart, fieldsPart, MADSqlTextFromPart, tableNamePart];

    }

    return sql;
}

@end
