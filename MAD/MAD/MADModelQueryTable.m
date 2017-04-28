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

#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSURL.h>

#import "madlib.h"

#import "MADModelDatabase.h"
#import "MADModelTable.h"
#import "MADModelQueryField.h"

#import "RptqQueryTable.h"
#import "RptqQueryField.h"

@interface MADModelQueryTable ()
    @property (readwrite, nonatomic, strong) NSMutableDictionary <NSNumber *, MADModelQueryField *> *queryFields;
    @property (readwrite, nonatomic, strong) NSMutableOrderedSet <NSNumber *> *queryFieldIDs;
@end

@implementation MADModelQueryTable {
    MADModelDatabase __weak *_database;
    int64_t _schemaTable;
    int64_t _dropIndex;
}

@dynamic schemaTable;

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate {
    
    NSFetchRequest *fetchQueryTable;
    NSString *entityName;
    entityName = NSStringFromClass([RptqQueryField class]);
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSString *keyPathInQueryTable = NSStringFromSelector(@selector(inQueryTable));
    
    NSString *keyPathDropIndex = NSStringFromSelector(@selector(dropIndex));
    NSString *keyPathInQueryTableDropIndex = [keyPathInQueryTable stringByAppendingString:@"."];
    keyPathInQueryTableDropIndex = [keyPathInQueryTableDropIndex stringByAppendingString:keyPathDropIndex];
    
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
    
    NSUInteger expressionCount = 11;
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
        MADKeySchemaFieldID,
        keyPathInQueryTableDropIndex
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
        [NSExpression expressionForKeyPath: keySchemaFieldID],
        [NSExpression expressionForKeyPath: keyPathInQueryTableDropIndex],
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
        //MADKeyQueryField,
        //MADKeyQueryTable,
        //MADKeySchemaFieldName,
        //MADKeySchemaTableName,
        //MADKeySchemaTable,
        //MADKeySchemaField,
        
        MADKeyQueryTableID,
        //MADKeyQueryFieldID,
        MADKeySchemaTableID,
        //MADKeySchemaFieldID
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
        //[NSExpression expressionForEvaluatedObject],
        //[NSExpression expressionForKeyPath: keyPathInQueryTable],
        //[NSExpression expressionForKeyPath: keyPathFieldName],
        //[NSExpression expressionForKeyPath: keyPathTableName],
        //[NSExpression expressionForKeyPath: keyPathSchemaTable],
        //[NSExpression expressionForKeyPath: keyPathDatabaseSchemaField],
        
        [NSExpression expressionForKeyPath: keyIdentifier],//  keyQueryTableID],
        //[NSExpression expressionForKeyPath: keyQueryFieldID],
        [NSExpression expressionForKeyPath: keyPathDatabaseSchemaTable],// keySchemaTableID],
        //[NSExpression expressionForKeyPath: keySchemaFieldID]
    };
    
    NSAttributeType types[] = {
        //NSObjectIDAttributeType,
        //NSObjectIDAttributeType,
        //NSObjectIDAttributeType,
        //NSObjectIDAttributeType,
        //NSObjectIDAttributeType,
        //NSObjectIDAttributeType,
        
        NSInteger64AttributeType,
        //NSInteger64AttributeType,
        NSInteger64AttributeType,
        //NSInteger64AttributeType
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

- (void)dealloc {
    _inQuery = nil;
}

- (instancetype)initWithIdentifier:(int64_t)identifier {
    if (self = [super initWithIdentifier:identifier]) { }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
                         dropIndex:(int64_t)dropIndex
                       schemaTable:(int64_t)schemaTable
                        inDatabase:(MADModelDatabase *)inDatabase {
    
    if (self = [self initWithIdentifier:identifier]) {
        _database = inDatabase;
        _schemaTable = schemaTable;
        _dropIndex = dropIndex;
        NSMutableDictionary *fields;
        fields = [[NSMutableDictionary alloc] init];
        self.queryFields = fields;
        
        NSMutableOrderedSet *fieldIDs;
        fieldIDs = [[NSMutableOrderedSet alloc] init];
        self.queryFieldIDs = fieldIDs;
        
    }
    return self;
}

- (NSMutableOrderedSet <NSNumber *> *)queryFieldIDs {
    if (_queryFieldIDs.count == 0) {
        [self updateFields];
    }
    return _queryFieldIDs;
}

- (NSMutableDictionary <NSNumber *, MADModelQueryField *> *)queryFields {
    if (_queryFields.count == 0) {
        [self updateFields];
    }
    return _queryFields;
}

- (void)updateFields {
    
}

- (void)addField:(int64_t)fieldIdentifier
     schemaField:(int64_t)schemaField {
        
    MADModelQueryField *queryField;
    queryField = [[MADModelQueryField alloc] initWithIdentifier: fieldIdentifier
                                                    schemaTable: _schemaTable
                                                    schemaField: schemaField
                                                       database: _database];
    NSNumber *fieldID = @(fieldIdentifier);
    [self.queryFieldIDs addObject:fieldID];
    [self.queryFields setObject:queryField forKey:fieldID];

}

- (int64_t)schemaTable {
    return _schemaTable;
}

- (NSString *)databaseSchemaTableName {
    NSNumber *key = @(_schemaTable);
    return [_database.tableDictionary objectForKey:key].name;
}

- (NSString *)alias {
    return _dropIndex == 0 ? [self databaseSchemaTableName] : [self queryAlias];
}

- (NSString *)queryAlias {
    char buf[22]; char *ptr;
    ltoa(_dropIndex, buf);
    ptr = buf;
    NSString *indexString = [[NSString alloc] initWithCString:ptr encoding:NSUTF8StringEncoding];
    return [[self databaseSchemaTableName] stringByAppendingString:indexString];
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    
    debugDescription = [[NSString alloc] initWithFormat:@"%@ <%@::%@>",
                                                NSStringFromClass([self class]),
                                                self.objectID,
                                                self.queryFieldIDs];
    return debugDescription;
}

@end
