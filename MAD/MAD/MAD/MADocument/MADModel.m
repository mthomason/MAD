//
//  MADModel.m
//  MAD
//
//  Created by Michael on 1/22/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModel.h"
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchedResultsController.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchedPropertyDescription.h>
#import <CoreData/NSPropertyDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSException.h>

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

@interface MADObjectID ()
    - (instancetype)newObjectIDDocument:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;
    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;
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

@interface MADModelQuery ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
   // @property (nonatomic, readwrite, strong) NSOrderedSet <MADModelQueryTable *> *tables;
   // @property (nonatomic, readwrite, strong) NSOrderedSet <MADModelQueryLink *> *links;
@end

@interface MADModelQueryTable ()

@end

@interface MADModelQueryField ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                             tableID:(NSManagedObjectID *)tableID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface MADModelQueryLink ()

@end

#pragma mark -
#pragma mark MAD Object ID

@implementation MADObjectID {
  @protected
    NSManagedObjectID *_objectID;
    NSManagedObjectContext * __weak _managedObjectContext;
}

  @synthesize objectID = _objectID;
  @synthesize managedObjectContext = _managedObjectContext;

- (instancetype)newObjectIDDocument:(NSManagedObjectContext *)managedObjectContext {
    return [[MADModelDocument alloc] initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)init {
    return [self initWithManagedObjectContext:nil];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super init]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super init]) {
        _managedObjectContext = managedObjectContext;
        _objectID = objectID;
    }
    return self;
}

- (BOOL)isEqual:(id)object {

    return (self == object || (object != nil &&
            [object isKindOfClass:[self class]] &&
            ((typeof(self))object).objectID != nil &&
            [((typeof(self))object).objectID isEqual:_objectID]));
    
}

@end

#pragma mark -
#pragma mark MAD Document Object ID

@implementation MADModelDocument

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithManagedObjectContext:managedObjectContext]) {

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
        _objectID = [self fetchDocumentObjectID].copy;
    }
    return _objectID;
}

- (MADModelDatabase *)firstDatabase {
    return self.databases.firstObject;
}

- (MADModelQuery *)firstQuery {
    return self.firstDatabase.firstQuery;
}

//Load all the databases and queries for this document.  This is because current versions
// of the software only use one database and query.

- (void)update {
    if (_objectID == nil || _databases == nil) {
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
        
        setupExpression(expressionDescription[0], keyDatabase,
                        [NSExpression expressionForKeyPath:inDatabase]);

        setupExpression(expressionDescription[1], keyDocument,
                        [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"%@.%@",
                                                                inDatabase, inDocument]]);
        setupExpression(expressionDescription[2], keyQuery,
                        [NSExpression expressionForEvaluatedObject]);
        
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
            database = [[MADModelDatabase alloc] initWithObjectID:resultWrapper[keyDatabase]
                                                          queryID:resultWrapper[keyQuery]
                                             managedObjectContext:managedObjectContext];
            NSLog(@"%@", database.tables);
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
    
}

- (NSManagedObjectID *)fetchDocumentObjectID {
    NSFetchRequest *request;
    request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocument class])];
    request.fetchLimit = 1;
    request.resultType = NSManagedObjectIDResultType;
    request.includesSubentities = NO;
    request.includesPropertyValues = NO;
    NSError * __autoreleasing *error = NULL;
    NSArray <NSManagedObjectID *> *result;
    result = [_managedObjectContext executeFetchRequest:request error:error];
    return  result.firstObject;
}

@end

#pragma mark -
#pragma mark MAD Database Object ID

@implementation MADModelDatabase {
  @protected
    NSOrderedSet <MADModelTable *> *_tables;
    NSOrderedSet <MADModelQuery *> *_queries;
}

@synthesize tables = _tables;
@synthesize queries = _queries;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         queryID:(NSManagedObjectID *)queryID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {
        MADModelQuery *queryObjectID;
        
        NSMutableOrderedSet <MADModelQuery *> *queries;
        queries = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];

        queryObjectID = [[MADModelQuery alloc] initWithObjectID:queryID
                                           managedObjectContext:managedObjectContext];
        [queries addObject: queryObjectID];
        _queries = queries;
    }
    return self;
}

