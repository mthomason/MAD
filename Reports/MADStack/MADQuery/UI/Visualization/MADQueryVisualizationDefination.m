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
//#import "MTGraph+RptqQuery.h"


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
        
        MTGraph *graph = [[MTGraph alloc] initWtthQueryID: queryID];
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
                
                NSManagedObjectID *tableID = tableIdVertext.object;
                
                BOOL topLevel = YES;

                NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = queryID.links.objectEnumerator;
                for (MADModelQueryLink *link in queryLinkEnumerator) {
                    if ([link.rightFieldReference.tableID isEqual:tableID]) {
                        topLevel = NO;
                        break;
                    }
                }
                
                if (topLevel) {
                    NSURL *url = tableID.URIRepresentation.copy;
                    [startingPoints addObject:url];
                }
                
            }
        }
        
        self.startingPoints = startingPoints;
        self.directedAcyclicGraph = isDirectedAcyclicGraph;
        
    }
    return self;
}

@end
