//
//  MADModel.m
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModel.h"
#import <CoreFoundation/CFTree.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedPropertyDescription.h>
#import <CoreData/NSPropertyDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSAttributeDescription.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSOperation.h>
#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

/*struct MADTableFieldIndex {
    NSUInteger table;
    NSUInteger field;
};
typedef struct MADTableFieldIndex MADTableFieldIndex;

static inline MADTableFieldIndex MADTableFieldIndexMake(NSUInteger, NSUInteger);
static inline MADTableFieldIndex MADTableFieldIndexMake(NSUInteger table, NSUInteger field) {
    MADTableFieldIndex tableFieldIndex;
    tableFieldIndex.table = table;
    tableFieldIndex.field = field;
    return tableFieldIndex;
}*/

NSString * const MADNotificationDeleteQueryLink = @"MADNotificationDeleteQueryLink";
NSString * const MADKeyQuery = @"MADKeyQuery";
NSString * const MADKeyQueryLink = @"MADKeyLink";

@implementation MADTableFieldReference

- (instancetype)init {
    if (self = [self initWithTableID:nil andFieldID:nil]) {
    }
    return self;
}

- (instancetype)initWithTableID:(NSManagedObjectID *)tableID
                     andFieldID:(NSManagedObjectID *)fieldID {
    if (self = [super init]) {
        _tableID = tableID.copy;
        _fieldID = fieldID.copy;
    }
    return self;
}

@end

@interface MADObjectID ()
    - (instancetype)newObjectIDDocument:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelDocument ()
    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readwrite, strong) NSMutableOrderedSet <MADModelDatabase *> *databases;
@end

@interface MADModelDatabase ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                             queryID:(NSManagedObjectID *)queryID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelTable ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                                name:(NSString *)name;
    - (void)addFieldWithID:(NSManagedObjectID *)objectID
                      name:(NSString *)name
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelField ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                                name:(NSString *)name;

@end

@interface MADModelQuery ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                            database:(MADModelDatabase *)database;
    @property (nonatomic, weak, readonly) MADModelDatabase *database;
