//
//  MADModelQuery.m
//  MAD
//
//  Created by Michael on 2/3/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADModelQuery.h"

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSOperation.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>

#import "MADModelDatabase.h"
#import "MADModelQueryTable.h"
#import "MADModelQueryLink.h"

#import "RptqQueryLinks.h"
#import "RptqQueryField.h"

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
    expressions[1] = [NSExpression expressionForConstantValue: self.objectID];
    
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
    expressions[1] = [NSExpression expressionForConstantValue: self.objectID];

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
    debugDescription = self.objectID.URIRepresentation.pathComponents.count == 3 ?
                            [[NSString alloc] initWithFormat:@"%@ <%@::%@> [%@, %@]",
                                                NSStringFromClass([self class]),
                                                self.objectID.URIRepresentation.pathComponents[1],
                                                self.objectID.URIRepresentation.pathComponents[2],
                                                _tables,
                                                _links] :
                            self.debugDescription;
    return debugDescription;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    [debug appendFormat:@"%@", NSStringFromClass([self class]).uppercaseString];
    [debug appendFormat:@"ID:\t%@\n", self.objectID];
    [debug appendFormat:@"Tables:\t%@", _tables];
    [debug appendFormat:@"Tables:\t%@", _tableSchemas];
    [debug appendFormat:@"Links:\t%@", _links];
    return debug;
}

@end