- (NSOrderedSet <MADModelTable *> *)tables {
    if (!_tables) {
        NSManagedObjectContext *managedObjectContext = _managedObjectContext;
        
        NSError * __autoreleasing *error = NULL;
        NSArray <NSManagedObjectID *> *results;
        
        void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
        ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
            expressionDescription.name = name.copy;
            expressionDescription.expression = expression;
            expressionDescription.expressionResultType = NSManagedObjectIDResultType;
            
        };
        
        int expressionCount = 6;
        NSExpressionDescription *expressionDescription[expressionCount];
        NSExpression *expressionInQuery[4];
        expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inTable.inDatabase"];
        expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];
        NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                                           rightExpression: expressionInQuery[1]
                                                                                  modifier: NSDirectPredicateModifier
                                                                                      type: NSEqualToPredicateOperatorType
                                                                                   options: 0];
        expressionInQuery[2] = [NSExpression expressionForKeyPath:@"inQueryField.databaseSchemaField"];
        expressionInQuery[3] = [NSExpression expressionForEvaluatedObject];
        NSPredicate *predicate2 = [NSPredicate predicateWithValue:YES];// [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[2]
                                                                    //rightExpression: expressionInQuery[3]
                                                                     //      modifier: NSDirectPredicateModifier
                                                                      //         type: NSEqualToPredicateOperatorType
                                                                       //     options: 0];
        
        
        NSFetchRequest *fetchQueryTable;
        fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabaseSchemaField class])];
        
        expressionDescription[0] = [[NSExpressionDescription alloc] init];
        setupExpression(expressionDescription[0], @"T1", [NSExpression expressionForEvaluatedObject]);
        
        expressionDescription[1] = [[NSExpressionDescription alloc] init];
        setupExpression(expressionDescription[1], @"IQ", [NSExpression expressionForKeyPath:@"inTable"]);

        expressionDescription[2] = [[NSExpressionDescription alloc] init];
        setupExpression(expressionDescription[2], @"TF", [NSExpression expressionForKeyPath:@"inTable.name"]);

        expressionDescription[3] = [[NSExpressionDescription alloc] init];
        setupExpression(expressionDescription[3], @"FF", [NSExpression expressionForKeyPath:@"name"]);

        //expressionDescription[2] = [[NSExpressionDescription alloc] init];
        //setupExpression(expressionDescription[2], @"LT", [NSExpression expressionForKeyPath:@"inTable.inDatabase"]);
        
        
        //expressionDescription[3] = [[NSExpressionDescription alloc] init];
        //setupExpression(expressionDescription[2], @"J1", [NSExpression expressionForSubquery:[NSExpression expressionForKeyPath:@"inQueryField"] usingIteratorVariable:@"field" predicate:predicate2]);

        NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription[0], expressionDescription[1], expressionDescription[2], expressionDescription[3], nil];
        
        //fetchQueryTable.propertiesToGroupBy = @[expressionDescription[1]];
        fetchQueryTable.propertiesToFetch = propertiesToFetch;
        fetchQueryTable.resultType = NSDictionaryResultType;
        fetchQueryTable.predicate = predicate;
        
        results = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
        
        NSLog(@"Results: %@", results);
        
    }
    return _tables;
}

- (NSOrderedSet <MADModelQuery *> *)queries {
    if (!_queries) {
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
    return _queries;
}

- (MADModelQuery *)firstQuery {
    return self.queries.firstObject;
}

@end

@implementation MADModelTable {
    NSOrderedSet <MADModelField *> *_fields;
}

@synthesize fields = _fields;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

    }
    return self;
}

- (NSOrderedSet <MADModelField *> *)fields {
    if (_fields == nil) {
        
    }
    return _fields;
}

@end

#pragma mark -
#pragma mark MADModelField

@implementation MADModelField

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

    }
    return self;
}

@end

#pragma mark -
#pragma mark MADModelQuery

@implementation MADModelQuery {
@protected
    NSOrderedSet <MADModelQueryTable *> *_tables;
    NSOrderedSet <MADModelQueryLink *> *_links;
}

@synthesize tables = _tables;
@synthesize links = _links;

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

    }
    return self;
}

- (NSOrderedSet <MADModelQueryTable *> *)tables {
    if (_tables == nil) {
        [self update];
    }
    return _tables;
}

- (NSOrderedSet <MADModelQueryLink *> *)links {
    if (_links == nil) {
        [self update];
    }
    return _links;
}

