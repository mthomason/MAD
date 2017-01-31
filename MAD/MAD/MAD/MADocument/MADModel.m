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
#import <MAD/RptqDocument.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqDatabaseSchemaField.h>

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

NSString * const MADNotificationQueryTableInsert = @"MADNotificationQueryTableInsert";
NSString * const MADNotificationQueryTableDelete = @"MADNotificationQueryTableDelete";

NSString * const MADNotificationQueryLinkInsert = @"MADNotificationQueryLinkInsert";
NSString * const MADNotificationQueryLinkDelete = @"MADNotificationQueryLinkDelete";

static NSString * const MADKeyQueryTable = @"QT";
static NSString * const MADKeyQueryLink = @"QL";
static NSString * const MADKeyQueryLinkLeftField = @"LF";
static NSString * const MADKeyQueryLinkRightField = @"RF";
static NSString * const MADKeyQueryLinkLeftTable = @"LT";
static NSString * const MADKeyQueryLinkRightTable = @"RT";
static NSString * const MADKeyQueryField = @"QF";
static NSString * const MADKeySchemaFieldName = @"SFN";
static NSString * const MADKeySchemaTableName = @"STN";
static NSString * const MADKeySchemaTable = @"ST";
static NSString * const MADKeySchemaField = @"SF";

NSString * const MADKeyQuery = @"MADKeyQuery";

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
    - (void)deleteQueryTableID:(NSManagedObjectID *)queryTable;
    - (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink;
    - (void)insertQueryTableID:(NSManagedObjectID *)queryTableID;
    - (void)insertQueryLinkID:(NSManagedObjectID *)queryLinkID;
@end

@interface MADModelQueryTable ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         schemaTable:(NSManagedObjectID *)schemaTable
                            capacity:(NSUInteger)capacity;
    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
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
    + (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
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
    id <NSObject> _observeChangeNotification;
    id <NSObject> _observeWillSaveNotification;
    id <NSObject> _observeDidSaveNotification;
}
    @synthesize managedObjectContext = _managedObjectContext;

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:_observeChangeNotification];
    [notificationCenter removeObserver:_observeWillSaveNotification];
    [notificationCenter removeObserver:_observeDidSaveNotification];
}

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
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        _observeChangeNotification = [notificationCenter addObserverForName:NSManagedObjectContextObjectsDidChangeNotification
                                                                     object:managedObjectContext
                                                                      queue:_objectContextQueue
                                                                 usingBlock:^(NSNotification * _Nonnull note) {
                                                                     
                                                                     //NSLog(@"%@: %@", NSStringFromClass(note.class), note);
                                                                     id keys = note.userInfo.keyEnumerator;
                                                                     id objects = note.userInfo.objectEnumerator;
                                                                     
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
                                                                         
                                                                         if ([obj isKindOfClass:[RptqQueryTable class]]) {
                                                                             typeof(self) sself = wself;
                                                                             MADModelQuery *query = sself.firstQuery;
                                                                             [query deleteQueryTableID:((NSManagedObject *)obj).objectID];
                                                                         }
                                                                         
                                                                     }];
                                                                     
                                                                     insertedObjects = [note.userInfo objectForKey:NSInsertedObjectsKey];
                                                                     [insertedObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                                                                         
                                                                         if ([obj isKindOfClass:[RptqQueryLinks class]]) {
                                                                             typeof(self) sself = wself;
                                                                             MADModelQuery *query = sself.firstQuery;
                                                                             [query insertQueryLinkID:((NSManagedObject *)obj).objectID];
                                                                         }
                                                                         
                                                                         if ([obj isKindOfClass:[RptqQueryTable class]]) {
                                                                             typeof(self) sself = wself;
                                                                             MADModelQuery *query = sself.firstQuery;
                                                                             [query insertQueryTableID:((NSManagedObject *)obj).objectID];
                                                                         }
                                                                         
                                                                     }];
                                                                     updatedObjects = [note.userInfo objectForKey:NSUpdatedObjectsKey];
                                                                     invalidatedObjects = [note.userInfo objectForKey:NSInvalidatedObjectsKey];
                                                                     
                                                                 }];

        _observeWillSaveNotification = [notificationCenter addObserverForName:NSManagedObjectContextWillSaveNotification
                                                                       object:managedObjectContext
                                                                        queue:_objectContextQueue
                                                                   usingBlock:^(NSNotification * _Nonnull note) {
                                                                       //NSLog(@"%@: %@", NSStringFromClass(note.class), note);
                                                                   }];
        _observeDidSaveNotification = [notificationCenter addObserverForName:NSManagedObjectContextDidSaveNotification
                                                                      object:managedObjectContext
                                                                       queue:_objectContextQueue
                                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                                      //NSLog(@"%@: %@", NSStringFromClass(note.class), note);
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
    NSMutableDictionary <NSManagedObjectID *, MADModelQueryTable *> *_tables;
    NSMutableDictionary <NSManagedObjectID *, MADModelTable *> *_tableSchemas;
    NSMutableDictionary <NSManagedObjectID *, MADModelQueryLink *> *_links;
    MADModelDatabase __weak *_database;
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

            if (_tables == nil) {
                NSMutableDictionary <NSManagedObjectID *, MADModelQueryTable *> *tables;
                tables = [[NSMutableDictionary alloc] init];
                _tables = tables;
            }
            
            NSMutableOrderedSet <NSManagedObjectID *> *tableIDs;
            tableIDs = [[NSMutableOrderedSet alloc] init];
            _queryTableIDs = tableIDs;
            
            [self updateTables];
        }
    }
    return _queryTableIDs;
}

