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

#import <MADFoundation/NSString+Common.h>

#import "MADModelDatabase.h"
#import "MADModelQueryTable.h"
#import "MADModelQueryLink.h"

#import "RptqQueryLinks.h"
#import "RptqQueryTable.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"

#import "NSPredicate+Creators.h"

@interface MADModelQuery ()

    @property (nonatomic, weak, readonly) MADModelDatabase *database;

    - (void)deleteQueryTableID:(NSNumber *)queryTable;
    - (void)deleteQueryLinkID:(NSNumber *)queryLink;
    - (void)insertQueryTableID:(NSNumber *)queryTableID;
    - (void)insertQueryLinkID:(NSNumber *)queryLinkID;
@end

#pragma mark -
#pragma mark MADModelQuery

@implementation MADModelQuery {
  @protected
    NSMutableOrderedSet <NSNumber *> *_queryTableIDs;
    NSMutableOrderedSet <NSNumber *> *_queryLinkIDs;
    NSMutableDictionary <NSNumber *, MADModelQueryTable *> *_tables;
    //NSMutableDictionary <NSNumber *, MADModelTable *> *_tableSchemas;
    NSMutableDictionary <NSNumber *, MADModelQueryLink *> *_links;
    NSManagedObjectContext * __weak _managedObjectContext;
}
    @synthesize managedObjectContext = _managedObjectContext;

- (void)dealloc {
    [_queryTableIDs removeAllObjects];
    [_queryLinkIDs removeAllObjects];
    [_tables removeAllObjects];
    [_links removeAllObjects];
    _inDatabase = nil;
    _managedObjectContext = nil;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
            managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    if (self = [super initWithIdentifier:identifier]) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}

- (instancetype)initWithIdentifier:(int64_t)identifier
                          database:(MADModelDatabase *)database {
    if (self = [self initWithIdentifier: identifier
                 managedObjectContext: database.managedObjectContext]) {
        _inDatabase = database;
    }
    return self;
}

- (NSOrderedSet <NSNumber *> *)queryTableIDs {
    if (_queryTableIDs == nil) {
        @autoreleasepool {

            if (_tables == nil) {
                NSMutableDictionary <NSNumber *, MADModelQueryTable *> *tables;
                tables = [[NSMutableDictionary alloc] init];
                _tables = tables;
            }
            
            NSMutableOrderedSet <NSNumber *> *tableIDs;
            tableIDs = [[NSMutableOrderedSet alloc] init];
            _queryTableIDs = tableIDs;
            
            [self updateTables];
        }
    }
    return _queryTableIDs;
}

- (NSOrderedSet <NSNumber *> *)queryLinkIDs {
    if (_queryLinkIDs == nil) {
        @autoreleasepool {
            
            NSMutableDictionary <NSNumber *, MADModelQueryLink *> *links;
            links = [[NSMutableDictionary alloc] init];
            _links = links;
            
            NSMutableOrderedSet <NSNumber *> *queryLinkIDs;
            queryLinkIDs = [[NSMutableOrderedSet alloc] init];
            _queryLinkIDs = queryLinkIDs;

            [self updateLinks];
        }
    }
    return _queryLinkIDs;
}

- (NSMutableDictionary <NSNumber *, MADModelQueryTable *> *)tables {
    if (_tables == nil) {
        @autoreleasepool {
            NSMutableDictionary <NSNumber *, MADModelQueryTable *> *tables;
            tables = [[NSMutableDictionary alloc] init];
            _tables = tables;
            
            if (_queryTableIDs == nil) {
                NSMutableOrderedSet <NSNumber *> *tableIDs;
                tableIDs = [[NSMutableOrderedSet alloc] init];
                _queryTableIDs = tableIDs;
            }
            [self updateTables];
        }
    }
    return _tables;
}

- (NSMutableDictionary <NSNumber *, MADModelQueryLink *> *)links {
    if (_links == nil) {
        @autoreleasepool {
            
            NSMutableDictionary <NSNumber *, MADModelQueryLink *> *links;
            links = [[NSMutableDictionary alloc] init];
            _links = links;

            NSMutableOrderedSet <NSNumber *> *queryLinkIDs;
            queryLinkIDs = [[NSMutableOrderedSet alloc] init];
            _queryLinkIDs = queryLinkIDs;
            
            [self updateLinks];
        }
    }
    return _links;
}

/*- (NSSet <MADTableFieldReference *> *)tableFieldReferencesInLinks {
    NSEnumerator <MADModelQueryLink *> *links = _links.objectEnumerator;
    MADModelQueryLink *link;
    NSSet *tablesInLinks;
    tablesInLinks = [[NSMutableSet alloc] initWithCapacity:_links.count * 2];
    for (link in links) {
        tablesInLinks = [tablesInLinks setByAddingObjectsFromSet: link.tableFieldReferences];
    }
    return tablesInLinks;
}*/

- (NSSet <NSNumber *> *)tablesInLinks {
    NSEnumerator <MADModelQueryLink *> *links = _links.objectEnumerator;
    MADModelQueryLink *link;
    NSSet <NSNumber *> *tablesInLinks;
    tablesInLinks = [[NSMutableSet alloc] initWithCapacity:_links.count * 2];
    for (link in links) {
        tablesInLinks = [tablesInLinks setByAddingObjectsFromSet: link.tables];
        
    }
    return tablesInLinks;
}


