//
//  MADModelDatabase.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelDatabase.h"

#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSException.h>
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
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"



@interface MADModelDatabase ()
    - (instancetype)initIdentifier:(int64_t)identifier
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initIdentifier:(int64_t)identifier
                           queryID:(NSManagedObjectID *)queryID
                   queryIdentifier:(int64_t)queryIdentifier
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

#pragma mark -
#pragma mark MAD Database Object ID

@implementation MADModelDatabase {
@protected
    NSManagedObjectContext * __weak _managedObjectContext;
    NSMutableOrderedSet <NSNumber *> *_tables;
    NSMutableDictionary <NSNumber *, MADModelTable *> *_tableDictionary;
    NSOrderedSet <MADModelQuery *> *_queries;
}

@dynamic managedObjectContext;
@dynamic tableDictionary;
@dynamic tables;

@synthesize queries = _queries;

- (NSManagedObjectContext *)managedObjectContext {
    return _managedObjectContext;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithIdentifier:identifier]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
                   queryIdentifier:(int64_t)queryIdentifier
              managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    if (self = [super initWithIdentifier:identifier]) {
        _managedObjectContext = managedObjectContext;
        MADModelQuery *queryObjectID;
        
        NSMutableOrderedSet <MADModelQuery *> *queries;
        queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
        
        queryObjectID = [[MADModelQuery alloc] initWithIdentifier: queryIdentifier
                                                         database: self];
        [queries addObject: queryObjectID];
        _queries = queries;
    }
    return self;
}

- (NSDictionary <NSNumber *, MADModelTable *> *)tableDictionary {
    if (!_tableDictionary) {
        @autoreleasepool {
            [self updateTables];
        }
    }
    return _tableDictionary;
}

- (NSOrderedSet <NSNumber *> *)tables {
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

/**
 @brief Fetches RptqQueryField <Name, Identifier> for all query tables.
 @param None
 @returns
 @abstract
*/

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
    
    NSUInteger expressionCount = 3;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *predicateExpression[2];
    
    NSString *inTable, *name, *inDatabase, *inTableInDB, *inTableName,
                *keyField, *keyFieldName, *keyTable, *keyTableName;
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    keyField = @"F";
    keyTable = @"T";
    keyFieldName = @"G";
    keyTableName = @"U";
    
    inTable = NSStringFromSelector(@selector(inTable));
    inDatabase = NSStringFromSelector(@selector(inDatabase));
    name = NSStringFromSelector(@selector(name));
    inTableInDB = [[NSString alloc] initWithFormat:@"%@.%@", inTable, inDatabase];
    inTableName = [[NSString alloc] initWithFormat:@"%@.%@", inTable, name];
    
    NSString *inTableInDBIdentifier = [inTableInDB stringByAppendingString:@"."];
    inTableInDBIdentifier = [inTableInDBIdentifier stringByAppendingString:keyIdentifier];
    NSString *inDatabaseIdentifier = [inDatabase stringByAppendingString:@"."];
    inDatabaseIdentifier = [inDatabaseIdentifier stringByAppendingString:keyIdentifier];
    predicateExpression[0] = [NSExpression expressionForKeyPath:inDatabaseIdentifier];
    predicateExpression[1] = [NSExpression expressionForConstantValue: @(self.identifier)];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
                                                   rightExpression: predicateExpression[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    NSFetchRequest *fetchQueryTable;
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaTable class]);
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSString *keyPathQuerable = NSStringFromSelector(@selector(queryable));
    NSExpression *expressionForSelf = [NSExpression expressionForKeyPath:keyIdentifier],
                 *expresssionForQueryable = [NSExpression expressionForKeyPath:keyPathQuerable],
                 *expressionForName = [NSExpression expressionForKeyPath:name];
    
    setupExpressionWithType(expressionDescription[0],
                            keyIdentifier,
                            expressionForSelf,
                            NSInteger64AttributeType);
    
    setupExpressionWithType(expressionDescription[1],
                            keyPathQuerable,
                            expresssionForQueryable,
                            NSBooleanAttributeType);
    
    setupExpressionWithType(expressionDescription[2],
                            name,
                            expressionForName,
                            NSStringAttributeType);
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:expressionCount];
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    
    fetchQueryTable.resultType = NSDictionaryResultType;
    fetchQueryTable.predicate = predicate;
    
    NSSortDescriptor *sortByTableName;
    sortByTableName = [[NSSortDescriptor alloc] initWithKey:name ascending:YES];
    
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByTableName, nil];
    
    fetchQueryTable.sortDescriptors = sortDescriptors;
    results = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    
    NSMutableOrderedSet <NSNumber *> *tables;
    NSMutableDictionary <NSNumber *, MADModelTable *> *tableDictionary;

    tables = [[NSMutableOrderedSet alloc] init];
    tableDictionary = [[NSMutableDictionary alloc] init];
    
    MADModelTable *table;
    NSDictionary *tableData;
    for (tableData in results) {
        
        NSNumber *schemaTableIdentifier = tableData[keyIdentifier];
        NSString *schemaTableName = tableData[name];
        NSNumber *schemaTableQuerable = tableData[keyPathQuerable];
        
        table = [[MADModelTable alloc] initWithIdentifier: schemaTableIdentifier.longLongValue
                                     managedObjectContext: managedObjectContext
                                                     name: schemaTableName
                                                queryable: schemaTableQuerable.boolValue];
        [tables addObject:schemaTableIdentifier];
        [tableDictionary setObject:table forKey:schemaTableIdentifier];
    }

    predicateExpression[0] = nil;
    predicateExpression[1] = nil;
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
    }
    _tableDictionary = tableDictionary;
    _tables = tables;
}

- (void)updateQueries {
    NSFetchRequest *request;
    NSArray <NSDictionary <NSString *, NSNumber *> *> *result;
    NSExpression *expression[2];
    NSComparisonPredicate *predicate;
    NSExpressionDescription *expressionDescription;
    NSString *keyPathIdentifier = NSStringFromSelector(@selector(identifier));
    expressionDescription = [[NSExpressionDescription alloc] init];
    expressionDescription.name = keyPathIdentifier.copy;
    expressionDescription.expression = [NSExpression expressionForKeyPath:keyPathIdentifier];
    expressionDescription.expressionResultType = NSInteger64AttributeType;
    
    expression[0] = [NSExpression expressionWithFormat: @"%@.%@",
                     NSStringFromSelector(@selector(inDatabase)),
                     keyPathIdentifier];
    
    expression[1] = [NSExpression expressionForConstantValue:@(self.identifier)];
    request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    
    NSAssert(expression != nil, @"Need an expression");
    predicate= [NSComparisonPredicate predicateWithLeftExpression: expression[0]
                                                  rightExpression: expression[1]
                                                         modifier: NSDirectPredicateModifier
                                                             type: NSEqualToPredicateOperatorType
                                                          options: 0];
    request.predicate = predicate;
    request.resultType = NSDictionaryResultType;
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
    for (NSDictionary <NSString *, NSNumber *> *objid in result) {
        queryObjectID = [[MADModelQuery alloc] initWithIdentifier: objid[keyPathIdentifier].longLongValue
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

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    if (_tables) {
        [debug appendFormat:@"Tables:\t%@", _tables];
    }
    if (_queries) {
        [debug appendFormat:@"Queries:\t%@", self.queries];
    }
    return debug;
}

@end