- (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink;
@end

@interface MADModelQueryTable ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         schemaTable:(NSManagedObjectID *)schemaTable
                            capacity:(NSUInteger)capacity;
    - (void)addField:(NSManagedObjectID *)fieldID schemaField:(NSManagedObjectID *)schemaField;
@end

@interface MADModelQueryField ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         schemaField:(NSManagedObjectID *)schemaField;
@end

@interface MADModelQueryLink ()

    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         leftFieldID:(NSManagedObjectID *)leftFieldID
                         leftTableID:(NSManagedObjectID *)leftTableID
                        rightFieldID:(NSManagedObjectID *)rightFieldID
                        rightTableID:(NSManagedObjectID *)rightTableID;
    - (NSSet <MADTableFieldReference *> *)tableFieldReferences;
    - (NSSet <NSManagedObjectID *> *)tables;

@end

#pragma mark -
#pragma mark MAD Object ID

@implementation MADObjectID {
  @protected
    NSManagedObjectID *_objectID;
}

    @synthesize objectID = _objectID;

- (instancetype)newObjectIDDocument:(NSManagedObjectContext *)managedObjectContext {
    return [[MADModelDocument alloc] initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID {
    if (self = [super init]) {
        _objectID = objectID.copy;
    }
    return self;
}

- (NSUInteger)hash {
    return _objectID.hash * 2654435761U;
}

- (BOOL)isEqual:(id)object {

    return (self == object || (object != nil &&
            [object isKindOfClass:[self class]] &&
            ((typeof(self))object).objectID != nil &&
            [((typeof(self))object).objectID isEqual:_objectID]));
    
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
                            [[NSString alloc] initWithFormat:@"%@ <%@::%@> %@, %@, $@, %@",
                             NSStringFromClass([self class]),
                             _objectID.URIRepresentation.pathComponents[1],
                             _objectID.URIRepresentation.pathComponents[2],
                             _objectID.URIRepresentation.absoluteString,
                             _objectID.URIRepresentation.relativeString,
                             _objectID.URIRepresentation.dataRepresentation] :
                            self.debugDescription;
    return debugDescription;
}

@end

#pragma mark -
#pragma mark MAD Document Object ID

@implementation MADModelDocument {
  @protected
    NSOperationQueue *_objectContextQueue;
    NSManagedObjectContext * __weak _managedObjectContext;
}
    @synthesize managedObjectContext = _managedObjectContext;

- (instancetype)init {
    if (self = [self initWithObjectID: nil
                 managedObjectContext: nil]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [self initWithManagedObjectContext:managedObjectContext]) {
        _objectID = objectID.copy;
    }
    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super init]) {
        
        NSOperationQueue *objectContextQueue;
        objectContextQueue = [[NSOperationQueue alloc] init];
        objectContextQueue.qualityOfService = NSOperationQualityOfServiceUserInitiated;
        
        __typeof(self) __weak wself = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                                          object:managedObjectContext
                                                           queue:_objectContextQueue
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          
                                                          //void(^displayObject)(id) = ^void(id obj) {
                                                          //    NSLog(@"[%@] %@", [obj class], obj);
                                                          //};
                                                          NSLog(@"%@: %@", NSStringFromClass(note.class), note);
                                                          id keys = note.userInfo.keyEnumerator;
                                                          id objects = note.userInfo.objectEnumerator;
                                                          
                                                          //NSManagedObjectContext *objectContext;
                                                          NSSet *deletedObjects;
                                                          NSSet *updatedObjects;
                                                          NSSet *insertedObjects;
                                                          NSSet *invalidatedObjects;
                                                          deletedObjects = [note.userInfo objectForKey:NSDeletedObjectsKey];
                                                          [deletedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                                                              if ([obj isKindOfClass:[RptqQueryLinks class]]) {
                                                                  typeof(self) sself = wself;
                                                                  MADModelQuery *query = sself.firstQuery;
                                                                  [query deleteQueryLinkID:((NSManagedObject *)obj).objectID];
                                                              }
                                                          }];
                                                          updatedObjects = [note.userInfo objectForKey:NSUpdatedObjectsKey];
                                                          insertedObjects = [note.userInfo objectForKey:NSInsertedObjectsKey];
                                                          invalidatedObjects = [note.userInfo objectForKey:NSInvalidatedObjectsKey];
                                                          for (id key in keys) {
                                                              NSLog(@"[%@] %@", NSStringFromClass([key class]), key);
                                                              
                                                          }
                                                          for (id object in objects) {
                                                              NSLog(@"[%@] %@", NSStringFromClass([object class]), object);
                                                          }
                                                          NSLog(@"%@", NSInsertedObjectsKey);
                                                          NSLog(@"%@", NSUpdatedObjectsKey);
                                                          NSLog(@"%@", NSRefreshedObjectsKey);
                                                          NSLog(@"%@", NSDeletedObjectsKey);
                                                          NSLog(@"%@", NSInvalidatedObjectsKey);
                                                          NSLog(@"%@", NSManagedObjectContextQueryGenerationKey);
                                                          //displayObject(note.object[NSInsertedObjectsKey]);
                                                          //displayObject(note.object[NSUpdatedObjectsKey]);
                                                          //displayObject(note.object[NSDeletedObjectsKey]);
                                                          //displayObject(note.object[NSRefreshedObjectsKey]);
//                                                          displayObject(note.object[NSInvalidatedObjectsKey]);
//                                                          displayObject(note.object[NSManagedObjectContextQueryGenerationKey]);
//                                                          displayObject(note.object[NSInvalidatedAllObjectsKey]);
                                                          
                                                          
                                                      }];

        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextWillSaveNotification
                                                          object:managedObjectContext
                                                           queue:_objectContextQueue
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          NSLog(@"%@: %@", NSStringFromClass(note.class), note);
                                                      }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                          object:managedObjectContext
                                                           queue:_objectContextQueue
                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                          NSLog(@"%@: %@", NSStringFromClass(note.class), note);
                                                      }];
        
        _objectContextQueue = objectContextQueue;
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (NSMutableOrderedSet <MADModelDatabase *> *)databases {
    if (!_databases) {
        [self update];
    }
    return _databases;
}

