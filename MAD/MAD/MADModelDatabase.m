//
//  MADModelDatabase.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelDatabase.h"

#import <Foundation/NSException.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSExpressionDescription.h>

#import "MADModel.h"
#import "MADModelTable.h"
#import "MADModelQuery.h"

#import "RptqQuery.h"
#import "RptqDatabaseSchemaField.h"

@interface MADModelDatabase ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                             queryID:(NSManagedObjectID *)queryID
                          queryIdentifier:(int64_t)queryIdentifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

#pragma mark -
#pragma mark MAD Database Object ID

@implementation MADModelDatabase {
@protected
    NSManagedObjectContext * __weak _managedObjectContext;
    NSOrderedSet <MADModelTable *> *_tables;
    NSOrderedSet <MADModelQuery *> *_queries;
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize tables = _tables;
@synthesize queries = _queries;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                         queryID:(NSManagedObjectID *)queryID
                 queryIdentifier:(int64_t)queryIdentifier
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    if (self = [super initWithObjectID:objectID identifier:identifier]) {
        _managedObjectContext = managedObjectContext;
        MADModelQuery *queryObjectID;
        
        NSMutableOrderedSet <MADModelQuery *> *queries;
        queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
        
        queryObjectID = [[MADModelQuery alloc] initWithObjectID: queryID
                                                     identifier: queryIdentifier
                                                       database: self];
        [queries addObject: queryObjectID];
        _queries = queries;
    }
    return self;
}

- (NSOrderedSet <MADModelTable *> *)tables {
    if (!_tables) {
        @autoreleasepool {
            [self updateTables];
        }
    }
    return _tables;
}

- (NSOrderedSet <MADModelQuery *> *)queries {
    if (!_queries) {
        @autoreleasepool {
            [self updateQueries];
        }
    }
    return _queries;
}

- (MADModelQuery *)firstQuery {
    return self.queries.firstObject;
}

- (void)update {
    @autoreleasepool {
        [self updateTables];
    }
    @autoreleasepool {
        [self updateQueries];
    }
}

