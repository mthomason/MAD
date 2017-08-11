//
//  RptqQueryField+Extras.m
//  Reports
//
//  Created by Michael Thomason on 5/13/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryField+Extras.h"

#if DEBUG
    #import <objc/runtime.h>
#endif

#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSExpressionDescription.h>

#import <MADFoundation/NSString+Common.h>

#import "RptqQueryTable+Extras.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDataHelper.h"

@implementation RptqQueryField (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                           managedObjectContext:self.managedObjectContext];
}

+ (NSString *)keyInQueryTable {
    NSString *keyPathInQueryTable = NSStringFromSelector(@selector(inQueryTable));
    return keyPathInQueryTable;
}

+ (NSString *)keyName {
    NSString *keyName = NSStringFromSelector(@selector(name));
    return keyName;
}

+ (NSString *)dropIndex {
    NSString *key = NSStringFromSelector(@selector(dropIndex));
    return key;
}

+ (NSString *)keyInQueryTableDropIndex {
    NSString *keyPathInQueryTable = [self keyInQueryTable];
    NSString *keyPathDropIndex = NSStringFromSelector(@selector(dropIndex));
    NSString *keyPathInQueryTableDropIndex = [keyPathInQueryTable stringByAppendingPeriod];
    keyPathInQueryTableDropIndex = [keyPathInQueryTableDropIndex stringByAppendingString:keyPathDropIndex];
    return keyPathInQueryTableDropIndex;
}

+ (NSString *)keyDatabaseSchemaTable {
    NSString *keyPathDatabaseSchemaTable = NSStringFromSelector(@selector(databaseSchemaTable));
    return keyPathDatabaseSchemaTable;
}

+ (NSString *)keyTableName {
    NSString *keyPathName = [self keyName];
    NSString *keyPathInQueryTable = [self keyInQueryTable];
    NSString *keyPathTableName = [keyPathInQueryTable stringByAppendingPeriod];
    NSString *keyPathDatabaseSchemaTable = [self keyDatabaseSchemaTable];
    keyPathTableName = [keyPathTableName stringByAppendingString: keyPathDatabaseSchemaTable];
    keyPathTableName = [keyPathTableName stringByAppendingPeriod];
    keyPathTableName = [keyPathTableName stringByAppendingString: keyPathName];
    return keyPathTableName;
}

+ (NSString *)keyFieldName {
    NSString *keyPathName = [self keyName];
    NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *keyPathFieldName = [keyPathDatabaseSchemaField stringByAppendingPeriod];
    keyPathFieldName = [keyPathFieldName stringByAppendingString:keyPathName];
    return keyPathFieldName;
}

+ (NSString *)keySchemaTable {
    NSString *keyPathInQueryTable = [self keyInQueryTable];
    NSString *keyPathDatabaseSchemaTable = [self keyDatabaseSchemaTable];
    NSString *keyPathSchemaTable = [keyPathInQueryTable stringByAppendingPeriod];
    keyPathSchemaTable = [keyPathSchemaTable stringByAppendingString: keyPathDatabaseSchemaTable];
    return keyPathSchemaTable;
}

+ (NSString *)keyQueryTableID {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *keyInQueryTable = [self keyInQueryTable];
    NSString *key;
    key = [keyInQueryTable stringByAppendingPeriod];
    key = [key stringByAppendingString:keyIdentifier];
    return key;
}

+ (NSString *)keyQueryFieldID {
    NSString *key = NSStringFromSelector(@selector(identifier));
    return key;
}

+ (NSString *)keySchemaTableID {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *keySchemaTable = [self keySchemaTable];
    NSString *key = [keySchemaTable stringByAppendingPeriod];
    key = [key stringByAppendingString:keyIdentifier];
    return key;
}

+ (NSString *)keySchemaFieldID {
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *keyDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *key = [keyDatabaseSchemaField stringByAppendingPeriod];
    key = [key stringByAppendingString:keyIdentifier];
    return key;
}

+ (NSString *)keySchemaFieldName {
    NSString *keyName = NSStringFromSelector(@selector(name));
    NSString *keyDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *key = [keyDatabaseSchemaField stringByAppendingPeriod];
    key = [key stringByAppendingString:keyName];
    return key;
}

+ (NSString *)keySchemaFieldDataType {
    NSString *keyDataType = NSStringFromSelector(@selector(dataType));
    NSString *keyDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *key = [keyDatabaseSchemaField stringByAppendingPeriod];
    key = [key stringByAppendingString:keyDataType];
    return key;
}