- (NSOrderedSet <NSManagedObjectID *> *)queryLinkIDs {
    if (_queryLinkIDs == nil) {
        @autoreleasepool {
            
            NSMutableDictionary <NSManagedObjectID *, MADModelQueryLink *> *links;
            links = [[NSMutableDictionary alloc] init];
            _links = links;
            
            NSMutableOrderedSet <NSManagedObjectID *> *queryLinkIDs;
            queryLinkIDs = [[NSMutableOrderedSet alloc] init];
            _queryLinkIDs = queryLinkIDs;

            [self updateLinks];
        }
    }
    return _queryLinkIDs;
}

- (NSMutableDictionary <NSManagedObjectID *, MADModelQueryTable *> *)tables {
    if (_tables == nil) {
        @autoreleasepool {
            NSMutableDictionary <NSManagedObjectID *, MADModelQueryTable *> *tables;
            tables = [[NSMutableDictionary alloc] init];
            _tables = tables;
            
            if (_queryTableIDs == nil) {
                NSMutableOrderedSet <NSManagedObjectID *> *tableIDs;
                tableIDs = [[NSMutableOrderedSet alloc] init];
                _queryTableIDs = tableIDs;
            }
            [self updateTables];
        }
    }
    return _tables;
}

- (NSMutableDictionary <NSManagedObjectID *, MADModelQueryLink *> *)links {
    if (_links == nil) {
        @autoreleasepool {
            
            NSMutableDictionary <NSManagedObjectID *, MADModelQueryLink *> *links;
            links = [[NSMutableDictionary alloc] init];
            _links = links;

            NSMutableOrderedSet <NSManagedObjectID *> *queryLinkIDs;
            queryLinkIDs = [[NSMutableOrderedSet alloc] init];
            _queryLinkIDs = queryLinkIDs;
            
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
    NSArray <NSDictionary *> *fetchQueryTableResults;
    
    NSUInteger expressionInQueryCount = 2;

    NSExpression *expressionInQuery[expressionInQueryCount];
    NSString *predicateKey = [NSStringFromSelector(@selector(inQueryTable)) stringByAppendingString:@"."];
    predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(inQuery))];
    
    expressionInQuery[0] = [NSExpression expressionForKeyPath:predicateKey];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];
    
    NSPredicate *predicateInQuery;
    predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                          rightExpression: expressionInQuery[1]
                                                                 modifier: NSDirectPredicateModifier
                                                                     type: NSEqualToPredicateOperatorType
                                                                  options: 0];
    
    NSFetchRequest *fetchQueryTable = [MADModelQueryTable fetchRequest: predicateInQuery];
    
    fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    NSAssert(fetchQueryTableResults != nil && error == nil, @"What? %@", *error);

    [self insertTablesFromFetchRequestResults:fetchQueryTableResults];

    for (NSUInteger i=0; i<expressionInQueryCount; i++) {
        expressionInQuery[i] = nil;
    }

}

