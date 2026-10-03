//
//  MADQueryVisulizationDefination.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryVisualizationModel.h"
#import "MTGraph+RptqQuery.h"
#import "madlog.h"

#import <MAD/MADModel.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADTableFieldIdentifier.h>

#import <MADDataStructures/MTPair.h>
#import <MADDataStructures/MTLinkedList.h>
#import <MADDataStructures/MTVertex.h>
#import <MADDataStructures/MTGraph.h>

#import <Foundation/NSURL.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSMapTable.h>


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
		
		NSError *error = NULL;
		BOOL isDirectedAcyclicGraph, topLevel;
		MTLinkedList *tableIDs = [graph topologicalSortWithError: &error
										  isDirectedAcyclicGraph: &isDirectedAcyclicGraph];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "%s: %@", __PRETTY_FUNCTION__, error);
		}
		self.topologicallySortedTables = tableIDs;
		
		NSMutableArray <NSNumber *> *startingPoints = [[NSMutableArray alloc] init];
		for (MTPair *tableObjectIdContainer in tableIDs) {
			MTVertex *tableIdVertext = tableObjectIdContainer.former;
			if (tableIdVertext.object != nil) {
				NSNumber *tableID = tableIdVertext.object;
				topLevel = YES;
				NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = queryID.links.objectEnumerator;
				for (MADModelQueryLink *link in queryLinkEnumerator) {
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
