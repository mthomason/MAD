//
//  MADQueryVisulizationDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationDefination.h"
#import "MTGraph+RptqQuery.h"
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>
#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTVertex.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

@interface MADQueryVisualizationDefination()

@property (nonatomic, strong, readwrite) MTGraph *graphRepresentation;
@property (nonatomic, strong, readwrite) MTLinkedList *topologicallySortedTables;
@property (nonatomic, strong, readwrite) NSArray *startingPoints;
@property (nonatomic, assign, readwrite, getter=isDirectedAcyclicGraph) BOOL directedAcyclicGraph;

@end

@implementation MADQueryVisualizationDefination

- (instancetype)initWithQuery:(RptqQuery *)query {
    if (self = [super init]) {
        
        MTGraph *graph = [[MTGraph alloc] initWithQuery:query];
        self.graphRepresentation = graph;

        NSError *error = nil;
        BOOL isDirectedAcyclicGraph;
        MTLinkedList *tableIds = [graph topologicalSortWithError:&error isDirectedAcyclicGraph:&isDirectedAcyclicGraph];
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
                    [startingPoints addObject:table.objectID.URIRepresentation];
                }
            }
        }

        self.startingPoints = [NSArray arrayWithArray:startingPoints];
        self.directedAcyclicGraph = isDirectedAcyclicGraph;
        
    }
    return self;
}

@end