- (void)insertTablesFromFetchRequestResults:(NSArray <NSDictionary *> *)results {
    if (!results.count) return;
    
    NSArray <NSManagedObjectID *> *tableValues;
    tableValues = [results valueForKey:MADKeyQueryTable];
    
    NSOrderedSet <NSManagedObjectID *> *tableObjectIDs;
    tableObjectIDs = [[NSOrderedSet alloc] initWithArray: tableValues copyItems:NO];
    
    
    NSComparisonPredicate *predicateTable;
    NSExpression *tablePath = [NSExpression expressionForKeyPath: MADKeyQueryTable], *tableValue;
    NSArray *fresults;
    @autoreleasepool {
        NSManagedObjectID *tableObjectID;
        for (tableObjectID in tableObjectIDs) {
            
            @autoreleasepool {
                
                tableValue = [NSExpression expressionForConstantValue: tableObjectID];
                predicateTable = [NSComparisonPredicate predicateWithLeftExpression: tablePath
                                                                    rightExpression: tableValue
                                                                           modifier: NSDirectPredicateModifier
                                                                               type: NSEqualToPredicateOperatorType
                                                                            options: 0];
                fresults = [results filteredArrayUsingPredicate:predicateTable];
                
                //NSManagedObjectID *schemaTable;
                NSDictionary *filteredResult = fresults.firstObject;
                
                MADModelQueryTable *queryTable;
                queryTable = [[MADModelQueryTable alloc] initWithObjectID: tableObjectID
                                                              schemaTable: filteredResult[MADKeySchemaTable]
                                                                 capacity: fresults.count];
                
//                id result
                for (filteredResult in fresults) {
                    [queryTable addField: filteredResult[MADKeyQueryField]
                             schemaField: filteredResult[MADKeySchemaField]];
                }
                NSManagedObjectID *tableID = tableObjectID.copy;
                [_queryTableIDs addObject:tableID];
                [_tables setObject:queryTable forKey:tableID];
                tableID = nil;
            }
        }
    }
}

- (void)insertLinksFromFetchRequestResults:(NSArray <NSDictionary *> *)results {
    if (!results.count) return;

    NSArray <NSManagedObjectID *> *queryLinkIDsFiltered;
    queryLinkIDsFiltered = [results valueForKey:MADKeyQueryLink];
    
    [_queryLinkIDs addObjectsFromArray:queryLinkIDsFiltered];
    NSManagedObjectID *queryLinkID;
    MADModelQueryLink *queryLink;
    NSPredicate *predicateTable;
    NSExpression *queryLinkIDValue;
    NSExpression *queryLinkPathKey = [NSExpression expressionForKeyPath:MADKeyQueryLink];
    
    for (queryLinkID in _queryLinkIDs) {
        
        queryLinkIDValue = [NSExpression expressionForConstantValue: queryLinkID];
        predicateTable = [NSComparisonPredicate predicateWithLeftExpression: queryLinkPathKey
                                                            rightExpression: queryLinkIDValue
                                                                   modifier: NSDirectPredicateModifier
                                                                       type: NSEqualToPredicateOperatorType
                                                                    options: 0];
        
        NSArray *fresults = [results filteredArrayUsingPredicate:predicateTable];
        
        for (NSDictionary *result in fresults) {
            queryLink = [[MADModelQueryLink alloc] initWithObjectID:queryLinkID
                                                        leftFieldID:result[MADKeyQueryLinkLeftField]
                                                        leftTableID:result[MADKeyQueryLinkLeftTable]
                                                       rightFieldID:result[MADKeyQueryLinkRightField]
                                                       rightTableID:result[MADKeyQueryLinkRightTable]];
            [_links setObject:queryLink forKey:queryLinkID];
        }
    }

}

