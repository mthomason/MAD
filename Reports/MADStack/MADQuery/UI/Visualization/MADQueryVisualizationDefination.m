//
//  MADQueryVisulizationDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationDefination.h"
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchRequest.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>
#import <MAD/RptqQuery.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>
#import <MAD/MADocument.h>
#import <MAD/MADModel.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTGraph.h>
#import "MTGraph+RptqQuery.h"


@interface MADQueryVisualizationDefination()

    @property (nonatomic, strong, readwrite) MTGraph *graphRepresentation;
    @property (nonatomic, strong, readwrite) MTLinkedList *topologicallySortedTables;
    @property (nonatomic, strong, readwrite) NSArray <NSURL *> *startingPoints;
    @property (nonatomic, assign, readwrite, getter=isDirectedAcyclicGraph) BOOL directedAcyclicGraph;

@end

@implementation MADQueryVisualizationDefination

- (instancetype)initWithQuery:(MADModelQuery *)queryID {
    if (self = [super init]) {
        
        NSManagedObjectContext *managedObjectContext = queryID.managedObjectContext;
        MTGraph *graph = [[MTGraph alloc] initWithQueryID:queryID.objectID managedObjectContext:managedObjectContext];
        self.graphRepresentation = graph;
        
        NSError * __autoreleasing *error = NULL;
        BOOL isDirectedAcyclicGraph;
        MTLinkedList *tableIds;
        tableIds = [graph topologicalSortWithError: error
                            isDirectedAcyclicGraph: &isDirectedAcyclicGraph];
        self.topologicallySortedTables = tableIds;
        
        NSMutableArray *startingPoints = [[NSMutableArray alloc] init];
        for (MTPair *tableObjectIdContainer in tableIds) {
            MTVertex *tableIdVertext = tableObjectIdContainer.former;
            
            if (tableIdVertext.object != nil) {
                
                NSManagedObjectID *table = [tableIdVertext.object copy];
                
                BOOL topLevel = YES;
                
                
                NSArray <NSManagedObjectID *> *fetchQueryLinksResults;
                NSFetchRequest *fetchQueryLinks;
                
                NSExpression *expressionInQuery[2];
                expressionInQuery[0] = [NSExpression expressionForKeyPath:@"inQuery"];
                expressionInQuery[1] = [NSExpression expressionForConstantValue: queryID];
                NSPredicate *predicateInQuery = [NSComparisonPredicate predicateWithLeftExpression: expressionInQuery[0]
                                                                                   rightExpression: expressionInQuery[1]
                                                                                          modifier: NSDirectPredicateModifier
                                                                                              type: NSEqualToPredicateOperatorType
                                                                                           options: 0];

                fetchQueryLinks = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([RptqQueryLinks class])];
                NSExpressionDescription *expRightFieldHasQueryTable = [[NSExpressionDescription alloc] init];
                expRightFieldHasQueryTable.name = @"RT";
                expRightFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasRightField.inQueryTable"];
                expRightFieldHasQueryTable.expressionResultType = NSManagedObjectIDResultType;
                NSExpressionDescription *expSelf = [[NSExpressionDescription alloc] init];
                expSelf.name = @"T1";
                expSelf.expression = [NSExpression expressionForEvaluatedObject];
                expSelf.expressionResultType = NSManagedObjectIDResultType;
                NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects: expSelf, expRightFieldHasQueryTable, nil];
                fetchQueryLinks.propertiesToFetch = propertiesToFetch;
                fetchQueryLinks.resultType = NSDictionaryResultType;
                fetchQueryLinks.predicate = predicateInQuery;
                error = NULL;
                fetchQueryLinksResults = [managedObjectContext executeFetchRequest:fetchQueryLinks error:error];
                
                /*
                for (RptqQueryLinks *link in query.hasQueryLinks) {
                    RptqQueryTable *rightQueryTable = link.hasRightField.inQueryTable;
                    if ([rightQueryTable.objectID isEqual:table]) {
                        topLevel = NO;
                        break;
                    }
                }
                
                if (topLevel) {
                    NSURL *url = table.objectID.URIRepresentation.copy;
                    [startingPoints addObject:url];
                }
                */
            }
        }
        
        NSArray *points = [[NSArray alloc] initWithArray:startingPoints];
        self.startingPoints = points;
        self.directedAcyclicGraph = isDirectedAcyclicGraph;
        
    }
    return self;
}
/*
- (instancetype)initWithQuery:(RptqQuery *)query {
    if (self = [super init]) {
        
        MTGraph *graph = [[MTGraph alloc] initWithQuery:query];
        self.graphRepresentation = graph;

        NSError *error = nil;
        BOOL isDirectedAcyclicGraph;
        MTLinkedList *tableIds;
        tableIds = [graph topologicalSortWithError:&error
                            isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
        self.topologicallySortedTables = tableIds;
        
        NSMutableArray *startingPoints = [[NSMutableArray alloc] init];
        for (MTPair *tableObjectIdContainer in tableIds) {
            MTVertex *tableIdVertext = tableObjectIdContainer.former;
            
            if (tableIdVertext.object != nil) {
                
                RptqQueryTable *table = (RptqQueryTable *)[query.managedObjectContext objectWithID:tableIdVertext.object];
                
                BOOL topLevel = YES;
                for (RptqQueryLinks *link in query.hasQueryLinks) {
                    RptqQueryTable *rightQueryTable = link.hasRightField.inQueryTable;
                    if ([rightQueryTable.objectID isEqual:table.objectID]) {
                        topLevel = NO;
                        break;
                    }
                }
                
                if (topLevel) {
                    NSURL *url = table.objectID.URIRepresentation.copy;
                    [startingPoints addObject:url];
                }
            }
        }
        
        NSArray *points = [[NSArray alloc] initWithArray:startingPoints];
        self.startingPoints = points;
        self.directedAcyclicGraph = isDirectedAcyclicGraph;
        
    }
    return self;
}
*/
@end
