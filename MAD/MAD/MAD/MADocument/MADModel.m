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

static NSString * const MADKeyQueryLink = @"QL";
static NSString * const MADKeyQueryLinkLeftField = @"LF";
static NSString * const MADKeyQueryLinkRightField = @"RF";
static NSString * const MADKeyQueryLinkLeftTable = @"LT";
static NSString * const MADKeyQueryLinkRightTable = @"RT";
static NSString * const MADKeyQueryTable = @"QT";
static NSString * const MADKeyQueryField = @"QF";
static NSString * const MADKeySchemaFieldName = @"SFN";
static NSString * const MADKeySchemaTableName = @"STN";
static NSString * const MADKeySchemaTable = @"ST";
static NSString * const MADKeySchemaField = @"SF";

static NSString * const MADKeyQueryLinkID = @"QLI";
static NSString * const MADKeyQueryLinkLeftFieldID = @"LFI";
static NSString * const MADKeyQueryLinkRightFieldID = @"RFI";
static NSString * const MADKeyQueryLinkLeftTableID = @"LTI";
static NSString * const MADKeyQueryLinkRightTableID = @"RTI";

static NSString * const MADKeyQueryTableID = @"QTI";
static NSString * const MADKeyQueryFieldID = @"QFI";
static NSString * const MADKeySchemaTableID = @"STI";
static NSString * const MADKeySchemaFieldID = @"SFI";

NSString * const MADKeyQuery = @"MADKeyQuery";

@implementation MADTableFieldIdentifier {
    int64_t _tableID;
    int64_t _fieldID;
}

@dynamic tableID;
@dynamic fieldID;

- (instancetype)init {
    if (self = [self initWithTableID:-1 andFieldID:-1]) {
    }
    return self;
}

- (instancetype)initWithTableID:(int64_t)tableID
                     andFieldID:(int64_t)fieldID {
    if (self = [super init]) {
        _tableID = tableID;
        _fieldID = fieldID;
    }
    return self;
}

- (int64_t)tableID {
    return _tableID;
}

- (int64_t)fieldID {
    return _fieldID;
}

@end

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
                          identifier:(int64_t)identifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                             queryID:(NSManagedObjectID *)queryID
                          queryIdentifier:(int64_t)queryIdentifier
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelTable ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;
    - (void)addFieldWithID:(NSManagedObjectID *)objectID
                identifier:(int64_t)identifier
                      name:(NSString *)name
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelField ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                                name:(NSString *)name;

@end

@interface MADModelQuery ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                            database:(MADModelDatabase *)database;
    @property (nonatomic, weak, readonly) MADModelDatabase *database;
    - (void)deleteQueryTableID:(NSManagedObjectID *)queryTable;
    - (void)deleteQueryLinkID:(NSManagedObjectID *)queryLink;
    - (void)insertQueryTableID:(NSManagedObjectID *)queryTableID;
    - (void)insertQueryLinkID:(NSManagedObjectID *)queryLinkID;
@end

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

@interface MADModelQueryField ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                         schemaField:(NSManagedObjectID *)schemaField
               schemaFieldIdentifier:(int64_t)schemaFieldIdentifier;
@end

@interface MADModelQueryLink ()

    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                          identifier:(int64_t)identifier
                         leftFieldID:(NSManagedObjectID *)leftFieldID
                        lfIdentifier:(int64_t)lfIdentifier
                         leftTableID:(NSManagedObjectID *)leftTableID
                        ltIdentifier:(int64_t)ltIdentifier
                        rightFieldID:(NSManagedObjectID *)rightFieldID
                        rfIdentifier:(int64_t)rfIdentifier
                        rightTableID:(NSManagedObjectID *)rightTableID
                        rtIdentifier:(int64_t)rtIdentifier;
+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate;
    - (NSSet <MADTableFieldReference *> *)tableFieldReferences;
    - (NSSet <NSManagedObjectID *> *)tables;

@end

#pragma mark -
#pragma mark MAD Object ID

@implementation MADObjectID {
  @protected
    int64_t _uid;
    NSManagedObjectID *_objectID;
}
    @dynamic identifier;
    @synthesize objectID = _objectID;

- (instancetype)newObjectIDDocument:(NSManagedObjectContext *)managedObjectContext {
    return [[MADModelDocument alloc] initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super init]) {
        _objectID = objectID.copy;
        _uid = identifier;
    }
    return self;
}

