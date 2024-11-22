//
//  MADQueryVisulizationDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryVisualizationModel.h"

#import <Foundation/NSURL.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSMapTable.h>

#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSFetchRequest.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADTableFieldIdentifier.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTGraph.h>

#import "MTGraph+RptqQuery.h"

@interface MADQueryVisualizationModel()

	@property (nonatomic, strong, readwrite) MTGraph *graphRepresentation;
	@property (nonatomic, strong, readwrite) MTLinkedList *topologicallySortedTables;
	@property (nonatomic, strong, readwrite) NSArray <NSNumber *> *startingPoints;
	@property (nonatomic, assign, readwrite, getter=isDirectedAcyclicGraph) BOOL directedAcyclicGraph;

@end

@implementation MADQueryVisualizationModel

- (instancetype)initWithQuery:(MADModelQuery *)queryID {
	if (self = [super init]) {
				
		MTGraph *graph = [[MTGraph alloc] initWtthQueryID: queryID];
		self.graphRepresentation = graph;
		
		NSError * __autoreleasing error = NULL;
		BOOL isDirectedAcyclicGraph, topLevel;
		MTLinkedList *tableIDs;

		tableIDs = [graph topologicalSortWithError: &error
							isDirectedAcyclicGraph: &isDirectedAcyclicGraph];
		
		self.topologicallySortedTables = tableIDs;
		
		NSMutableArray <NSNumber *> *startingPoints = [[NSMutableArray alloc] init];
		MTVertex *tableIdVertext;
		NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator;

		NSNumber *tableID;
		MADModelQueryLink *link;
		for (MTPair *tableObjectIdContainer in tableIDs) {
			tableIdVertext = tableObjectIdContainer.former;
			
			if (tableIdVertext.object != nil) {
				
				tableID = tableIdVertext.object;
				topLevel = YES;

				queryLinkEnumerator = queryID.links.objectEnumerator;
				for (link in queryLinkEnumerator) {
					if (link.rightFieldIdentifier.tableID == tableID.longLongValue) {
						topLevel = NO;
						break;
					}
				}
				
				if (topLevel) {
					[startingPoints addObject:tableID];
				}
			}
		}

		self.startingPoints = startingPoints;
		self.directedAcyclicGraph = isDirectedAcyclicGraph;
	}
	return self;
}

- (BOOL)isTopLevel:(NSNumber *)identifier {
	return [self.startingPoints containsObject:identifier];
}

@end
