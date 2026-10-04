//
//  MTGraph+RptqQuery.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MTGraph+RptqQuery.h"
#import "madlog.h"

#import <MAD/RptqQuery.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>

#import <MADDataStructures/MTVertex.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADTableFieldIdentifier.h>


#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSComparisonPredicate.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSOrderedSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSException.h>
#import <Foundation/NSMapTable.h>

@implementation MTGraph (RptqQuery)

- (instancetype)initWtthQueryID:(MADModelQuery *)query {
	if (self = [self init]) {
		
		[query.queryTableIDs  enumerateObjectsUsingBlock:^(NSNumber * _Nonnull tableID,
														   NSUInteger __unused idx, BOOL * _Nonnull __unused stop) {
			[self addVertexWithObject: tableID];
		}];
		
		NSNumber *weight = @(1);
		
		NSEnumerator <MADModelQueryLink *> *queryLinkEnumerator = query.links.objectEnumerator;

		NSNumber *identifier, *leftFieldID, *rightFieldID;
		MTVertex *vertexOrigin, *vertexDestination;
		for (MADModelQueryLink *link in queryLinkEnumerator) {
			leftFieldID =       @(link.leftFieldIdentifier.tableID);
			rightFieldID =      @(link.rightFieldIdentifier.tableID);
			vertexOrigin =        [self vertexForObject:leftFieldID];
			vertexDestination =   [self vertexForObject:rightFieldID];
			
			identifier = @(link.identifier);
			[self addEdgeWithOrigin: vertexOrigin
						destination: vertexDestination
							 object: identifier
						  andWeight: weight];
		}
	}
	return self;
}

- (instancetype)initWithQueryID:(int64_t)queryID
		   managedObjectContext:(RptqStoreContext *)managedObjectContext {

	if (self = [self init]) {

		NSArray *queryTables = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQueryTable class])];
		for (RptqQueryTable *table in queryTables) {
			if (table.inQuery.identifier != queryID) continue;
			[self addVertexWithObject: @(table.identifier)];
		}

		NSArray *queryLinks = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQueryLinks class])];
		for (RptqQueryLinks *link in queryLinks) {
			if (link.inQuery.identifier != queryID) continue;
			MTVertex *vertexOrigin = [[self vertexForObject:(MTObject *)@(link.hasLeftField.inQueryTable.identifier)] copy];
			MTVertex *vertexDestination = [[self vertexForObject:(MTObject *)@(link.hasRightField.inQueryTable.identifier)] copy];
			[self addEdgeWithOrigin: vertexOrigin
						destination: vertexDestination
							 object: @(link.identifier)
						  andWeight: @(1)];
		}
	}

	return self;
}

- (instancetype)initWithQuery:(RptqQuery *)query {
	return [self initWithQueryID:query.identifier managedObjectContext:query.storeContext];
}

@end