// Fetches the needed data from RptqQueryLinks.
// It creates MADModelQueryLink objects.
- (void)updateLinks {

    NSArray <NSDictionary *> *fetchQueryLinksResults;
    NSFetchRequest *fetchQueryLinks;

    fetchQueryLinks = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];
    NSExpression *expressionInQuery[2];
    expressionInQuery[0] = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(inQuery))];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];

    NSPredicate *predicateInQuery;
    predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                          rightExpression: expressionInQuery[1]
                                                                 modifier: NSDirectPredicateModifier
                                                                     type: NSEqualToPredicateOperatorType
                                                                  options: 0];
    fetchQueryLinks = [MADModelQueryLink fetchRequest:predicateInQuery];
    NSError * __autoreleasing * error = NULL;
    fetchQueryLinksResults = [_managedObjectContext executeFetchRequest:fetchQueryLinks error:error];
    NSAssert(fetchQueryLinksResults != nil && error == nil, @"Need this to work! %@", *error);

    [self insertLinksFromFetchRequestResults:fetchQueryLinksResults];
    
    expressionInQuery[0] = nil;
    expressionInQuery[1] = nil;
}

- (void)update { }

// #MARK: Insert

- (void)insertQueryTableID:(NSManagedObjectID *)queryTableID {
    MADModelQueryTable *table;
    if ((table = [_tables objectForKey:queryTableID])) return;

    NSExpression *expressionInQuery[2];
    NSArray <NSDictionary *> *results;
    expressionInQuery[0] = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(inQueryTable))];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: queryTableID];
    
    NSPredicate *isQueryTable;
    isQueryTable = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                      rightExpression: expressionInQuery[1]
                                                             modifier: NSDirectPredicateModifier
                                                                 type: NSEqualToPredicateOperatorType
                                                              options: 0];
    NSError * __autoreleasing *error = NULL;
    NSFetchRequest *fetchRequest = [MADModelQueryTable fetchRequest:isQueryTable];
    results = [_managedObjectContext executeFetchRequest:fetchRequest error:error];
    
    NSAssert(results != nil && error == nil, @"What? %@", *error);
    [self insertTablesFromFetchRequestResults:results];
    
    expressionInQuery[0] = nil;
    expressionInQuery[1] = nil;
    
    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:table, queryTableID, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationQueryTableInsert
                                                            object: self
                                                          userInfo: userInfo];
    }];
}

- (void)insertQueryLinkID:(NSManagedObjectID *)queryLinkID {
    MADModelQueryLink *link;
    if ((link = [_links objectForKey:queryLinkID])) return;
    
    NSExpression *expressionInQuery[2];
    NSArray <NSDictionary *> *results;
    expressionInQuery[0] = [NSExpression expressionForEvaluatedObject];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: queryLinkID];
    
    NSPredicate *isQueryLink;
    isQueryLink = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                     rightExpression: expressionInQuery[1]
                                                            modifier: NSDirectPredicateModifier
                                                                type: NSEqualToPredicateOperatorType
                                                             options: 0];
    NSError * __autoreleasing *error = NULL;
    NSFetchRequest *fetchRequest = [MADModelQueryLink fetchRequest:isQueryLink];
    results = [_managedObjectContext executeFetchRequest:fetchRequest error:error];
    NSAssert(results != nil && error == nil, @"What? %@", *error);
    [self insertLinksFromFetchRequestResults:results];

    expressionInQuery[0] = nil;
    expressionInQuery[1] = nil;

    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:link, queryLinkID, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationQueryLinkInsert
                                                            object: self
                                                          userInfo: userInfo];
    }];
}


// #MARK: Delete

- (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink {
    MADModelQueryLink *link;
    if (!(link = [_links objectForKey:queryLink])) return;

    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:link, queryLink, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationQueryLinkDelete
                                                            object: self
                                                          userInfo: userInfo];
    }];
    [_queryLinkIDs removeObject:queryLink];
    [_links removeObjectForKey:queryLink];
}