- (void)update {
    
    NSManagedObjectContext *managedObjectContext = _managedObjectContext;
    
    NSError * __autoreleasing *error = NULL;
    NSArray <NSManagedObjectID *> *fetchQueryTableResults;
    NSArray <NSManagedObjectID *> *fetchQueryLinksResults;
    
    void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
    ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
        expressionDescription.name = name.copy;
        expressionDescription.expression = expression;
        expressionDescription.expressionResultType = NSManagedObjectIDResultType;
        
    };
    
    int expressionCount = 6;
    NSExpressionDescription *expressionDescription[expressionCount];
    NSExpression *expressionInQuery[2];
    expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inQueryField.inQueryTable.inQuery"];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];
    NSPredicate *predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                                       rightExpression: expressionInQuery[1]
                                                                              modifier: NSDirectPredicateModifier
                                                                                  type: NSEqualToPredicateOperatorType
                                                                               options: 0];
    
    
    NSFetchRequest *fetchQueryTable, *fetchQueryLinks;
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqDatabaseSchemaField class])];
    
    expressionDescription[0] = [[NSExpressionDescription alloc] init];
    setupExpression(expressionDescription[0], @"T1", [NSExpression expressionForEvaluatedObject]);
    
    expressionDescription[1] = [[NSExpressionDescription alloc] init];
    setupExpression(expressionDescription[1], @"IQ", [NSExpression expressionForKeyPath:@"inTable"]);
    
    expressionDescription[2] = [[NSExpressionDescription alloc] init];
    setupExpression(expressionDescription[2], @"LT", [NSExpression expressionForKeyPath:@"inQueryField.inQueryTable"]);

    expressionDescription[3] = [[NSExpressionDescription alloc] init];
    setupExpression(expressionDescription[3], @"RT", [NSExpression expressionForKeyPath:@"inQueryTable.inQuery.hasQueryLinks.hasRightField"]);
    
    expressionDescription[4] = [[NSExpressionDescription alloc] init];
    setupExpression(expressionDescription[4], @"RS", [NSExpression expressionForKeyPath:@"inQueryTable.inQuery.inQueryGroup.hasField"]);

    expressionDescription[5] = [[NSExpressionDescription alloc] init];
    setupExpression(expressionDescription[5], @"BS", [NSExpression expressionForKeyPath:@"inQueryTable.inQuery.inQueryGroup"]);
    
    NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects:expressionDescription[0], expressionDescription[1], /*expressionDescription[2], */ /*expressionDescription[3], expressionDescription[4], expressionDescription[5],*/ nil];
    
    fetchQueryTable.propertiesToGroupBy = @[expressionDescription[1]];
    fetchQueryTable.propertiesToFetch = propertiesToFetch;
    fetchQueryTable.resultType = NSDictionaryResultType;
    //fetchQueryTable.predicate = predicateInQuery;
    
    fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    
    fetchQueryLinks = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];

    NSExpressionDescription *expLeftFieldHasQueryTable = [[NSExpressionDescription alloc] init];
    expLeftFieldHasQueryTable.name = @"LT";
    expLeftFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasLeftField.inQueryTable"];
    expLeftFieldHasQueryTable.expressionResultType = NSManagedObjectIDResultType;
    
    NSExpressionDescription *expRightFieldHasQueryTable = [[NSExpressionDescription alloc] init];
    expRightFieldHasQueryTable.name = @"RT";
    expRightFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasRightField.inQueryTable"];
    expRightFieldHasQueryTable.expressionResultType = NSManagedObjectIDResultType;
    
    NSArray *propertiesToFetch2 = [[NSArray alloc] initWithObjects: expressionDescription[0], expLeftFieldHasQueryTable, expRightFieldHasQueryTable, nil];
    fetchQueryLinks.propertiesToFetch = propertiesToFetch2;
    fetchQueryLinks.resultType = NSDictionaryResultType;
    fetchQueryLinks.predicate = predicateInQuery;
    error = NULL;
    fetchQueryLinksResults = [managedObjectContext executeFetchRequest:fetchQueryLinks error:error];
    
    NSLog(@"%@", fetchQueryLinksResults);
    NSLog(@"%@", fetchQueryTableResults);
    
}

@end

@implementation MADModelQueryTable

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {
    }
    return self;
}

@end

@implementation MADModelQueryLink

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                     leftFieldID:(NSManagedObjectID *)leftFieldID
                     leftTableID:(NSManagedObjectID *)leftTableID
                    rightFieldID:(NSManagedObjectID *)rightFieldID
                    rightTableID:(NSManagedObjectID *)rightTableID {
    
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

        _objectID = objectID.copy;
        id leftField = [[MADModelQueryField alloc] initWithObjectID: leftFieldID
                                                            tableID: leftTableID
                                               managedObjectContext: managedObjectContext];
        _leftField = leftField;

        MADModelQueryField *rightField = [[MADModelQueryField alloc] initWithObjectID: rightFieldID
                                                                              tableID: rightTableID
                                                                 managedObjectContext: managedObjectContext];
        _rightField = rightField;
        
        

    }
    return self;
}

@end

@implementation MADModelQueryField

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID: objectID
                  managedObjectContext: managedObjectContext]) {
    }
    return self;
}

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                         tableID:(NSManagedObjectID *)tableID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID: objectID
                  managedObjectContext: managedObjectContext]) {
        id table = [[MADModelQueryTable alloc] initWithObjectID:tableID
                                           managedObjectContext:managedObjectContext];
        _table = table;
    }
    return self;
}

@end