- (NSSet <NSNumber *> *)orphanedQueryTables {
    NSSet <NSNumber *> *orphanedQueryTables;
    NSExpression *expressionMinusSet;
    NSSet <NSNumber *> * joinedTables = [self tablesInLinks];
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
    
    NSError * __autoreleasing error = NULL;
    NSArray <NSDictionary *> *fetchQueryTableResults;
    
    NSFetchRequest *fetchQueryTable = [RptqQueryField fetchRequestFieldKeys: self.identifier];
    
    fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable
                                                                 error:&error];
    NSAssert(fetchQueryTableResults != nil && error == NULL, @"What? %@", error);

    [self insertTablesFromFetchRequestResults:fetchQueryTableResults];


}

- (void)insertTableRptqQueryTable:(RptqQueryTable *)queryTable {
    if (queryTable == nil) return;
    
    MADModelQueryTable *modelQueryTable;
    modelQueryTable = [[MADModelQueryTable alloc] initWithIdentifier: queryTable.identifier
                                                           dropIndex: queryTable.dropIndex
                                                         schemaTable: queryTable.databaseSchemaTable.identifier
                                                          inDatabase: _inDatabase];
    
    for (RptqQueryField *queryField in queryTable.hasQueryFields) {
        [modelQueryTable addField: queryField.identifier
                      schemaField: queryField.databaseSchemaField.identifier];
        NSNumber *qtidn = @(modelQueryTable.identifier);
        [_queryTableIDs addObject:qtidn];
        [_tables setObject:modelQueryTable forKey:qtidn];
    }
}

- (void)insertTablesFromFetchRequestResults:(NSArray <NSDictionary *> *)results {
    if (!results.count) return;
    
    NSArray <NSManagedObjectID *> *tableValues;
    NSString *keyInQueryTable = [RptqQueryField keyInQueryTable];
    tableValues = [results valueForKey:keyInQueryTable];
    
    NSOrderedSet <NSManagedObjectID *> *tableObjectIDs;
    tableObjectIDs = [[NSOrderedSet alloc] initWithArray: tableValues copyItems:NO];
    
    NSString *dropIndex = [NSStringFromSelector(@selector(inQueryTable)) stringByAppendingPeriod];
    dropIndex = [dropIndex stringByAppendingString:NSStringFromSelector(@selector(dropIndex))];
    
    NSString *keySchemaTableID = [RptqQueryField keySchemaTableID];
    NSString *keyQueryTableID = [RptqQueryField keyQueryTableID],
             *keyQueryFieldID = [RptqQueryField keyQueryFieldID],
             *keySchemaFieldID = [RptqQueryField keySchemaFieldID];
    
    NSComparisonPredicate *predicateTable;
    NSExpression *tablePath = [NSExpression expressionForKeyPath: keyInQueryTable], *tableValue;
    NSArray *fresults;
    int64_t stid = -1, qtid = -1, sfid = -1, qfid = -1, di = -1;
    @autoreleasepool {
        
        NSDictionary *filteredResult;
        NSManagedObjectID *tableObjectID;
        NSNumber *qtidn;
        for (tableObjectID in tableObjectIDs) {
            
            @autoreleasepool {
                
                tableValue = [NSExpression expressionForConstantValue: tableObjectID];
                predicateTable = [NSComparisonPredicate predicateWithLeftExpression: tablePath
                                                                    rightExpression: tableValue
                                                                           modifier: NSDirectPredicateModifier
                                                                               type: NSEqualToPredicateOperatorType
                                                                            options: 0];
                fresults = [results filteredArrayUsingPredicate:predicateTable];
                
                NSUInteger resultCounter = 0;
                MADModelQueryTable *queryTable;
                for (filteredResult in fresults) {
                    CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[keySchemaTableID], kCFNumberSInt64Type, &stid);
                    CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[keySchemaFieldID], kCFNumberSInt64Type, &sfid);
                    CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[keyQueryTableID], kCFNumberSInt64Type, &qtid);
                    CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[keyQueryFieldID], kCFNumberSInt64Type, &qfid);
                    CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)filteredResult[dropIndex], kCFNumberSInt64Type, &di);

                    if (resultCounter == 0) {

                        queryTable = [[MADModelQueryTable alloc] initWithIdentifier: qtid
                                                                          dropIndex: di
                                                                        schemaTable: stid
                                                                         inDatabase: _inDatabase];

                    }
                    
                    [queryTable addField: qfid schemaField: sfid];
                    resultCounter++;
                }
                qtidn = @(qtid);
                [_queryTableIDs addObject:qtidn];
                [_tables setObject:queryTable forKey:qtidn];
            }
        }
    }
}