+ (NSString *)keyInQueryTableAlias {
    NSString *keyAlias = NSStringFromSelector(@selector(alias));
    NSString *key = [self keyInQueryTable];
    key = [key stringByAppendingPeriod];
    key = [key stringByAppendingString:keyAlias];
    return key;
}

+ (NSFetchRequest *)fetchRequestFields:(int64_t)identifier {
    
    NSUInteger expressionInQueryCount = 2;

    NSExpression *pexpressions[expressionInQueryCount];
    NSString *predicateKey;
    NSNumber *idn = @(identifier);
    NSString *keyInQueryTable = [self keyInQueryTable];
    predicateKey = [keyInQueryTable stringByAppendingPeriod];
    predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(inQuery))];
    predicateKey = [predicateKey stringByAppendingPeriod];
    predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(identifier))];
    
    pexpressions[0] = [NSExpression expressionForKeyPath:predicateKey];
    pexpressions[1] = [NSExpression expressionForConstantValue: idn];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                   rightExpression: pexpressions[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];

    
    NSFetchRequest *fetchQueryTable;
    NSString *entityName;
    entityName = NSStringFromClass([RptqQueryField class]);
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSString *keyPathInQueryTable = [self keyInQueryTable];
    
    NSString *keyPathInQueryTableDropIndex = [self keyInQueryTableDropIndex];
    
    NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *keyPathFieldName = [self keyFieldName];
    NSString *keyPathTableName = [self keyTableName];
    NSString *keyPathSchemaTable = [self keySchemaTable];
    NSString *keyQueryTableID = [self keyQueryTableID],
             *keyQueryFieldID = [self keyQueryFieldID],
             *keySchemaTableID = [self keySchemaTableID],
             *keySchemaFieldID = [self keySchemaFieldID],
             *keyQueryTableAlias = [self keyInQueryTableAlias],
             *keySchemaFieldDataType = [self keySchemaFieldDataType];
    NSString *keySelf = NSStringFromSelector(@selector(self));
    NSUInteger expressionCount = 13;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSString *keys[] = {
        keySelf,
        keyPathInQueryTable,
        keyPathFieldName,
        keyPathTableName,
        keyPathSchemaTable,
        keyPathDatabaseSchemaField,
        
        keyQueryTableID,
        keyQueryFieldID,
        keySchemaTableID,
        keySchemaFieldID,
        keyPathInQueryTableDropIndex,
        keyQueryTableAlias,
        keySchemaFieldDataType
    };
    
    NSExpression *expressions[] = {
        [NSExpression expressionForEvaluatedObject],
        [NSExpression expressionForKeyPath: keyPathInQueryTable],
        [NSExpression expressionForKeyPath: keyPathFieldName],
        [NSExpression expressionForKeyPath: keyPathTableName],
        [NSExpression expressionForKeyPath: keyPathSchemaTable],
        [NSExpression expressionForKeyPath: keyPathDatabaseSchemaField],
        
        [NSExpression expressionForKeyPath: keyQueryTableID],
        [NSExpression expressionForKeyPath: keyQueryFieldID],
        [NSExpression expressionForKeyPath: keySchemaTableID],
        [NSExpression expressionForKeyPath: keySchemaFieldID],
        [NSExpression expressionForKeyPath: keyPathInQueryTableDropIndex],
        [NSExpression expressionForKeyPath: keyQueryTableAlias],
        [NSExpression expressionForKeyPath: keySchemaFieldDataType]
    };

    NSAttributeType types[] = {
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        NSStringAttributeType,
        NSStringAttributeType,
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSStringAttributeType,
        NSInteger16AttributeType,
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
    
    for (NSUInteger i=0; i<expressionInQueryCount; i++) {
        pexpressions[i] = nil;
    }

    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
        keys[i] = nil;
        expressions[i] = nil;
    }
    return fetchQueryTable;
}