- (void)deleteQueryTableID:(NSManagedObjectID *)queryTable {
    MADModelQueryTable *table = [_tables objectForKey:queryTable];
    if (!(table = [_tables objectForKey:queryTable])) return;

    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:table, queryTable, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationQueryTableDelete
                                                            object: self
                                                          userInfo: userInfo];
    }];
    [_queryTableIDs removeObject:queryTable];
    [_tables removeObjectForKey:queryTable];
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

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate {
    NSFetchRequest *fetchQueryLinks;
    
    NSUInteger expressionDescCount = 6;
    NSExpressionDescription *expressionDescription[expressionDescCount];
    
    fetchQueryLinks = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];

    expressionDescription[0] = [[NSExpressionDescription alloc] init];
    expressionDescription[0].name = MADKeyQueryLink;
    expressionDescription[0].expression = [NSExpression expressionForEvaluatedObject];
    expressionDescription[0].expressionResultType = NSManagedObjectIDResultType;
    
    expressionDescription[1] = [[NSExpressionDescription alloc] init];
    expressionDescription[1].name = MADKeyQueryLinkLeftTable;
    expressionDescription[1].expression = [NSExpression expressionForKeyPath:@"hasLeftField.inQueryTable"];
    expressionDescription[1].expressionResultType = NSManagedObjectIDResultType;
    
    expressionDescription[2] = [[NSExpressionDescription alloc] init];
    expressionDescription[2].name = MADKeyQueryLinkLeftField;
    expressionDescription[2].expression = [NSExpression expressionForKeyPath:@"hasLeftField"];
    expressionDescription[2].expressionResultType = NSManagedObjectIDResultType;
    
    expressionDescription[3] = [[NSExpressionDescription alloc] init];
    expressionDescription[3].name = MADKeyQueryLinkRightTable;
    expressionDescription[3].expression = [NSExpression expressionForKeyPath:@"hasRightField.inQueryTable"];
    expressionDescription[3].expressionResultType = NSManagedObjectIDResultType;
    
    expressionDescription[4] = [[NSExpressionDescription alloc] init];
    expressionDescription[4].name = MADKeyQueryLinkRightField;
    expressionDescription[4].expression = [NSExpression expressionForKeyPath:@"hasRightField"];
    expressionDescription[4].expressionResultType = NSManagedObjectIDResultType;
    
    
    NSArray *propertiesToFetch2 = [[NSArray alloc] initWithObjects:expressionDescription count:5];
    fetchQueryLinks.propertiesToFetch = propertiesToFetch2;
    fetchQueryLinks.resultType = NSDictionaryResultType;
    fetchQueryLinks.predicate = predicate;

    return fetchQueryLinks;
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
    NSMutableDictionary <NSManagedObjectID *, MADModelQueryField *> *_fields;
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
    
    void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = NSManagedObjectIDResultType;
        
    };
    
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
    
    NSUInteger expressionCount = 6;
    //NSExpression *expressionInQuery[expressionCount];
    NSExpressionDescription *expressionDescription[expressionCount];
    NSString *keys[] = {
        MADKeyQueryField,
        MADKeyQueryTable,
        MADKeySchemaFieldName,
        MADKeySchemaTableName,
        MADKeySchemaTable,
        MADKeySchemaField
    };
    
    NSExpression *expressionInQuery[] = {
        [NSExpression expressionForEvaluatedObject],
        [NSExpression expressionForKeyPath: keyPathInQueryTable],
        [NSExpression expressionForKeyPath: keyPathFieldName],
        [NSExpression expressionForKeyPath: keyPathTableName],
        [NSExpression expressionForKeyPath: keyPathSchemaTable],
        [NSExpression expressionForKeyPath: keyPathDatabaseSchemaField]
    };

    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        setupExpression(expressionDescription[i], keys[i], expressionInQuery[i]);
    }
    
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:(NSUInteger)expressionCount];
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    fetchQueryTable.resultType = NSDictionaryResultType;
    fetchQueryTable.predicate = predicate;
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = nil;
        keys[i] = nil;
        expressionInQuery[i] = nil;
    }
    return fetchQueryTable;
}

- (void)addField:(NSManagedObjectID *)fieldID
     schemaField:(NSManagedObjectID *)schemaField {
    
    NSManagedObjectID *_fieldID = fieldID, *_schemaField = schemaField;
    
    MADModelQueryField *queryField = [[MADModelQueryField alloc] initWithObjectID:_fieldID
                                                                      schemaField:_schemaField];
    [_fieldIDs addObject:_fieldID];
    [_fields setObject:queryField forKey:_fieldID];

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
