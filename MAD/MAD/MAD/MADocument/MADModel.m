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

@interface MADObjectID ()
    - (instancetype)newObjectIDDocument:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;
    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_DESIGNATED_INITIALIZER;
@end

@interface MADModelDocument ()
    - (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readwrite, strong) NSMutableOrderedSet <MADModelDatabase *> *databaseIDs;
@end

@interface MADModelDatabase ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                             queryID:(NSManagedObjectID *)queryID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readwrite, strong) NSMutableOrderedSet <MADModelQuery *> *queryIDs;
@end

@interface MADModelQuery ()
    - (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
                managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    @property (nonatomic, readwrite, strong) NSOrderedSet <MADModelQueryTable *> *tableIDs;
    @property (nonatomic, readwrite, strong) NSOrderedSet <MADModelQueryLink *> *linkIDs;
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

- (NSMutableOrderedSet <MADModelDatabase *> *)databaseIDs {
    if (!_databaseIDs) {
        [self update];
    }
    return _databaseIDs;
}

- (NSManagedObjectID *)objectID {
    if (!_objectID) {
        _objectID = [self fetchDocumentObjectID].copy;
    }
    return _objectID;
}

- (MADModelDatabase *)firstDatabase {
    return self.databaseIDs.firstObject;
}

- (MADModelQuery *)firstQuery {
    return self.firstDatabase.firstQuery;
}

//Load all the databases and queries for this document.  This is because current versions
// of the software only use one database and query.

- (void)update {
    if (_objectID == nil || _databaseIDs == nil) {
        NSArray <NSManagedObjectID *> *result;
        NSFetchRequest *request;
        
        void (^setupExpression)(NSExpressionDescription *, NSString *, NSExpression *) =
        ^void(NSExpressionDescription *expressionDescription, NSString *name, NSExpression *expression) {
            expressionDescription.name = name.copy;
            expressionDescription.expression = expression;
            expressionDescription.expressionResultType = NSManagedObjectIDResultType;
            
        };
        
        NSExpressionDescription *expressionDescription[3];
        NSManagedObjectContext *managedObjectContext;
        managedObjectContext = _managedObjectContext;
        
        expressionDescription[0] = [[NSExpressionDescription alloc] init];
        expressionDescription[1] = [[NSExpressionDescription alloc] init];
        expressionDescription[2] = [[NSExpressionDescription alloc] init];
        
        request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
        
        NSString *keyDatabase = @"DA", *keyQuery = @"QU", *keyDocument = @"DO";
        
        NSString *inDatabase = NSStringFromSelector(@selector(inDatabase));
        NSString *inDocument = NSStringFromSelector(@selector(ownedByQueryAsStaticResource));
        
        setupExpression(expressionDescription[0], keyDatabase,
                        [NSExpression expressionForKeyPath:inDatabase]);

        setupExpression(expressionDescription[1], keyDocument,
                        [NSExpression expressionForKeyPath:[NSString stringWithFormat:@"%@.%@",
                                                                inDatabase,
                                                                inDocument]]);
        
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
        NSMutableOrderedSet <MADModelDatabase *> *databaseIDs;
        databaseIDs = [[NSMutableOrderedSet <MADModelDatabase *> alloc] initWithCapacity:result.count];
        MADModelDatabase *databaseInnerObjectID;
        NSUInteger i = 0;

        NSDictionary <NSString *, NSManagedObjectID *> *resultWrapper;
        for (resultWrapper in result) {
            if (i == 0) {
                _objectID = resultWrapper[keyDocument].copy;
            }
            databaseInnerObjectID = [[MADModelDatabase alloc] initWithObjectID:resultWrapper[keyDatabase]
                                                                       queryID:resultWrapper[keyQuery]
                                                          managedObjectContext:managedObjectContext];
            [databaseIDs addObject: databaseInnerObjectID];
            databaseInnerObjectID = nil;
            i++;
        }
        expressionDescription[0] = nil;
        expressionDescription[1] = nil;
        expressionDescription[2] = nil;
        inDatabase = nil;
        inDocument = nil;
        
        _databaseIDs = databaseIDs;

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

@implementation MADModelDatabase

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
        
        NSMutableOrderedSet <MADModelQuery *> *queryIDs;
        queryIDs = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];

        queryObjectID = [[MADModelQuery alloc] initWithObjectID:queryID
                                           managedObjectContext:managedObjectContext];
        [queryIDs addObject: queryObjectID];
        _queryIDs = queryIDs;
    }
    return self;
}