- (int64_t)identifier {
    return _uid;
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
                           identifier:-1
                 managedObjectContext: nil]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
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
    
    void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *, NSAttributeType) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression, NSAttributeType type) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = type;
    };
    
    NSUInteger expressionCount = 6;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSManagedObjectContext *managedObjectContext;
    managedObjectContext = _managedObjectContext;
    
    for (NSUInteger i=0; i<expressionCount; i++) {
        expressionDescription[i] = [[NSExpressionDescription alloc] init];
    }
    
    request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    
    NSString *keyDatabase = @"DA", *keyQuery = @"QU", *keyDocument = @"DO";
    NSString *keyIDDatabase = @"ID", *keyIDQuery = @"IQ", *keyIDDocument = @"IO";
    
    NSString *identifier = NSStringFromSelector(@selector(identifier));
    NSString *inDatabase = NSStringFromSelector(@selector(inDatabase));
    NSString *inDocument;

    inDocument = [inDatabase stringByAppendingString:@"."];
    inDocument = [inDocument stringByAppendingString: NSStringFromSelector(@selector(ownedByQueryAsStaticResource))];

    NSString *inDBID = [inDatabase stringByAppendingString:@"."];
    inDBID = [inDBID stringByAppendingString:identifier];

    NSString *inDocID = [inDocument stringByAppendingString:@"."];
    inDocID = [inDocID stringByAppendingString:identifier];

    
    NSExpression *databaseExpression = [NSExpression expressionForKeyPath:inDatabase];
    NSExpression *databaseInDocumentExpression = [NSExpression expressionForKeyPath:inDocument];
    NSExpression *selfExpresssion = [NSExpression expressionForEvaluatedObject];
    NSExpression *dbIDExpression = [NSExpression expressionForKeyPath:inDBID];
    NSExpression *queryIDExpression = [NSExpression expressionForKeyPath:identifier];
    NSExpression *docIDExpression = [NSExpression expressionForKeyPath:inDocID];
    setupExpression(expressionDescription[0], keyDatabase, databaseExpression, NSObjectIDAttributeType);
    setupExpression(expressionDescription[1], keyDocument, databaseInDocumentExpression, NSObjectIDAttributeType);
    setupExpression(expressionDescription[2], keyQuery, selfExpresssion, NSObjectIDAttributeType);
    
    setupExpression(expressionDescription[3], keyIDDatabase, dbIDExpression, NSInteger64AttributeType);
    setupExpression(expressionDescription[4], keyIDQuery, queryIDExpression, NSInteger64AttributeType);
    setupExpression(expressionDescription[5], keyIDDocument, docIDExpression, NSInteger64AttributeType);

    request.resultType = NSDictionaryResultType;
    NSError * __autoreleasing *error = NULL;
    
    NSArray *propertiesToFetch;
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:expressionCount];
    request.propertiesToFetch = propertiesToFetch;
    result = [managedObjectContext executeFetchRequest:request error:error];
    
    
    NSMutableOrderedSet <MADModelDatabase *> *databases;
    databases = [[NSMutableOrderedSet <MADModelDatabase *> alloc] initWithCapacity:result.count];
    
    MADModelDatabase *database;
    NSUInteger resultCount = 0;
    
    NSDictionary <NSString *, __kindof NSObject *> *resultWrapper;

    int64_t docID, dbID, qID;
    for (resultWrapper in result) {
        if (resultCount == 0) {
            _objectID = resultWrapper[keyDocument].copy;
        }

        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDQuery], kCFNumberSInt64Type, &qID);
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDDatabase], kCFNumberSInt64Type, &dbID);
        CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)resultWrapper[keyIDDocument], kCFNumberSInt64Type, &docID);
        database = [[MADModelDatabase alloc] initWithObjectID: resultWrapper[keyDatabase]
                                                   identifier: dbID
                                                      queryID: resultWrapper[keyQuery]
                                              queryIdentifier: qID
                                         managedObjectContext: managedObjectContext];
        [databases addObject: database];
        database = nil;
        resultCount++;
    }
    
    for (NSUInteger i=0; i<expressionCount; i++) {
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

#pragma mark -
#pragma mark MADModelTable

@implementation MADModelTable {
    NSString *_name;
    NSMutableOrderedSet <MADModelField *> *_fields;
}

@synthesize fields = _fields;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                            name:(NSString *)name {
    if (self = [self initWithObjectID:objectID identifier:identifier]) {
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
            identifier:(int64_t)identifier
                  name:(NSString *)name
  managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    if (_fields == nil) {
        NSMutableOrderedSet *fields = [[NSMutableOrderedSet alloc] init];
        _fields = fields;
    }
    id field = [[MADModelField alloc] initWithObjectID: objectID
                                            identifier:identifier
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

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID: objectID identifier: identifier]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                            name:(NSString *)name {
    if (self = [self initWithObjectID:objectID identifier:identifier]) {
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
                      identifier:(int64_t)identifier
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                        database:(MADModelDatabase *)database {
    if (self = [self initWithObjectID: objectID
                           identifier: identifier
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

    NSExpression *expressions[expressionInQueryCount];
    NSString *predicateKey = [NSStringFromSelector(@selector(inQueryTable)) stringByAppendingString:@"."];
    predicateKey = [predicateKey stringByAppendingString:NSStringFromSelector(@selector(inQuery))];
    
    expressions[0] = [NSExpression expressionForKeyPath:predicateKey];
    expressions[1] = [NSExpression expressionForConstantValue: _objectID];
    
    NSPredicate *predicate;
    predicate = [NSComparisonPredicate predicateWithLeftExpression: expressions[0]
                                                   rightExpression: expressions[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
    
    NSFetchRequest *fetchQueryTable = [MADModelQueryTable fetchRequest: predicate];
    
    fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    NSAssert(fetchQueryTableResults != nil && error == nil, @"What? %@", *error);

    [self insertTablesFromFetchRequestResults:fetchQueryTableResults];

    for (NSUInteger i=0; i<expressionInQueryCount; i++) {
        expressions[i] = nil;
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
    int64_t stid = -1, qtid = -1, sfid = -1, qfid = -1;
    @autoreleasepool {
        
        NSDictionary *filteredResult;
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
                filteredResult = fresults.firstObject;
                
                CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[MADKeySchemaTableID], kCFNumberSInt64Type, &stid);
                CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[MADKeySchemaFieldID], kCFNumberSInt64Type, &sfid);
                CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[MADKeyQueryTableID], kCFNumberSInt64Type, &qtid);
                CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[MADKeyQueryFieldID], kCFNumberSInt64Type, &qfid);
                
                MADModelQueryTable *queryTable;
                queryTable = [[MADModelQueryTable alloc] initWithObjectID: tableObjectID
                                                               identifier: qtid
                                                              schemaTable: filteredResult[MADKeySchemaTable]
                                                    schemaTableIdentifier: stid
                                                                 capacity: fresults.count];
                
                for (filteredResult in fresults) {
                    [queryTable addField: filteredResult[MADKeyQueryField]
                         fieldIdentifier: qfid
                             schemaField: filteredResult[MADKeySchemaField]
                   schemaFieldIdentifier: sfid];
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
    NSPredicate *predicate;
    NSExpression *queryLinkIDValue;
    NSExpression *queryLinkPathKey = [NSExpression expressionForKeyPath:MADKeyQueryLink];
    
    for (queryLinkID in _queryLinkIDs) {
        
        queryLinkIDValue = [NSExpression expressionForConstantValue: queryLinkID];
        predicate = [NSComparisonPredicate predicateWithLeftExpression: queryLinkPathKey
                                                       rightExpression: queryLinkIDValue
                                                              modifier: NSDirectPredicateModifier
                                                                  type: NSEqualToPredicateOperatorType
                                                               options: 0];
        
        NSArray *fresults = [results filteredArrayUsingPredicate:predicate];
        
        int64_t qlid = -1, ltid = -1, lfid = -1, rtid = -1, rfid = -1;
        for (NSDictionary *result in fresults) {
            
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkID], kCFNumberSInt64Type, &qlid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkLeftTableID], kCFNumberSInt64Type, &ltid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkLeftFieldID], kCFNumberSInt64Type, &lfid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkRightTableID], kCFNumberSInt64Type, &rtid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkRightFieldID], kCFNumberSInt64Type, &rfid);
            
            queryLink = [[MADModelQueryLink alloc] initWithObjectID: queryLinkID
                                                         identifier: qlid
                                                        leftFieldID: result[MADKeyQueryLinkLeftField]
                                                       lfIdentifier: lfid
                                                        leftTableID: result[MADKeyQueryLinkLeftTable]
                                                       ltIdentifier: ltid
                                                       rightFieldID: result[MADKeyQueryLinkRightField]
                                                       rfIdentifier: rfid
                                                       rightTableID: result[MADKeyQueryLinkRightTable]
                                                       rtIdentifier: rtid];
            
            [_links setObject:queryLink forKey:queryLinkID];
            
        }
    }

}

// Fetches the needed data from RptqQueryLinks.
// It creates MADModelQueryLink objects.
- (void)updateLinks {

    NSArray <NSDictionary *> *fetchQueryLinksResults;
    NSFetchRequest *fetch;
    NSExpression *expressions[2];
    NSPredicate *predicate;

    fetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];
    expressions[0] = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(inQuery))];
    expressions[1] = [NSExpression expressionForConstantValue: _objectID];

    predicate = [NSComparisonPredicate predicateWithLeftExpression: expressions[0]
                                                   rightExpression: expressions[1]
                                                          modifier: NSDirectPredicateModifier
                                                              type: NSEqualToPredicateOperatorType
                                                           options: 0];
 
    fetch = [MADModelQueryLink fetchRequest:predicate];
    
    NSError * __autoreleasing * error = NULL;
    fetchQueryLinksResults = [_managedObjectContext executeFetchRequest:fetch error:error];
    NSAssert(fetchQueryLinksResults != nil && error == nil, @"Need this to work! %@", *error);

    [self insertLinksFromFetchRequestResults:fetchQueryLinksResults];
    
    expressions[0] = nil;
    expressions[1] = nil;
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
    MADTableFieldIdentifier *_leftFieldIdentifier;
    MADTableFieldIdentifier *_rightFieldIdentifier;
}