- (void)insertLinksFromFetchRequestResults:(NSArray <NSDictionary *> *)results {
    if (!results.count) return;

    NSArray <NSNumber *> *queryLinkIDsFiltered;
    queryLinkIDsFiltered = [results valueForKey:MADKeyQueryLinkID];
    [_queryLinkIDs addObjectsFromArray:queryLinkIDsFiltered];
    
    NSNumber *queryLinkID;
    MADModelQueryLink *queryLink;
    NSPredicate *predicate;
    NSExpression *expressionKeyPath = [NSExpression expressionForKeyPath:MADKeyQueryLinkID];
    
    for (queryLinkID in _queryLinkIDs) {
        
        predicate = [NSPredicate newPredicateObjectWithNumber:queryLinkID
                                                andExpression:expressionKeyPath];
        
        NSArray *fresults = [results filteredArrayUsingPredicate:predicate];
        
        int64_t qlid = -1, ltid = -1, lfid = -1, rtid = -1, rfid = -1;
        for (NSDictionary *result in fresults) {

            NSNumber *qlidObj = (NSNumber *)result[MADKeyQueryLinkID];
            
            CFNumberGetValue((__bridge CFNumberRef)qlidObj, kCFNumberSInt64Type, &qlid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkLeftTableID], kCFNumberSInt64Type, &ltid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkLeftFieldID], kCFNumberSInt64Type, &lfid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkRightTableID], kCFNumberSInt64Type, &rtid);
            CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)result[MADKeyQueryLinkRightFieldID], kCFNumberSInt64Type, &rfid);
            
            queryLink = [[MADModelQueryLink alloc] initWithIdentifier: qlid
                                                          leftFieldID: lfid
                                                          leftTableID: ltid
                                                         rightFieldID: rfid
                                                         rightTableID: rtid];
            [_links setObject:queryLink forKey:qlidObj];
            
        }
    }

}

// Fetches the needed data from RptqQueryLinks.
// It creates MADModelQueryLink objects.
- (void)updateLinks {

    NSArray <NSDictionary *> *fetchQueryLinksResults;
    NSFetchRequest *fetch;

    NSString *keyInQuery = NSStringFromSelector(@selector(inQuery));
    NSString *keyIdentifier = NSStringFromSelector(@selector(identifier));
    NSString *inQueryTableID = [keyInQuery stringByAppendingPeriod];
    inQueryTableID = [inQueryTableID stringByAppendingString: keyIdentifier];

    NSPredicate *predicate = [NSPredicate newPredicateObjectWithIdentifier:self.identifier
                                                                 atKeyPath:inQueryTableID];
 
    fetch = [MADModelQueryLink fetchRequest:predicate];
    
    NSError * __autoreleasing error = NULL;
    fetchQueryLinksResults = [_managedObjectContext executeFetchRequest:fetch error:&error];
    NSAssert(fetchQueryLinksResults != nil && error == nil, @"Need this to work! %@", error);

    [self insertLinksFromFetchRequestResults:fetchQueryLinksResults];
}

- (void)update { }

// #MARK: Insert

- (void)insertQueryTable:(RptqQueryTable *)queryTable {
    MADModelQueryTable *table;
    NSNumber *queryTableID = @(queryTable.identifier);
    if ((table = [_tables objectForKey:queryTableID])) return;
    [self insertTableRptqQueryTable:queryTable];
    table = [_tables objectForKey:queryTableID];
    
    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:table, queryTableID, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationQueryTableInsert
                                                            object: self
                                                          userInfo: userInfo];
    }];
}

- (void)insertQueryTableID:(NSNumber *)queryTableID
      managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    MADModelQueryTable *table;
    if ((table = [_tables objectForKey:queryTableID])) return;
    
    NSArray <NSDictionary *> *results;
    
    NSError * __autoreleasing error = NULL;
    NSFetchRequest *fetchRequest = [RptqQueryField fetchRequestFieldKeys:queryTableID.longLongValue];
    results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    NSAssert(results != nil && error == nil, @"What? %@", error);
    [self insertTablesFromFetchRequestResults:results];
    table = [_tables objectForKey:queryTableID];
    
    NSDictionary *userInfo;
    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:table, queryTableID, nil];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName: MADNotificationQueryTableInsert
                                                            object: self
                                                          userInfo: userInfo];
    }];
}

- (void)insertQueryTableID:(NSNumber *)queryTableID {
    [self insertQueryTableID:queryTableID managedObjectContext:_managedObjectContext];
}


/// FIXME: Predicate is broken... maybe more... unused, but I think it's needed.
- (void)insertQueryLinkID:(NSNumber *)queryLinkID
     managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
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
    NSError * __autoreleasing error = NULL;
    NSFetchRequest *fetchRequest = [MADModelQueryLink fetchRequest:isQueryLink];
    results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    NSAssert(results != nil && error == nil, @"What? %@", error);
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

- (void)insertQueryLinkID:(NSNumber *)queryLinkID {
    [self insertQueryLinkID:queryLinkID managedObjectContext:_managedObjectContext];
}


// #MARK: Delete

- (void)deleteQueryLinkID:(NSNumber *)queryLink {
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

- (void)deleteQueryTableID:(NSNumber *)queryTable {
    MADModelQueryTable *table;
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

/*- (NSString *)debugDescription {
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
}*/

@end
