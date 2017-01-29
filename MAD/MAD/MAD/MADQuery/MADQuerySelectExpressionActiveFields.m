//
//  MADQuerySelectExpressionActiveFields.m
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQuerySelectExpressionActiveFields.h"
#import <CoreData/NSManagedObjectContext.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTVertex.h>

#import "MADQueryActiveQueryFields.h"
#import "RptqDatabaseSchemaField+CoreDataClass.h"
#import "RptqQueryTable+Extras.h"
#import "RptqQueryField+CoreDataClass.h"
#import "MTDatabase.h"
#import <Foundation/NSString.h>

@interface MADQuerySelectExpressionActiveFields ()

    @property (nonatomic, readwrite, strong) NSMutableDictionary <NSString *, RptqDatabaseSchemaField *> *fields;
    @property (nonatomic, readwrite, strong) NSMutableArray <NSString *> *fieldKeys;

@end

@implementation MADQuerySelectExpressionActiveFields

- (instancetype)initWithDatabase:(MTDatabase *)database
         forManagedObjectContext:(NSManagedObjectContext *)context {

    if (self = [super init]) {
        
        NSMutableString *result = [[NSMutableString alloc] init];
        MADQueryActiveQueryFields *queryFields;
        queryFields = [[MADQueryActiveQueryFields alloc] initWithManagedObjectContext:context];

        NSSet <RptqQueryField *> *rptqQueryFields = queryFields.queryFields;
        NSMutableDictionary *fields = [[NSMutableDictionary alloc] initWithCapacity:rptqQueryFields.count];
        NSMutableArray *fieldKeys = [[NSMutableArray alloc] initWithCapacity:rptqQueryFields.count];
        
        
        NSUInteger fieldCounter = 0;
        for (RptqQueryField *queryField in queryFields.queryFields) {
            
            
            RptqDatabaseSchemaField *field = queryField.databaseSchemaField;
            if (fieldCounter != 0)  [result appendString:@",\n"];
            
            NSString *tableName = [queryField.inQueryTable copyQueryAlias];
            MADSafeQueryField *safeTableName = [database newSafeIdentifier:tableName];
            
            NSString *tableAlias = [safeTableName stringByAppendingString:@"."];
            MADSafeQueryField *fieldName = [database newSafeIdentifier: field.name];
            
            NSString *fieldAlias = [tableAlias stringByAppendingString:fieldName];
            [result appendString: @"\t"];
            [result appendString: fieldAlias];
            
            fields[fieldAlias] = field;
            [fieldKeys addObject:fieldAlias];
            
            fieldCounter++;
        }
        if (fieldCounter > 0) {
            self.sql = result;
        }
        self.fields = fields;
        self.fieldKeys = fieldKeys;
        
    }
    return self;
}

@end

