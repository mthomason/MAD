//
//  MADModelTable.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADModelTable.h"

#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSExpressionDescription.h>

#import <MADFoundation/NSString+Common.h>

#import "MADModelField.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#pragma mark -
#pragma mark MADModelTable

@implementation MADModelTable {
    BOOL _queryable;
    NSString *_name;
    NSMutableOrderedSet <NSNumber *> *_fieldIDs;
    NSMutableDictionary <NSNumber *, MADModelField *> *_fields;
}

@synthesize managedObjectContext = _managedObjectContext;

@dynamic fields;
@dynamic fieldIDs;
@dynamic name;

- (void)dealloc {
    [_fieldIDs removeAllObjects];
    [_fields removeAllObjects];
    _inDatabase = nil;
    _managedObjectContext = nil;
}

- (instancetype)initWithIdentifier:(int64_t)identifier {
    if (self = [self initWithIdentifier:identifier
                   managedObjectContext:nil]) {

    }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
              managedObjectContext:(NSManagedObjectContext *)context {
    if (self = [self initWithIdentifier:identifier
                   managedObjectContext:context
                                   name:nil
                              queryable:NO]) {
        
    }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
              managedObjectContext:(NSManagedObjectContext *)context
                              name:(NSString *)name
                         queryable:(BOOL)queryable {
    if (self = [super initWithIdentifier:identifier]) {
        _name = name.copy;
        _queryable = queryable;
        _managedObjectContext = context;
    }
    return self;
}

- (NSString *)name {
    return _name;
}

- (NSOrderedSet <NSNumber *> *)fieldIDs {
    if (_fieldIDs.count == 0) {
        
        NSMutableOrderedSet <NSNumber *> *fieldIDs;
        fieldIDs = [[NSMutableOrderedSet alloc] init];
        _fieldIDs = fieldIDs;
        
        NSMutableDictionary <NSNumber *, MADModelField *> *fields;
        fields = [[NSMutableDictionary alloc] init];
        _fields = fields;
        
        [self update];
    }
    return _fieldIDs;
}

- (NSDictionary <NSNumber *, MADModelField *> *)fields {
    if (_fields.count == 0) {
        
        NSMutableOrderedSet <NSNumber *> *fieldIDs;
        fieldIDs = [[NSMutableOrderedSet alloc] init];
        _fieldIDs = fieldIDs;

        NSMutableDictionary <NSNumber *, MADModelField *> *fields;
        fields = [[NSMutableDictionary alloc] init];
        _fields = fields;
        
        [self update];
    }
    return _fields;
}

- (void)update {
    NSManagedObjectContext *managedObjectContext = _managedObjectContext;
    
    NSError * __autoreleasing error = NULL;
    NSArray <NSDictionary *> *results;
    NSFetchRequest *fetchQueryTable;
    NSString *entityName = NSStringFromClass([RptqDatabaseSchemaField class]);
    NSUInteger expressionCount;
    
    void (^setupExpressionWithType)(NSExpressionDescription *, NSString *, NSExpression *, NSAttributeType) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression, NSAttributeType type) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = type;
    };
    
    entityName = NSStringFromClass([RptqDatabaseSchemaField class]);
    
    expressionCount = 7;
    NSExpressionDescription *expressionDescription[expressionCount];
    
    NSString *keyName, *keyPrimaryKey, *keyDataType, *keyDataTypeNative, *keyDecimals, *keyWidth,
             *keyIdentifier, *keyInTableIdentifier;
    
    keyName = NSStringFromSelector(@selector(name));
    keyPrimaryKey = NSStringFromSelector(@selector(primaryKey));
    keyDataType = NSStringFromSelector(@selector(dataType));
    keyDataTypeNative = NSStringFromSelector(@selector(dataTypeNative));
    keyDecimals = NSStringFromSelector(@selector(decimals));
    keyWidth = NSStringFromSelector(@selector(width));
    keyIdentifier = NSStringFromSelector(@selector(identifier));
    keyInTableIdentifier = NSStringFromSelector(@selector(inTable));
    keyInTableIdentifier = [keyInTableIdentifier stringByAppendingPeriod];
    keyInTableIdentifier = [keyInTableIdentifier stringByAppendingString:keyIdentifier];

    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSExpression *expressionForName =           [NSExpression expressionForKeyPath:keyName],
                 *expressionForPrimaryKey =     [NSExpression expressionForKeyPath:keyPrimaryKey],
                 *expresssionForDataType =      [NSExpression expressionForKeyPath:keyDataType],
                 *expressionForDataTypeNative = [NSExpression expressionForKeyPath:keyDataTypeNative],
                 *expressionForDecimals =       [NSExpression expressionForKeyPath:keyDecimals],
                 *expressionForWidth =          [NSExpression expressionForKeyPath:keyWidth],
                 *expressionForIdentifier =     [NSExpression expressionForKeyPath:keyIdentifier];
    
    setupExpressionWithType(expressionDescription[0],
                            keyName,
                            expressionForName,
                            NSStringAttributeType);
    setupExpressionWithType(expressionDescription[1],
                            keyPrimaryKey,
                            expressionForPrimaryKey,
                            NSBooleanAttributeType);
    setupExpressionWithType(expressionDescription[2],
                            keyDataType,
                            expresssionForDataType,
                            NSInteger16AttributeType);
    setupExpressionWithType(expressionDescription[3],
                            keyDataTypeNative,
                            expressionForDataTypeNative,
                            NSInteger16AttributeType);
    setupExpressionWithType(expressionDescription[4],
                            keyDecimals,
                            expressionForDecimals,
                            NSInteger16AttributeType);
    setupExpressionWithType(expressionDescription[5],
                            keyWidth,
                            expressionForWidth,
                            NSInteger64AttributeType);
    setupExpressionWithType(expressionDescription[6],
                            keyIdentifier,
                            expressionForIdentifier,
                            NSInteger64AttributeType);

    NSArray <NSExpressionDescription *> *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects: expressionDescription
                                                   count: expressionCount];
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    fetchQueryTable.resultType = NSDictionaryResultType;
    
    NSPredicate *predicate;
    NSExpression *predicateExpression[2];
    
    NSNumber *identifierObject = @(self.identifier);
    predicateExpression[0] = [NSExpression expressionForKeyPath: keyInTableIdentifier];
    predicateExpression[1] = [NSExpression expressionForConstantValue: identifierObject];
    
    predicate = [NSComparisonPredicate predicateWithLeftExpression: predicateExpression[0]
                                                   rightExpression: predicateExpression[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    fetchQueryTable.predicate = predicate;
    
    NSSortDescriptor *sortByFieldName = [[NSSortDescriptor alloc] initWithKey: keyName
                                                                    ascending: YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortByFieldName, nil];
    fetchQueryTable.sortDescriptors = sortDescriptors;

    results = [managedObjectContext executeFetchRequest:fetchQueryTable error:&error];

    
    NSMutableOrderedSet <NSNumber *> *fieldIDs = [[NSMutableOrderedSet alloc] init];
    NSMutableDictionary <NSNumber *, MADModelField *> *fields = [[NSMutableDictionary alloc] init];
    
    NSDictionary *result;
    NSNumber *primaryKey, *dataType, *dataTypeNative, *decimals, *width, *identifier;
    NSString *name;

    MADModelField *field;
    for (result in results) {
        primaryKey = [result objectForKey:keyPrimaryKey];
        dataType = [result objectForKey:keyDataType];
        dataTypeNative = [result objectForKey:keyDataTypeNative];
        decimals = [result objectForKey:keyDecimals];
        width = [result objectForKey:keyWidth];
        name = [result objectForKey:keyName];
        identifier = [result objectForKey:keyIdentifier];
        field = [[MADModelField alloc] initWithIdentifier: identifier.longLongValue
                                             isPrimaryKey: primaryKey.boolValue
                                                 dataType: dataType.shortValue
                                           dataTypeNative: dataTypeNative.shortValue
                                                 decimals: decimals.shortValue
                                                    width: width.longLongValue
                                                     name: name];
        [fieldIDs addObject:identifier];
        [fields setObject:field forKey:identifier];
        
    }
    _fields = fields;
    _fieldIDs = fieldIDs;
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
    }
    predicateExpression[0] = nil;
    predicateExpression[1] = nil;

}

/*- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Name:\t%@", _name];
    [debug appendFormat:@"Field:\t%@", self.fields];
    return debug;
}*/

@end
