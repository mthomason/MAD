//
//  MADModelDocument.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelDocument.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSDictionary.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSOperation.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSExpressionDescription.h>

#import "MADModelDatabase.h"
#import "MADModelQuery.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryLinks.h"
#import "RptqQueryTable.h"

@interface MADModelDocument ()
    - (instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readwrite, copy)       NSManagedObjectID *objectID;
    @property (nonatomic, readwrite, strong) NSMutableOrderedSet <MADModelDatabase *> *databases;
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
    @dynamic objectID;
    @synthesize managedObjectContext = _managedObjectContext;

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:_observeChangeNotification];
    [notificationCenter removeObserver:_observeWillSaveNotification];
    [notificationCenter removeObserver:_observeDidSaveNotification];
}

- (instancetype)init {
    if (self = [self initWithObjectID: nil
                           identifier: -1
                 managedObjectContext: nil]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID identifier:(int64_t)identifier {
    if (self = [self initWithObjectID:objectID identifier:identifier managedObjectContext:nil]) {
        
    }
    return self;
}

- (instancetype)initWithContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [self initWithObjectID:nil identifier: -1
                 managedObjectContext:managedObjectContext]) {
        
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                      identifier:(int64_t)identifier
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID identifier:identifier]) {
        _managedObjectContext = managedObjectContext;
        
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
    if (![super objectID]) {
        [self update];
    }
    return [super objectID];
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

+ (NSFetchRequest <NSManagedObjectID *> *)fetchRequestObjectID {
    NSFetchRequest *request;
    request = [[NSFetchRequest alloc] initWithEntityName: NSStringFromClass([RptqDocument class])];
    request.fetchLimit = 1;
    request.resultType = NSManagedObjectIDResultType;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    return request;
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
            self.objectID = resultWrapper[keyDocument].copy;
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