- (NSManagedObjectID *)objectID {
    if (!_objectID) {
        [self update];
    }
    return _objectID;
}

- (MADModelDatabase *)firstDatabase {
    return self.databases.firstObject;
}

- (MADModelQuery *)firstQuery {
    return self.firstDatabase.firstQuery;
}

- (void)update {
    @autoreleasepool {
        [self updateDocumentDatabaseQuery];
    }
}

//Load all the databases and queries for this document.  This is because current versions
// of the software only use one database and query.

- (void)updateDocument {
    NSFetchRequest *request;
    request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    request.fetchLimit = 1;
    request.resultType = NSManagedObjectIDResultType;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    NSError * __autoreleasing *error = NULL;
    NSArray <NSManagedObjectID *> *result;
    result = [_managedObjectContext executeFetchRequest:request error:error];
    _objectID = result.firstObject.copy;
}

- (void)updateDocumentDatabaseQuery {
    NSArray <NSManagedObjectID *> *result;
    NSFetchRequest *request;
    
    void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = NSManagedObjectIDResultType;
    };
    
    int expressionCount = 3;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSManagedObjectContext *managedObjectContext;
    managedObjectContext = _managedObjectContext;
    
    for (int i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    
    NSString *keyDatabase = @"DA", *keyQuery = @"QU", *keyDocument = @"DO";
    
    NSString *inDatabase = NSStringFromSelector(@selector(inDatabase));
    NSString *inDocument = NSStringFromSelector(@selector(ownedByQueryAsStaticResource));
    NSString *inDatabaseInDocumentKeyPath = [NSString stringWithFormat:@"%@.%@", inDatabase, inDocument];
    
    NSExpression *databaseExpression = [NSExpression expressionForKeyPath:inDatabase];
    NSExpression *databaseInDocumentExpression = [NSExpression expressionForKeyPath:inDatabaseInDocumentKeyPath];
    NSExpression *selfExpresssion = [NSExpression expressionForEvaluatedObject];
    
    setupExpression(expressionDescription[0], keyDatabase, databaseExpression);
    setupExpression(expressionDescription[1], keyDocument, databaseInDocumentExpression);
    setupExpression(expressionDescription[2], keyQuery, selfExpresssion);
    
    request.resultType = NSDictionaryResultType;
    NSError * __autoreleasing *error = NULL;
    
    NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects:
                                                            expressionDescription[0],
                                                            expressionDescription[1],
                                                            expressionDescription[2], nil];
    request.propertiesToFetch = propertiesToFetch;
    result = [managedObjectContext executeFetchRequest:request error:error];
    
    
    NSMutableOrderedSet <MADModelDatabase *> *databases;
    databases = [[NSMutableOrderedSet <MADModelDatabase *> alloc] initWithCapacity:result.count];
    
    MADModelDatabase *database;
    NSUInteger resultCount = 0;
    
    NSDictionary <NSString *, NSManagedObjectID *> *resultWrapper;
    for (resultWrapper in result) {
        if (resultCount == 0) {
            _objectID = resultWrapper[keyDocument].copy;
        }
        database = [[MADModelDatabase alloc] initWithObjectID: resultWrapper[keyDatabase]
                                                      queryID: resultWrapper[keyQuery]
                                         managedObjectContext: managedObjectContext];
        [databases addObject: database];
        database = nil;
        resultCount++;
    }
    
    for (int i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
    }
    
    inDatabase = nil;
    inDocument = nil;
    
    _databases = databases;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Databases:\t%@", self.databases];
    return debug;
}

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
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         queryID:(NSManagedObjectID *)queryID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    if (self = [super initWithObjectID:objectID]) {
        _managedObjectContext = managedObjectContext;
        MADModelQuery *queryObjectID;
        
        NSMutableOrderedSet <MADModelQuery *> *queries;
        queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];

        queryObjectID = [[MADModelQuery alloc] initWithObjectID:queryID
                                                       database:self];
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
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];
    
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
        NSOrderedSet *tableObjectIDs = [[NSOrderedSet alloc] initWithArray: tableValues copyItems:NO];
        
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
                                                               name: filteredResults.firstObject[keyTableName]];
                    [tables addObject:table];
                    for (attributes in filteredResults) {
                        [table addFieldWithID:attributes[keyField]
                                         name:attributes[keyFieldName]
                         managedObjectContext:managedObjectContext];
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
    
    expression[1] = [NSExpression expressionForConstantValue:_objectID];
    
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

#pragma mark -
#pragma mark MADModelTable

@implementation MADModelTable {
    NSString *_name;
    NSMutableOrderedSet <MADModelField *> *_fields;
}

@synthesize fields = _fields;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID {
    if (self = [super initWithObjectID:objectID]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                            name:(NSString *)name {
    if (self = [self initWithObjectID:objectID]) {
        _name = name.copy;
    }
    return self;
}

- (NSString *)name {
    if (_name == nil) {
        
    }
    return _name;
}

- (NSOrderedSet <MADModelField *> *)fields {
    if (_fields == nil) {
        NSMutableOrderedSet *fields = [[NSMutableOrderedSet alloc] init];
        _fields = fields;
    }
    return _fields;
}

- (void)addFieldWithID:(NSManagedObjectID *)objectID
                  name:(NSString *)name
  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    if (_fields == nil) {
        NSMutableOrderedSet *fields = [[NSMutableOrderedSet alloc] init];
        _fields = fields;
    }
    id field = [[MADModelField alloc] initWithObjectID: objectID
                                                  name: name];
    [_fields addObject:field];
}

- (void)update {
    
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Name:\t%@", _name];
    [debug appendFormat:@"Field:\t%@", self.fields];
    return debug;
}

@end

#pragma mark -
#pragma mark MADModelField

@implementation MADModelField {
    NSString *_name;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID {
    if (self = [super initWithObjectID:objectID]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                            name:(NSString *)name {
    if (self = [self initWithObjectID:objectID]) {
        _name = name.copy;
    }
    return self;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Name:\t%@", _name];
    return debug;
}

@end

#pragma mark -
#pragma mark MADModelQuery

@implementation MADModelQuery {
  @protected
    NSMutableOrderedSet <NSManagedObjectID *> *_queryTableIDs;
    NSMutableOrderedSet <NSManagedObjectID *> *_queryLinkIDs;
    NSMapTable <NSManagedObjectID *, MADModelQueryTable *> *_tables;
    NSMapTable <NSManagedObjectID *, MADModelTable *> *_tableSchemas;
    NSMapTable <NSManagedObjectID *, MADModelQueryLink *> *_links;
    MADModelDatabase __weak *_database;
  @protected
    NSManagedObjectContext * __weak _managedObjectContext;
}
    @synthesize managedObjectContext = _managedObjectContext;

- (void)dealloc {
    _database = nil;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                        database:(MADModelDatabase *)database {
    if (self = [self initWithObjectID: objectID
                 managedObjectContext: database.managedObjectContext]) {
        _database = database;
    }
    return self;
}

- (NSOrderedSet <NSManagedObjectID *> *)queryTableIDs {
    if (_queryTableIDs == nil) {
        @autoreleasepool {
            [self updateTables];
        }
    }
    return _queryTableIDs;
}

- (NSOrderedSet <NSManagedObjectID *> *)queryLinkIDs {
    if (_queryLinkIDs == nil) {
        @autoreleasepool {
            [self updateLinks];
        }
    }
    return _queryLinkIDs;
}

- (NSMapTable <NSManagedObjectID *, MADModelQueryTable *> *)tables {
    if (_tables == nil) {
        @autoreleasepool {
            [self updateTables];
        }
    }
    return _tables;
}

- (NSMapTable <NSManagedObjectID *, MADModelQueryLink *> *)links {
    if (_links == nil) {
        @autoreleasepool {
            [self updateLinks];
        }
    }
    return _links;
}

- (NSSet <MADTableFieldReference *> *)tableFieldReferencesInLinks {
    NSEnumerator <MADModelQueryLink *> *links = _links.objectEnumerator;
    MADModelQueryLink *link;
    NSSet *tablesInLinks;
    tablesInLinks = [[NSMutableSet alloc] initWithCapacity:_links.count * 2];
    for (link in links) {
        tablesInLinks = [tablesInLinks setByAddingObjectsFromSet: link.tableFieldReferences];
        
    }
    return tablesInLinks;
}

- (NSSet <NSManagedObjectID *> *)tablesInLinks {
    NSEnumerator <MADModelQueryLink *> *links = _links.objectEnumerator;
    MADModelQueryLink *link;
    NSSet *tablesInLinks;
    tablesInLinks = [[NSMutableSet alloc] initWithCapacity:_links.count * 2];
    for (link in links) {
        tablesInLinks = [tablesInLinks setByAddingObjectsFromSet: link.tables];
        
    }
    return tablesInLinks;
}


- (NSSet <NSManagedObjectID *> *)orphanedQueryTables {
    NSSet <NSManagedObjectID *> *orphanedQueryTables;
    NSExpression *expressionMinusSet;
    NSSet <NSManagedObjectID *> * joinedTables = [self tablesInLinks];
    NSExpression *evaluatedObject = [NSExpression expressionForEvaluatedObject];
    NSExpression *evaluatedJoinedTables = [NSExpression expressionForConstantValue:joinedTables];
    expressionMinusSet = [NSExpression expressionForMinusSet: evaluatedObject
                                                        with: evaluatedJoinedTables];
    
    orphanedQueryTables = [expressionMinusSet expressionValueWithObject: self.queryTableIDs
                                                                context: nil];
    
    return orphanedQueryTables;
}

- (void)updateTables {
    NSManagedObjectContext *managedObjectContext = _managedObjectContext;
    
    NSError * __autoreleasing *error = NULL;
    NSArray <NSManagedObjectID *> *fetchQueryTableResults;
    
    void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = NSManagedObjectIDResultType;
        
    };
    
    NSUInteger expressionCount = 6;
    NSUInteger expressionInQueryCount = 8;

    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionInQuery[expressionInQueryCount];
    expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inQueryTable.inQuery"];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];
    
    NSPredicate *predicateInQuery;
    predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                          rightExpression: expressionInQuery[1]
                                                                 modifier: NSDirectPredicateModifier
                                                                     type: NSEqualToPredicateOperatorType
                                                                  options: 0];
    
    NSFetchRequest *fetchQueryTable;
    NSString *keyQT = @"QT", *keyQF = @"QF", *keySFN = @"SFN", *keySTN = @"STN", *keyST = @"ST", *keySF = @"SF";

    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryField class])];
    expressionInQuery[2] = [NSExpression expressionForEvaluatedObject];
    expressionInQuery[3] = [NSExpression expressionForKeyPath:@"inQueryTable"];
    expressionInQuery[4] = [NSExpression expressionForKeyPath:@"databaseSchemaField.name"];
    expressionInQuery[5] = [NSExpression expressionForKeyPath:@"inQueryTable.databaseSchemaTable.name"];
    expressionInQuery[6] = [NSExpression expressionForKeyPath:@"inQueryTable.databaseSchemaTable"];
    expressionInQuery[7] = [NSExpression expressionForKeyPath:@"inQueryTable.databaseSchemaTable"];
    setupExpression(expressionDescription[0], keyQF, expressionInQuery[2]);
    setupExpression(expressionDescription[1], keyQT, expressionInQuery[3]);
    setupExpression(expressionDescription[2], keySFN, expressionInQuery[4]);
    setupExpression(expressionDescription[3], keySTN, expressionInQuery[5]);
    setupExpression(expressionDescription[4], keyST, expressionInQuery[6]);
    setupExpression(expressionDescription[5], keySF, expressionInQuery[7]);
    
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:(NSUInteger)expressionCount];
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    fetchQueryTable.resultType = NSDictionaryResultType;
    fetchQueryTable.predicate = predicateInQuery;
    
    fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    NSAssert(error == nil, @"What? %@", *error);
    
    NSArray *tableValues = [fetchQueryTableResults valueForKey:keyQT];
    
    NSOrderedSet *tableObjectIDs;
    tableObjectIDs = [[NSOrderedSet alloc] initWithArray: tableValues copyItems:NO];
    
    
    NSComparisonPredicate *predicateTable;
    NSExpression *tablePath = [NSExpression expressionForKeyPath: keyQT],
    *tableValue;
    NSArray *fresults;
    @autoreleasepool {
        NSMapTable <NSManagedObjectID *, MADModelQueryTable *> *tables;
        tables = [[NSMapTable alloc] initWithKeyOptions: NSPointerFunctionsWeakMemory
                                           valueOptions: NSPointerFunctionsStrongMemory
                                               capacity: tableObjectIDs.count];
        NSMutableOrderedSet <NSManagedObjectID *> *tableIDs;
        tableIDs = [[NSMutableOrderedSet alloc] initWithCapacity:tableObjectIDs.count];
        
        NSManagedObjectID *tableObjectID;
        for (tableObjectID in tableObjectIDs) {
            
            @autoreleasepool {
                
                tableValue = [NSExpression expressionForConstantValue: tableObjectID];
                predicateTable = [NSComparisonPredicate predicateWithLeftExpression: tablePath
                                                                    rightExpression: tableValue
                                                                           modifier: NSDirectPredicateModifier
                                                                               type: NSEqualToPredicateOperatorType
                                                                            options: 0];
                fresults = [fetchQueryTableResults filteredArrayUsingPredicate:predicateTable];
                
                //NSManagedObjectID *schemaTable;
                NSDictionary *filteredResult = fresults.firstObject;
                
                MADModelQueryTable *queryTable;
                queryTable = [[MADModelQueryTable alloc] initWithObjectID: tableObjectID
                                                              schemaTable: filteredResult[keyST]
                                                                 capacity: fresults.count];
                
                for (filteredResult in fresults) {
                    [queryTable addField: filteredResult[keyQF]
                             schemaField: filteredResult[keySF]];
                }
                NSManagedObjectID *tableID = tableObjectID.copy;
                [tableIDs addObject:tableID];
                [tables setObject:queryTable forKey:tableID];
                tableID = nil;
            }
        }
        _tables = tables;
        _queryTableIDs = tableIDs;
    }
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
    }
    for (NSUInteger i=0; i<expressionInQueryCount; i++) {
        expressionInQuery[i] = nil;
    }

}

