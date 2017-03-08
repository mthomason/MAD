//
//  MADQuerySelectExpressionAllFields.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADQuerySelectExpressionAllFields.h"

#import <CoreData/NSManagedObjectContext.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField.h"
#import "MTDatabase.h"

@implementation MADQuerySelectExpressionAllFields

- (instancetype)initWithDatabase:(MTDatabase *)database
                          tables:(NSArray <MTPair *> *)tables
         forManagedObjectContext:(NSManagedObjectContext *)context {
    
    if (self = [super init]) {
        
        NSMutableString *result = [[NSMutableString alloc] init];

        NSUInteger tableCounter = 0;
        for (MTPair *pair in tables) {
            MTVertex *queryTable = pair.former;
            NSManagedObjectID *objectID = queryTable.object;
            
            RptqQueryTable *table = [context objectWithID:objectID];
            if (table != nil) {
                if (tableCounter != 0) [result appendString:@",\n"];
                
                NSString *tableName = [table queryAlias];
                MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
                NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
                
                NSUInteger fieldCounter = 0;
                
                RptqQueryField *queryField;
                NSEnumerator <RptqQueryField *> *hasQueryFields;
                hasQueryFields = table.hasQueryFields.objectEnumerator;
                MADSafeQueryField *safeFieldName;
                NSString *fieldAlias;
                for (queryField in hasQueryFields) {
                    if (fieldCounter != 0)  [result appendString:@",\n"];
                    safeFieldName = [database newSafeIdentifier:queryField.databaseSchemaField.name];
                    fieldAlias = [tableAlias stringByAppendingString:safeFieldName];
                    [result appendString: @"\t"];
                    [result appendString: fieldAlias];
                    fieldCounter++;
                }
                tableCounter++;
            }
        }
        self.sql = result;
    }
    return self;
}

@end