+ (NSFetchRequest *)fetchRequestFieldKeys:(int64_t)identifier {
    
    NSUInteger expressionInQueryCount = 2;

    NSExpression *pexpressions[expressionInQueryCount];
    NSString *predicateKey;
    NSNumber *idn = @(identifier);
    NSString *keyInQueryTable = [self keyInQueryTable];
    predicateKey = [keyInQueryTable stringByAppendingPeriod];
    predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(inQuery))];
    predicateKey = [predicateKey stringByAppendingPeriod];
    predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(identifier))];
    
    pexpressions[0] = [NSExpression expressionForKeyPath:predicateKey];
    pexpressions[1] = [NSExpression expressionForConstantValue: idn];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: pexpressions[0]
                                                   rightExpression: pexpressions[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];

    
    NSString *entityName;
    NSFetchRequest *fetchQueryTable;
    
    entityName = NSStringFromClass([RptqQueryField class]);
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSString *keyPathInQueryTable = [self keyInQueryTable],
             *keyPathInQueryTableDropIndex = [self keyInQueryTableDropIndex],
             *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField)),
             *keyPathFieldName = [self keyFieldName],
             *keyPathTableName = [self keyTableName],
             *keyPathSchemaTable = [self keySchemaTable],
             *keyQueryTableID = [self keyQueryTableID],
             *keyQueryFieldID = [self keyQueryFieldID],
             *keySchemaTableID = [self keySchemaTableID],
             *keySchemaFieldID = [self keySchemaFieldID],
             *keySelf = NSStringFromSelector(@selector(self));
    NSUInteger expressionCount = 11;
    NSExpressionDescription *expressionDescription[expressionCount];
    
    NSString *keys[] = {
        keySelf,
        keyPathInQueryTable,
        keyPathFieldName,
        keyPathTableName,
        keyPathSchemaTable,
        keyPathDatabaseSchemaField,
        
        keyQueryTableID,
        keyQueryFieldID,
        keySchemaTableID,
        keySchemaFieldID,
        keyPathInQueryTableDropIndex
    };
    
    NSExpression *expressions[] = {
        [NSExpression expressionForEvaluatedObject],
        [NSExpression expressionForKeyPath: keyPathInQueryTable],
        [NSExpression expressionForKeyPath: keyPathFieldName],
        [NSExpression expressionForKeyPath: keyPathTableName],
        [NSExpression expressionForKeyPath: keyPathSchemaTable],
        [NSExpression expressionForKeyPath: keyPathDatabaseSchemaField],
        
        [NSExpression expressionForKeyPath: keyQueryTableID],
        [NSExpression expressionForKeyPath: keyQueryFieldID],
        [NSExpression expressionForKeyPath: keySchemaTableID],
        [NSExpression expressionForKeyPath: keySchemaFieldID],
        [NSExpression expressionForKeyPath: keyPathInQueryTableDropIndex],
    };

    NSAttributeType types[] = {
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        NSStringAttributeType,
        NSStringAttributeType,
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSInteger64AttributeType,
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
    
    for (NSUInteger i=0; i<expressionInQueryCount; i++) {
        pexpressions[i] = nil;
    }

    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
        keys[i] = nil;
        expressions[i] = nil;
    }
    return fetchQueryTable;
}

+ (instancetype)newQueryField:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
    NSString *entityName = NSStringFromClass([RptqQueryField class]);
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: managedObjectContext];
    RptqQueryField *queryField = [[RptqQueryField alloc] initWithEntity: entity
                                         insertIntoManagedObjectContext: managedObjectContext];
    return queryField;
}

- (NSString *)tableFieldKey {
    return [self toString];
}

- (NSString *)display {
    return self.toStringHumanReadable.lowercaseString;
}

+ (instancetype)queryFieldForObjectID:(NSManagedObjectID *)objectId
                 managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqQueryField *)[managedObjectContext objectWithID:objectId];
}

#pragma mark - MTProtocolLog

- (NSString *)toStringHumanReadable {
    return [self.inQueryTable.alias stringByAppendingKeyPath: self.databaseSchemaField.name];
}

- (NSString *)toStringReverse {
    return [self.databaseSchemaField.name stringByAppendingKeyPath: self.inQueryTable.alias];
}

- (NSString *)toString {
    NSString *queryAlias = [self.inQueryTable queryAlias];
    return [queryAlias stringByAppendingKeyPath: self.databaseSchemaField.name];
}

- (NSString *)toStringDebug {
    return [NSString stringWithFormat:@"%@", self];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"***********   RptqQueryField  ***********\n"];
    [description appendFormat:@"Identifier:             %lld\n", self.identifier];
    [description appendFormat:@"Schema field:           %@\n", self.databaseSchemaField];
    [description appendFormat:@"***********   RptqQueryField  ***********"];
    return description;
}

@end