// Fetches the needed data from RptqQueryLinks.
// It creates MADModelQueryLink objects.
- (void)updateLinks {
    NSArray <NSManagedObjectID *> *fetchQueryLinksResults;
    NSFetchRequest *fetchQueryLinks;

    NSUInteger expressionDescCount = 6;
    NSExpressionDescription *expressionDescription[expressionDescCount];

    fetchQueryLinks = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];
    NSExpression *expressionInQuery[2];
    expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inQuery"];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];

    NSPredicate *predicateInQuery;
    predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                          rightExpression: expressionInQuery[1]
                                                                 modifier: NSDirectPredicateModifier
                                                                     type: NSEqualToPredicateOperatorType
                                                                  options: 0];
    
    NSString *keyQL = @"QL", *keyLF = @"RL", *keyRF = @"RF", *keyLT = @"LT", *keyRT = @"RT";
    expressionDescription[0] = [[NSExpressionDescription alloc] init];
    expressionDescription[0].name = keyQL;
    expressionDescription[0].expression = [NSExpression expressionForEvaluatedObject];
    expressionDescription[0].expressionResultType = NSManagedObjectIDResultType;

    expressionDescription[1] = [[NSExpressionDescription alloc] init];
    expressionDescription[1].name = keyLT;
    expressionDescription[1].expression = [NSExpression expressionForKeyPath:@"hasLeftField.inQueryTable"];
    expressionDescription[1].expressionResultType = NSManagedObjectIDResultType;

    expressionDescription[2] = [[NSExpressionDescription alloc] init];
    expressionDescription[2].name = keyLF;
    expressionDescription[2].expression = [NSExpression expressionForKeyPath:@"hasLeftField"];
    expressionDescription[2].expressionResultType = NSManagedObjectIDResultType;

    expressionDescription[3] = [[NSExpressionDescription alloc] init];
    expressionDescription[3].name = keyRT;
    expressionDescription[3].expression = [NSExpression expressionForKeyPath:@"hasRightField.inQueryTable"];
    expressionDescription[3].expressionResultType = NSManagedObjectIDResultType;
    
    expressionDescription[4] = [[NSExpressionDescription alloc] init];
    expressionDescription[4].name = keyRF;
    expressionDescription[4].expression = [NSExpression expressionForKeyPath:@"hasRightField"];
    expressionDescription[4].expressionResultType = NSManagedObjectIDResultType;
    
    
    NSArray *propertiesToFetch2 = [[NSArray alloc] initWithObjects:expressionDescription count:5];
    fetchQueryLinks.propertiesToFetch = propertiesToFetch2;
    fetchQueryLinks.resultType = NSDictionaryResultType;
    fetchQueryLinks.predicate = predicateInQuery;
    NSError * __autoreleasing * error = NULL;

    NSManagedObjectContext *managedObjectContext = _managedObjectContext;

    fetchQueryLinksResults = [managedObjectContext executeFetchRequest:fetchQueryLinks error:error];
    
    NSArray <NSManagedObjectID *> *queryLinkIDsFiltered;
    queryLinkIDsFiltered = [fetchQueryLinksResults valueForKey:keyQL];

    NSMutableOrderedSet <NSManagedObjectID *> *queryLinkIDs;
    queryLinkIDs = [[NSMutableOrderedSet alloc] initWithArray: queryLinkIDsFiltered];
    
    NSManagedObjectID *queryLinkID;
    MADModelQueryLink *queryLink;
    NSPredicate *predicateTable;
    NSExpression *queryLinkIDValue;
    NSExpression *queryLinkPathKey = [NSExpression expressionForKeyPath:keyQL];
    
    NSMapTable <NSManagedObjectID *, MADModelQueryLink *> *links;
    links = [[NSMapTable alloc] initWithKeyOptions: NSMapTableWeakMemory
                                      valueOptions: NSMapTableStrongMemory
                                          capacity: queryLinkIDs.count];
    
    for (queryLinkID in queryLinkIDs) {
        
        queryLinkIDValue = [NSExpression expressionForConstantValue: queryLinkID];
        predicateTable = [NSComparisonPredicate predicateWithLeftExpression: queryLinkPathKey
                                                            rightExpression: queryLinkIDValue
                                                                   modifier: NSDirectPredicateModifier
                                                                       type: NSEqualToPredicateOperatorType
                                                                    options: 0];
        
        NSArray *fresults = [fetchQueryLinksResults filteredArrayUsingPredicate:predicateTable];
        
        for (NSDictionary *results in fresults) {
            queryLink = [[MADModelQueryLink alloc] initWithObjectID:queryLinkID
                                                        leftFieldID:results[keyLF]
                                                        leftTableID:results[keyLT]
                                                       rightFieldID:results[keyRF]
                                                       rightTableID:results[keyRT]];
            [links setObject:queryLink forKey:queryLinkID];
        }
    }
    _links = links;
    _queryLinkIDs = queryLinkIDs;

    for (NSUInteger i=0; i<expressionDescCount; i++) {
        expressionDescription[i] = nil;
    }
    
    expressionInQuery[0] = nil;
    expressionInQuery[1] = nil;
    
    NSAssert(error == nil, @"Need this to work! %@", *error);
}