- (NSMutableOrderedSet <MADModelQuery *> *)queryIDs {
    if (!_queryIDs) {
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
        
        NSMutableOrderedSet <MADModelQuery *> *queryIDs;
        queryIDs = [[NSMutableOrderedSet <MADModelQuery *> alloc] init];
        MADModelQuery *queryObjectID;
        NSUInteger i = 0;
        for (NSManagedObjectID *objid in result) {
            queryObjectID = [[MADModelQuery alloc] initWithObjectID:objid
                                               managedObjectContext:managedObjectContext];
            [queryIDs addObject: queryObjectID];
            queryObjectID = nil;
            i++;
        }
        _queryIDs = queryIDs;
        result = nil;;
        request = nil;
        predicate = nil;
        expression[0] = nil;
        expression[1] = nil;
    }
    return _queryIDs;
}

- (MADModelQuery *)firstQuery {
    return self.queryIDs.firstObject;
}

@end

#pragma mark -
#pragma mark MADModelQuery

@implementation MADModelQuery

- (instancetype)initWithObjectID:(NSManagedObjectID *)objectID
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithObjectID:objectID
                  managedObjectContext:managedObjectContext]) {

    }
    return self;
}

- (NSOrderedSet <MADModelQueryTable *> *)tableIDs {
    if (_tableIDs == nil) {
        [self update];
    }
    return _tableIDs;
}

- (NSOrderedSet <MADModelQueryLink *> *)linkIDs {
    if (_linkIDs == nil) {
        [self update];
    }
    return _linkIDs;
}

- (void)update {
    
    NSManagedObjectContext *managedObjectContext;
    
    NSError * __autoreleasing *error = NULL;
    NSArray <NSManagedObjectID *> *fetchQueryTableResults;
    NSArray <NSManagedObjectID *> *fetchQueryLinksResults;
    
    NSExpression *expressionInQuery[2];
    expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inQuery"];
    expressionInQuery[1] = [NSExpression expressionForConstantValue: _objectID];
    NSPredicate *predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                                       rightExpression: expressionInQuery[1]
                                                                              modifier: NSDirectPredicateModifier
                                                                                  type: NSEqualToPredicateOperatorType
                                                                               options: 0];
    
    
    NSFetchRequest *fetchQueryTable, *fetchQueryLinks;
    fetchQueryTable = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryTable class])];
    fetchQueryLinks = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];
    
    NSExpressionDescription *expSelf = [[NSExpressionDescription alloc] init];
    expSelf.name = @"T1";
    expSelf.expression = [NSExpression expressionForEvaluatedObject];
    expSelf.expressionResultType = NSManagedObjectIDResultType;
    
    NSExpressionDescription *expQuery = [[NSExpressionDescription alloc] init];
    expQuery.name = @"IQ";
    expQuery.expression = [NSExpression expressionForKeyPath:@"inQuery"];
    expQuery.expressionResultType = NSManagedObjectIDResultType;
    
    NSArray *propertiesToFetch1 = [[NSArray alloc] initWithObjects:expSelf, expQuery, nil];
    
    fetchQueryTable.propertiesToFetch = propertiesToFetch1;
    fetchQueryTable.resultType = NSManagedObjectIDResultType;
    fetchQueryTable.predicate = predicateInQuery;
    
    fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable error:error];
    
    
    NSExpressionDescription *expLeftFieldHasQueryTable = [[NSExpressionDescription alloc] init];
    expLeftFieldHasQueryTable.name = @"LT";
    expLeftFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasLeftField.inQueryTable"];
    expLeftFieldHasQueryTable.expressionResultType = NSManagedObjectIDResultType;
    
    NSExpressionDescription *expRightFieldHasQueryTable = [[NSExpressionDescription alloc] init];
    expRightFieldHasQueryTable.name = @"RT";
    expRightFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasRightField.inQueryTable"];
    expRightFieldHasQueryTable.expressionResultType = NSManagedObjectIDResultType;
    
    NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects: expSelf, expLeftFieldHasQueryTable, expRightFieldHasQueryTable, nil];
    fetchQueryLinks.propertiesToFetch = propertiesToFetch;
    fetchQueryLinks.resultType = NSDictionaryResultType;
    fetchQueryLinks.predicate = predicateInQuery;
    error = NULL;
    fetchQueryLinksResults = [managedObjectContext executeFetchRequest:fetchQueryLinks error:error];
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
        _leftFieldIDs = leftField;

        MADModelQueryField *rightField = [[MADModelQueryField alloc] initWithObjectID: rightFieldID
                                                                              tableID: rightTableID
                                                                 managedObjectContext: managedObjectContext];
        _rightFieldIDs = rightField;
        
        

    }
    return self;
}

@end

@implementation MADModelQueryField : MADObjectID

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