- (void)updateTables {
    NSManagedObjectContext *managedObjectContext = _managedObjectContext;
    
    NSError * __autoreleasing *error = NULL;
    NSArray <NSDictionary *> *results;
    
    void (^setupExpressionWithType)(NSExpressionDescription *, NSString *, NSExpression *, NSAttributeType) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression, NSAttributeType type) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = type;
    };
    
    void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
        setupExpressionWithType(expressionDescription, name, expression, NSObjectIDAttributeType);
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = NSManagedObjectIDResultType;
    };
    
    int expressionCount = 4;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionInQuery[2];
    NSString *inTable, *name, *inDatabase, *inTableInDB, *inTableName, *keyField, *keyFieldName, *keyTable, *keyTableName;
    
    keyField = @"F";
    keyTable = @"T";
    keyFieldName = @"G";
    keyTableName = @"U";
    
    inTable = NSStringFromSelector(@selector(inTable));
    inDatabase = NSStringFromSelector(@selector(inDatabase));
    name = NSStringFromSelector(@selector(name));
    inTableInDB = [[NSString alloc] initWithFormat:@"%@.%@", inTable, inDatabase];
    inTableName = [[NSString alloc] initWithFormat:@"%@.%@", inTable, name];
    expressionInQuery[0] = [NSExpression expressionForKeyPath:inTableInDB];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: self.objectID];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                   rightExpression: expressionInQuery[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    for (int i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    NSFetchRequest *fetchQueryTable;
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabaseSchemaField class])];
    
    NSExpression *expressionForTable = [NSExpression expressionForKeyPath:inTable],
    *expressionForSelf = [NSExpression expressionForEvaluatedObject],
    *expresssionForTableName = [NSExpression expressionForKeyPath:inTableName],
    *expressionForName = [NSExpression expressionForKeyPath:name];
    
    setupExpression(expressionDescription[0], keyField, expressionForSelf);
    
    setupExpression(expressionDescription[1], keyTable, expressionForTable);
    
    setupExpressionWithType(expressionDescription[2],
                            keyTableName,
                            expresssionForTableName,
                            NSStringAttributeType);
    
    setupExpressionWithType(expressionDescription[3],
                            keyFieldName,
                            expressionForName,
                            NSStringAttributeType);
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription[3],
                         expressionDescription[2],
                         expressionDescription[1],
                         expressionDescription[0], nil];
    
    for (int i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
    }
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    
    fetchQueryTable.resultType = NSDictionaryResultType;
    fetchQueryTable.predicate = predicate;
    
    NSSortDescriptor *sortByFieldName = [[NSSortDescriptor alloc] initWithKey:name ascending:YES],
    *sortByTableName = [[NSSortDescriptor alloc] initWithKey:inTableName ascending:YES];
    
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByTableName, sortByFieldName, nil];
    
    fetchQueryTable.sortDescriptors = sortDescriptors;
    results = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    
    NSMutableOrderedSet <MADModelTable *> *tables;
    tables = [[NSMutableOrderedSet alloc] init];
    
    
    NSArray *filteredResults;
    NSComparisonPredicate *predicateTable;
    NSExpression *tablePath = [NSExpression expressionForKeyPath: keyTable],
    *tableValue;
    
    @autoreleasepool {
        
        NSArray *tableValues = [results valueForKey:keyTable];
        NSOrderedSet *tableObjectIDs;
        tableObjectIDs = [[NSOrderedSet alloc] initWithArray: tableValues copyItems:NO];
        
        MADModelTable *table;
        NSManagedObjectID *tableObjectID;
        NSDictionary *attributes;
        @autoreleasepool {
            for (tableObjectID in tableObjectIDs) {
                
                @autoreleasepool {
                    
                    tableValue = [NSExpression expressionForConstantValue: tableObjectID];
                    predicateTable = [NSComparisonPredicate predicateWithLeftExpression: tablePath
                                                                        rightExpression: tableValue
                                                                               modifier: NSDirectPredicateModifier
                                                                                   type: NSEqualToPredicateOperatorType
                                                                                options: 0];
                    filteredResults = [results filteredArrayUsingPredicate: predicateTable];
                    table = [[MADModelTable alloc] initWithObjectID: tableObjectID
                                                         identifier: -1
                                                               name: filteredResults.firstObject[keyTableName]];
                    [tables addObject:table];
                    for (attributes in filteredResults) {
                        [table addFieldWithID: attributes[keyField]
                                   identifier: -1
                                         name: attributes[keyFieldName]
                         managedObjectContext: managedObjectContext];
                    }
                }
            }
            tableValue = nil;
        }
    }
    _tables = tables;
}

- (void)updateQueries {
    NSFetchRequest *request;
    NSArray <NSManagedObjectID *> *result;
    
    NSExpression *expression[2];
    expression[0] = [NSExpression expressionWithFormat: @"%@.%@",
                     NSStringFromSelector(@selector(inDatabase)),
                     NSStringFromSelector(@selector(objectID))];
    
    expression[1] = [NSExpression expressionForConstantValue:self.objectID];
    
    NSAssert(expression != nil, @"Need an expression");
    NSComparisonPredicate *predicate;
    predicate= [NSComparisonPredicate predicateWithLeftExpression: expression[0]
                                                  rightExpression: expression[1]
                                                         modifier: NSDirectPredicateModifier
                                                             type: NSEqualToPredicateOperatorType
                                                          options: 0];
    
    request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    request.resultType = NSManagedObjectIDResultType;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    NSError * __autoreleasing *error = NULL;
    NSManagedObjectContext *managedObjectContext;
    managedObjectContext = _managedObjectContext;
    result = [managedObjectContext executeFetchRequest:request error:error];
    
    NSMutableOrderedSet <MADModelQuery *> *queries;
    queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
    MADModelQuery *queryObjectID;
    NSUInteger i = 0;
    for (NSManagedObjectID *objid in result) {
        queryObjectID = [[MADModelQuery alloc] initWithObjectID:objid
                                                     identifier: -1
                                           managedObjectContext:managedObjectContext];
        [queries addObject: queryObjectID];
        queryObjectID = nil;
        i++;
    }
    _queries = queries;
    result = nil;;
    request = nil;
    predicate = nil;
    expression[0] = nil;
    expression[1] = nil;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@", self.debugDescription];
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Tables:\t%@", self.tables];
    [debug appendFormat:@"Queries:\t%@", self.queries];
    return debug;
}

@end
