//
//  MADModelQueryTable.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelQueryTable.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSExpressionDescription.h>

#import <Foundation/NSExpression.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSURL.h>

#import "MADModelQueryField.h"

#import "RptqQueryTable.h"
#import "RptqQueryField.h"

@interface MADModelQueryTable ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                         schemaTable:(NSManagedObjectID *)schemaTable
               schemaTableIdentifier:(int64_t)schemaTableIdentifier
                            capacity:(NSUInteger)capacity;
    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
    - (void)addField:(NSManagedObjectID *)fieldID fieldIdentifier:(int64_t)fieldIdentifier
         schemaField:(NSManagedObjectID *)schemaField schemaFieldIdentifier:(int64_t) schemaFieldIdentifier;
@end

@implementation MADModelQueryTable {
    NSManagedObjectID *_schemaTable;
    NSMutableOrderedSet <NSManagedObjectID *> *_fieldIDs;
    NSMutableDictionary <NSManagedObjectID *, MADModelQueryField *> *_fields;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) { }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                     schemaTable:(NSManagedObjectID *)schemaTable
           schemaTableIdentifier:(int64_t)schemaTableIdentifier
                        capacity:(NSUInteger)capacity {
    
    if (self = [self initWithObjectID:objectID identifier:identifier]) {
        _schemaTable = schemaTable.copy;
        
        id fields;
        @autoreleasepool {
            fields = [[NSMutableDictionary alloc] init];
            _fields = fields;
            fields = nil;
        }
        @autoreleasepool {
            fields = [[NSMutableOrderedSet alloc] initWithCapacity:capacity];
            _fieldIDs = fields;
            fields = nil;
            
        }
        
    }
    return self;
}

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate {
    
    NSFetchRequest *fetchQueryTable;
    NSString *entityName;
    entityName = NSStringFromClass([RptqQueryField class]);
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSString *keyPathInQueryTable = NSStringFromSelector(@selector(inQueryTable));
    NSString *keyPathDatabaseSchemaTable = NSStringFromSelector(@selector(databaseSchemaTable));
    NSString *keyPathDatabaseSchemaField = NSStringFromSelector(@selector(databaseSchemaField));
    NSString *keyPathName = NSStringFromSelector(@selector(name));
    NSString *keyPathFieldName = [keyPathDatabaseSchemaField stringByAppendingString:@"."];
    keyPathFieldName = [keyPathFieldName stringByAppendingString:keyPathName];
    
    NSString *keyPathTableName = [keyPathInQueryTable stringByAppendingString:@"."];
    keyPathTableName = [keyPathTableName stringByAppendingString: keyPathDatabaseSchemaTable];
    keyPathTableName = [keyPathTableName stringByAppendingString:@"."];
    keyPathTableName = [keyPathTableName stringByAppendingString:keyPathName];
    
    NSString *keyPathSchemaTable = [keyPathInQueryTable stringByAppendingString: @"."];
    keyPathSchemaTable = [keyPathSchemaTable stringByAppendingString: keyPathDatabaseSchemaTable];
    
    NSUInteger expressionCount = 10;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSString *keys[] = {
        MADKeyQueryField,
        MADKeyQueryTable,
        MADKeySchemaFieldName,
        MADKeySchemaTableName,
        MADKeySchemaTable,
        MADKeySchemaField,
        
        MADKeyQueryTableID,
        MADKeyQueryFieldID,
        MADKeySchemaTableID,
        MADKeySchemaFieldID
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
        [NSExpression expressionForEvaluatedObject],
        [NSExpression expressionForKeyPath: keyPathInQueryTable],
        [NSExpression expressionForKeyPath: keyPathFieldName],
        [NSExpression expressionForKeyPath: keyPathTableName],
        [NSExpression expressionForKeyPath: keyPathSchemaTable],
        [NSExpression expressionForKeyPath: keyPathDatabaseSchemaField],
        
        [NSExpression expressionForKeyPath: keyQueryTableID],
        [NSExpression expressionForKeyPath: keyQueryFieldID],
        [NSExpression expressionForKeyPath: keySchemaTableID],
        [NSExpression expressionForKeyPath: keySchemaFieldID]
    };

    NSAttributeType types[] = {
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        NSObjectIDAttributeType,
        
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSInteger64AttributeType,
        NSInteger64AttributeType
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

- (void)addField:(NSManagedObjectID *)fieldID
 fieldIdentifier:(int64_t)fieldIdentifier
     schemaField:(NSManagedObjectID *)schemaField
schemaFieldIdentifier:(int64_t) schemaFieldIdentifier {
    
    NSManagedObjectID *_fieldID = fieldID, *_schemaField = schemaField;
    
    MADModelQueryField *queryField;
    queryField = [[MADModelQueryField alloc] initWithObjectID: _fieldID
                                                   identifier: fieldIdentifier
                                                  schemaField: _schemaField
                                        schemaFieldIdentifier: schemaFieldIdentifier];
    [_fieldIDs addObject:_fieldID];
    [_fields setObject:queryField forKey:_fieldID];

}

/*- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = self.objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@>",
     NSStringFromClass([self class]),
     self.objectID.URIRepresentation.pathComponents[1],
     self.objectID.URIRepresentation.pathComponents[2]] :
    self.debugDescription;
    return debugDescription;
}*/

@end