+ (NSFetchRequest *)fetchRequest:(NSPredicate *)predicate {
    NSFetchRequest *fetchRequest;
    
    NSUInteger expressionDescCount = 10;
    NSString *pathIdentifier, *pathHasRightField, *pathHasLeftField, *pathInQueryTable;
    
    NSExpressionDescription *expressionDescription[expressionDescCount];

    pathIdentifier = NSStringFromClass([RptqQueryLinks class]);
    
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:pathIdentifier];

    pathHasRightField = NSStringFromSelector(@selector(hasRightField));
    pathHasLeftField = NSStringFromSelector(@selector(hasLeftField));
    pathInQueryTable = NSStringFromSelector(@selector(inQueryTable));

    expressionDescription[0] = [[NSExpressionDescription alloc] init];
    expressionDescription[0].name = MADKeyQueryLink;
    expressionDescription[0].expression = [NSExpression expressionForEvaluatedObject];
    expressionDescription[0].expressionResultType = NSManagedObjectIDResultType;

    NSString *pathRTID = [pathHasRightField stringByAppendingString:@"."];
    pathRTID = [pathRTID stringByAppendingString:pathInQueryTable];

    NSString *pathLTID = [pathHasLeftField stringByAppendingString:@"."];
    pathLTID = [pathLTID stringByAppendingString:pathInQueryTable];

    expressionDescription[1] = [[NSExpressionDescription alloc] init];
    expressionDescription[1].name = MADKeyQueryLinkLeftTable;
    expressionDescription[1].expression = [NSExpression expressionForKeyPath:pathRTID];
    expressionDescription[1].expressionResultType = NSObjectIDAttributeType;
    
    expressionDescription[2] = [[NSExpressionDescription alloc] init];
    expressionDescription[2].name = MADKeyQueryLinkLeftField;
    expressionDescription[2].expression = [NSExpression expressionForKeyPath:pathHasLeftField];
    expressionDescription[2].expressionResultType = NSObjectIDAttributeType;
    
    expressionDescription[3] = [[NSExpressionDescription alloc] init];
    expressionDescription[3].name = MADKeyQueryLinkRightTable;
    expressionDescription[3].expression = [NSExpression expressionForKeyPath:pathLTID];
    expressionDescription[3].expressionResultType = NSObjectIDAttributeType;
    
    expressionDescription[4] = [[NSExpressionDescription alloc] init];
    expressionDescription[4].name = MADKeyQueryLinkRightField;
    expressionDescription[4].expression = [NSExpression expressionForKeyPath:pathHasRightField];
    expressionDescription[4].expressionResultType = NSObjectIDAttributeType;
    
    pathIdentifier = NSStringFromSelector(@selector(identifier));

    NSString *pathRFID = [pathHasRightField stringByAppendingString:@"."];
    pathRFID = [pathRFID stringByAppendingString:pathIdentifier];
    
    NSString *pathLFID = [pathHasLeftField stringByAppendingString:@"."];
    pathLFID = [pathLFID stringByAppendingString:pathIdentifier];
    
    pathRTID = [pathRTID stringByAppendingString:@"."];
    pathRTID = [pathRTID stringByAppendingString:pathIdentifier];
    
    pathLTID = [pathLTID stringByAppendingString:@"."];
    pathLTID = [pathLTID stringByAppendingString:pathIdentifier];
    
    expressionDescription[5] = [[NSExpressionDescription alloc] init];
    expressionDescription[5].name = MADKeyQueryLinkRightFieldID;
    expressionDescription[5].expression = [NSExpression expressionForKeyPath:pathRFID];
    expressionDescription[5].expressionResultType = NSInteger64AttributeType;
    
    expressionDescription[6] = [[NSExpressionDescription alloc] init];
    expressionDescription[6].name = MADKeyQueryLinkLeftFieldID;
    expressionDescription[6].expression = [NSExpression expressionForKeyPath:pathLFID];
    expressionDescription[6].expressionResultType = NSInteger64AttributeType;

    expressionDescription[7] = [[NSExpressionDescription alloc] init];
    expressionDescription[7].name = MADKeyQueryLinkRightTableID;
    expressionDescription[7].expression = [NSExpression expressionForKeyPath:pathRTID];
    expressionDescription[7].expressionResultType = NSInteger64AttributeType;
    
    expressionDescription[8] = [[NSExpressionDescription alloc] init];
    expressionDescription[8].name = MADKeyQueryLinkLeftTableID;
    expressionDescription[8].expression = [NSExpression expressionForKeyPath:pathLTID];
    expressionDescription[8].expressionResultType = NSInteger64AttributeType;

    expressionDescription[9] = [[NSExpressionDescription alloc] init];
    expressionDescription[9].name = MADKeyQueryLinkID;
    expressionDescription[9].expression = [NSExpression expressionForKeyPath:pathIdentifier];
    expressionDescription[9].expressionResultType = NSInteger64AttributeType;

    
    NSArray <NSExpressionDescription *> *properties;
    properties = [[NSArray alloc] initWithObjects: expressionDescription
                                            count: expressionDescCount];
    fetchRequest.propertiesToFetch = properties;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;

    for (NSUInteger i=0; i<expressionDescCount; i++) {
        expressionDescription[i] = nil;
    }
    
    return fetchRequest;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                     leftFieldID:(NSManagedObjectID *)leftFieldID
                    lfIdentifier:(int64_t)lfIdentifier
                     leftTableID:(NSManagedObjectID *)leftTableID
                    ltIdentifier:(int64_t)ltIdentifier
                    rightFieldID:(NSManagedObjectID *)rightFieldID
                    rfIdentifier:(int64_t)rfIdentifier
                    rightTableID:(NSManagedObjectID *)rightTableID
                    rtIdentifier:(int64_t)rtIdentifier {
    
    if (self = [self initWithObjectID:objectID identifier:identifier]) {
        
        MADTableFieldIdentifier *leftFieldIdentifier, *rightFieldIdentifier;
        leftFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: rtIdentifier
                                                                    andFieldID: rfIdentifier];
        _leftFieldIdentifier = leftFieldIdentifier;
        rightFieldIdentifier = [[MADTableFieldIdentifier alloc] initWithTableID: ltIdentifier
                                                                     andFieldID: lfIdentifier];
        _rightFieldIdentifier = rightFieldIdentifier;
        
        MADTableFieldReference *leftFieldReference;
        leftFieldReference = [[MADTableFieldReference alloc] initWithTableID: leftTableID
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
    propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription
                                                   count:(NSUInteger)expressionCount];
    
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
    queryField = [[MADModelQueryField alloc] initWithObjectID:_fieldID
                                                   identifier: fieldIdentifier
                                                  schemaField: _schemaField
                                        schemaFieldIdentifier: schemaFieldIdentifier];
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

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
                     schemaField:(NSManagedObjectID *)schemaField
           schemaFieldIdentifier:(int64_t)schemaFieldIdentifier {
    if (self = [self initWithObjectID: objectID identifier:identifier]) {
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