- (void)update { }

- (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink {
    MADModelQueryLink *link = [_links objectForKey:queryLink];
    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:link, queryLink, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationDeleteQueryLink
                                                            object: self
                                                          userInfo: userInfo];
    }];
    [_queryLinkIDs removeObject:queryLink];
    [_links removeObjectForKey:queryLink];
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
                            [[NSString alloc] initWithFormat:@"%@ <%@::%@> [%@, %@]",
                                                NSStringFromClass([self class]),
                                                _objectID.URIRepresentation.pathComponents[1],
                                                _objectID.URIRepresentation.pathComponents[2],
                                                _tables,
                                                _links] :
                            self.debugDescription;
    return debugDescription;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", _objectID];
    [debug appendFormat:@"Tables:\t%@", _tables];
    [debug appendFormat:@"Tables:\t%@", _tableSchemas];
    [debug appendFormat:@"Links:\t%@", _links];
    return debug;
}

@end

@implementation MADModelQueryLink {
    MADTableFieldReference *_leftFieldReference;
    MADTableFieldReference *_rightFieldReference;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID {
    if (self = [super initWithObjectID:objectID]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                     leftFieldID:(NSManagedObjectID *)leftFieldID
                     leftTableID:(NSManagedObjectID *)leftTableID
                    rightFieldID:(NSManagedObjectID *)rightFieldID
                    rightTableID:(NSManagedObjectID *)rightTableID {
    
    if (self = [self initWithObjectID:objectID]) {
        
        id leftFieldReference = [[MADTableFieldReference alloc] initWithTableID: leftTableID
                                                                     andFieldID: leftFieldID];
        _leftFieldReference = leftFieldReference;
        
        id rightFieldReference = [[MADTableFieldReference alloc] initWithTableID: rightTableID
                                                                      andFieldID: rightFieldID];
        _rightFieldReference = rightFieldReference;
    }
    return self;
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@> [%@ JOIN %@]",
     NSStringFromClass([self class]), _objectID.URIRepresentation.pathComponents[1],
                                      _objectID.URIRepresentation.pathComponents[2],
                                      _leftFieldReference.debugDescription,
                                      _rightFieldReference.debugDescription] :
                                      self.debugDescription;
    return debugDescription;
}

- (NSSet <NSManagedObjectID *> *)tables {
    NSManagedObjectID *tableLeft = _leftFieldReference.tableID.copy,
                      *tableRight = _rightFieldReference.tableID.copy;
    NSSet *tables = [[NSSet alloc] initWithObjects: tableLeft,
                                                    tableRight, nil];
    return tables;
}

- (NSSet <MADTableFieldReference *> *)tableFieldReferences {
    NSSet *tables = [[NSSet alloc] initWithObjects:_leftFieldReference,
                                                   _rightFieldReference, nil];
    return tables;
}

@end

@implementation MADModelQueryTable {
    NSManagedObjectID *_schemaTable;
    NSMutableOrderedSet <NSManagedObjectID *> *_fieldIDs;
    NSMapTable <NSManagedObjectID *, MADModelQueryField *> *_fields;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID {
    if (self = [super initWithObjectID:objectID]) { }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                     schemaTable:(NSManagedObjectID *)schemaTable
                      capacity:(NSUInteger)capacity {
    
    if (self = [self initWithObjectID:objectID]) {
        _schemaTable = schemaTable.copy;
        
        id fields;
        @autoreleasepool {
            fields = [[NSMapTable alloc] initWithKeyOptions: NSPointerFunctionsWeakMemory
                                               valueOptions: NSPointerFunctionsStrongMemory
                                                   capacity: capacity];
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

- (void)addField:(NSManagedObjectID *)fieldID
     schemaField:(NSManagedObjectID *)schemaField {
    
    MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithObjectID:fieldID
                                                                      schemaField:schemaField];
    [_fieldIDs addObject:fieldID];
    [_fields setObject:queryField forKey:fieldID];

}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@>",
     NSStringFromClass([self class]),
     _objectID.URIRepresentation.pathComponents[1],
     _objectID.URIRepresentation.pathComponents[2]] :
    self.debugDescription;
    return debugDescription;
}

@end

@implementation MADModelQueryField {
    NSManagedObjectID *_schemaField;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID {
    if (self = [super initWithObjectID:objectID]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                     schemaField:(NSManagedObjectID *)schemaField {
    if (self = [self initWithObjectID: objectID]) {
        _schemaField = schemaField.copy;
    }
    return self;
}

- (NSString *)debugDescription {
    NSString *debugDescription;
    debugDescription = _objectID.URIRepresentation.pathComponents.count == 3 ?
    [[NSString alloc] initWithFormat:@"%@ <%@::%@>",
     NSStringFromClass([self class]),
     _objectID.URIRepresentation.pathComponents[1],
     _objectID.URIRepresentation.pathComponents[2]] :
    self.debugDescription;
    return debugDescription;
}

@end
