//
//  RptqQueryTable+Extras.m
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryTable+Extras.h"

#import <CoreFoundation/CFNumber.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSExpression.h>

#import <stdio.h>

#import "madlib.h"

#import "RptqDocument+Extras.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery+Extras.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDataHelper.h"

@implementation RptqQueryTable (Extras)

+ (NSString *)keyPathAlias {
    NSString *result = NSStringFromSelector(@selector(alias));
    return result;
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
}

+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID
                  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryTable *)[managedObjectContext objectWithID:objectID];
}

+ (NSFetchRequest *)fetchRequestQueryTables:(NSPredicate *)predicate {
    
    NSFetchRequest *fetchQueryTable;
    NSString *entityName;
    entityName = NSStringFromClass([RptqQueryTable class]);
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSString *keyPathInQueryTable = NSStringFromSelector(@selector(inQueryTable));
    NSString *keyPathDatabaseSchemaTable = NSStringFromSelector(@selector(databaseSchemaTable));
    NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *keyPathName = NSStringFromSelector(@selector(name));
    NSString *keyPathFieldName = [keyPathDatabaseSchemaField stringByAppendingString:@"."];
    keyPathFieldName = [keyPathFieldName stringByAppendingString:keyPathName];
    
    NSString *keyPathTableName = [keyPathInQueryTable stringByAppendingString:@"."];
    keyPathTableName = [keyPathTableName stringByAppendingString: keyPathDatabaseSchemaTable];
    keyPathTableName = [keyPathTableName stringByAppendingString: @"."];
    keyPathTableName = [keyPathTableName stringByAppendingString: keyPathName];
    
    NSString *keyPathSchemaTable = [keyPathInQueryTable stringByAppendingString: @"."];
    keyPathSchemaTable = [keyPathSchemaTable stringByAppendingString: keyPathDatabaseSchemaTable];
    
    NSUInteger expressionCount = 10;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSString *keys[] = {
        @"QTI",
        @"STI",
    };
    
    NSString *keyQueryTableID, *keyQueryFieldID, *keySchemaTableID, *keySchemaFieldID;
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    
    keyQueryTableID = [keyPathInQueryTable stringByAppendingString:@"."];
    keyQueryTableID = [keyQueryTableID stringByAppendingString:keyIdentifier];
    
    keyQueryFieldID = keyIdentifier.copy;
    
    keySchemaTableID = [keyPathSchemaTable stringByAppendingString:@"."];
    keySchemaTableID = [keySchemaTableID stringByAppendingString:keyIdentifier];
    
    keySchemaFieldID = [keyPathDatabaseSchemaField stringByAppendingString:@"."];
    keySchemaFieldID = [keySchemaFieldID stringByAppendingString:keyIdentifier];
    
    NSExpression *expressions[] = {
        [NSExpression expressionForKeyPath: keyIdentifier],
        [NSExpression expressionForKeyPath: keyPathDatabaseSchemaTable],
    };
    
    NSAttributeType types[] = {
        NSInteger64AttributeType,
        NSInteger64AttributeType,
    };
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
        expressionDescription[i].name = keys[i].copy;
        expressionDescription[i].expression = expressions[i];
        expressionDescription[i].expressionResultType = types[i];
        
    }
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects: expressionDescription
                                                   count: (NSUInteger)expressionCount];
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    fetchQueryTable.resultType = NSDictionaryResultType;
    fetchQueryTable.predicate = predicate;
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
        keys[i] = nil;
        expressions[i] = nil;
    }
    return fetchQueryTable;
}

+ (RptqQueryTable *)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
                                       database:(RptqDatabase *)database
                        forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {


    RptqQuery *query = database.defaultQuery;
    NSSet <RptqQueryTable *> *queryTables = query.hasQueryTables;
    int64_t dupeCtr = 0;
    RptqQueryTable *queryTable;
    for (queryTable in queryTables) {
        if ([queryTable.databaseSchemaTable.objectID isEqual:databaseSchemaTable.objectID]) {
            dupeCtr++;
        }
    }
    
    NSEntityDescription *tableEntity;
    tableEntity = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryTable class])
                              inManagedObjectContext: managedObjectContext];
    queryTable = [[RptqQueryTable alloc] initWithEntity: tableEntity
                         insertIntoManagedObjectContext: managedObjectContext];

    queryTable.databaseSchemaTable = databaseSchemaTable;
    queryTable.inQuery = query;

    queryTable.dropIndex = dupeCtr;
    
    NSString *alias = [[NSString alloc] initWithString:queryTable.tableAlias];
    queryTable.alias = alias;
    
    return queryTable;
}

- (NSString *)tableAlias {
    return self.dropIndex == 0 ? self.databaseSchemaTable.name : [self queryAlias];
}

- (NSString *)queryAlias {
    char buf[22]; char *ptr;
    ltoa(self.dropIndex, buf);
    ptr = buf;
    NSString *indexString = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return [self.databaseSchemaTable.name stringByAppendingString:indexString];
}

- (BOOL)isEqualTo:(RptqQueryTable *)sender {
    
    if ([sender isEqual:sender])
        return YES;

    if ([sender isKindOfClass:self.class]) {
        NSNumber *i1;
        NSNumber *i2;
        return [i1 isEqualToNumber:i2];
    }
    
    return NO;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"***********   RptqQueryTable  ***********\n"];
    [description appendFormat:@"Identifier:             %lld\n", self.identifier];
    [description appendFormat:@"Alias:                  %@\n", self.alias];
    [description appendFormat:@"***********   RptqQueryTable  ***********"];
    return description;
}

@end
