//
//  MADQuerySelectPart.m
//  MAD
//
//  Created by Michael Thomason on 6/9/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQuerySelectExpression.h"

#import <CoreData/NSManagedObjectContext.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "MTDatabase.h"

@interface MADQuerySelectExpression ()

@property (nonatomic, readwrite, strong) NSString *sql;

@end

@implementation MADQuerySelectExpression

- (instancetype)initWithDatabase:(MTDatabase *)database
                          tables:(NSArray *)tables
           usingOnlyActiveFields:(BOOL)onlyActiveFields
         forManagedObjectContext:(NSManagedObjectContext *)context {

    if (self = [super init]) {
        
        NSMutableString *result = [[NSMutableString alloc] init];
        
        
        if (onlyActiveFields) {
            
            MADQueryActiveQueryFields *queryFields;
            queryFields = [[MADQueryActiveQueryFields alloc] initWithManagedObjectContext:context];
            
            NSUInteger fieldCounter = 0;
            for (RptqQueryField *queryField in queryFields.queryFields) {
                
                
                RptqDatabaseSchemaField *field = queryField.databaseSchemaField;
                if (fieldCounter != 0)  [result appendString:@",\n"];
                
                NSString *tableName = [queryField.inQueryTable copyQueryAlias];
                MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
                
                NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                MADSafeQueryField *fieldName = [database newSafeIdentifier: field.name];
                
                NSString *fieldAlias = [tableAlias stringByAppendingString:fieldName];
                [result appendFormat: @"\t%@", fieldAlias];
                
                fieldCounter++;
            }
            
            if (fieldCounter == 0) {
                result = nil;
            }
            
        } else {
            
            // Logic to return all fields.
            NSUInteger tableCounter = 0;
            for (MTPair *pair in tables) {
                MTVertex *queryTable = pair.former;
                NSManagedObjectID *objectID = queryTable.object;
                
                RptqQueryTable *table = [context objectWithID:objectID];
                if (table != nil) {
                    if (tableCounter != 0) [result appendString:@",\n"];
                    
                    NSString *tableName = [table copyQueryAlias];
                    MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
                    NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                    
                    NSUInteger fieldCounter = 0;
                    
                    for (RptqQueryField *queryField in table.hasQueryFields) {
                        RptqDatabaseSchemaField *field = queryField.databaseSchemaField;
                        if (fieldCounter != 0)  [result appendString:@",\n"];
                        NSString *fieldName = field.name;
                        MADSafeQueryField *safeFieldName = [database newSafeIdentifier:fieldName];
                        NSString *fieldAlias = [tableAlias stringByAppendingString:safeFieldName];
                        [result appendFormat: @"\t%@", fieldAlias];
                        fieldCounter++;
                    }
                    tableCounter++;
                }
            }
        }
        self.sql = result;
    }
    return self;
}

@end
