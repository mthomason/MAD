//
//  MTGraph+RptqQuery.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTGraph+RptqQuery.h"

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
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSException.h>
#import <Foundation/NSMapTable.h>

#import <MAD/RptqQuery.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>

#import <MADDataStructures/MTVertex.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADTableFieldIdentifier.h>

@implementation MTGraph (RptqQuery)

- (instancetype)initWtthQueryID:(MADModelQuery *)query {
    if (self = [self init]) {
        
        [query.queryTableIDs  enumerateObjectsUsingBlock:^(NSNumber * _Nonnull tableID,
                                                           NSUInteger idx, BOOL * _Nonnull stop) {
            [self addVertexWithObject: tableID];
        }];
        
        NSNumber *weight = @(1);
        
        NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = query.links.objectEnumerator;
        for (MADModelQueryLink *link in queryLinkEnumerator) {
            MTVertex *vertexOrigin =        [self vertexForObject:@(link.leftFieldIdentifier.tableID)];
            MTVertex *vertexDestination =   [self vertexForObject:@(link.rightFieldIdentifier.tableID)];
            
            [self addEdgeWithOrigin: vertexOrigin
                        destination: vertexDestination
                             object: @(link.identifier)
                          andWeight: weight];
        }
    }
    return self;
}

- (instancetype)initWithQueryID:(NSManagedObjectID *)queryID
           managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    if (self = [self init]) {

        NSError * __autoreleasing *error = NULL;
        NSArray <NSManagedObjectID *> *fetchQueryTableResults;
        NSArray <NSManagedObjectID *> *fetchQueryLinksResults;

        NSExpression *expressionInQuery[2];
        expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inQuery"];
        expressionInQuery[1] = [NSExpression expressionForConstantValue: queryID];
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
        
        NSAssert(error == nil, @"Got error %@", *error);
        
        //Add a vertex to the graph for each table.
        NSManagedObjectID *objectID;
        for (objectID in fetchQueryTableResults) {
            @autoreleasepool {
                [self addVertexWithObject: objectID.copy];
            }
        }
        objectID = nil;
        
        //Create an edge in the graph for each query link.
        NSNumber *weight = @(1);
        
        MTVertex *vertexOrigin;
        MTVertex *vertexDestination;
        NSDictionary <NSString *, NSManagedObjectID *> *queryLinkObjectIDS;
        for (queryLinkObjectIDS in fetchQueryLinksResults) {
            //@autoreleasepool {
                // T1 is the queryLink objectID
                //queryLink.inQuery
                // LT is the left query table objectID
                //queryLink.hasLeftField.inQueryTable.objectID
                // RT is the right query table objectID
                //queryLink.hasRightField.inQueryTable.objectID
                
                vertexOrigin =        [[self vertexForObject:(MTObject *)queryLinkObjectIDS[@"LT"]] copy];
                
                vertexDestination =   [[self vertexForObject:(MTObject *)queryLinkObjectIDS[@"RT"]] copy];
                
                [self addEdgeWithOrigin: vertexOrigin
                            destination: vertexDestination
                                 object: [queryLinkObjectIDS[@"T1"] copy]
                              andWeight: weight.copy];
            //}
        }
        vertexOrigin = nil;
        vertexDestination = nil;
    }
    
    return self;
}

- (instancetype)initWithQuery:(RptqQuery *)query {
    NSManagedObjectContext *managedObjectContext = query.managedObjectContext;
    NSManagedObjectID *queryID = query.objectID;
    return [self initWithQueryID:queryID managedObjectContext:managedObjectContext];
}

@end
