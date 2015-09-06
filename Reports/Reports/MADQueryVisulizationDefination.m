//
//  MADQueryVisulizationDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisulizationDefination.h"
#import "MTLinkedList.h"
#import "MTGraph.h"
#import "MTVertex.h"
#import "MTObject.h"
#import "RptqQuery.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqQueryTable.h"
#import "RptqQueryLinks.h"
#import "RptqQueryField.h"
#import "MTGraph+RptqQuery.h"

@interface MADQueryVisulizationDefination()

@property (nonatomic, strong, readwrite) MTGraph *graphRepresentation;
@property (nonatomic, strong, readwrite) MTLinkedList *topologicallySortedTables;
@property (nonatomic, strong, readwrite) NSArray *startingPoints;
@property (nonatomic, assign, readwrite, getter=isDirectedAcyclicGraph) BOOL directedAcyclicGraph;

@end

@implementation MADQueryVisulizationDefination

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
