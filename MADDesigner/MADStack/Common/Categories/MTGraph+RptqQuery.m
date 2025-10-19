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
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryLinks.h>

#import <MADDataStructures/MTVertex.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryLink.h>
#import <MAD/MADTableFieldIdentifier.h>

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

@implementation MTGraph (RptqQuery)

- (instancetype)initWtthQueryID:(MADModelQuery *)query {
	if (self = [self init]) {
		
		[query.queryTableIDs  enumerateObjectsUsingBlock:^(NSNumber * _Nonnull tableID,
														   NSUInteger idx, BOOL * _Nonnull stop) {
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

- (instancetype)initWithQueryID:(NSManagedObjectID *)queryID
		   managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
	
	if (self = [self init]) {

		NSError * __autoreleasing error = NULL;
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
		expSelf.expressionResultType = NSObjectIDAttributeType;

		NSExpressionDescription *expQuery = [[NSExpressionDescription alloc] init];
		expQuery.name = @"IQ";
		expQuery.expression = [NSExpression expressionForKeyPath:@"inQuery"];
		expQuery.expressionResultType = NSObjectIDAttributeType;

		fetchQueryTable.propertiesToFetch = @[expSelf, expQuery];
		fetchQueryTable.resultType = NSManagedObjectIDResultType;
		fetchQueryTable.predicate = predicateInQuery;
		
		fetchQueryTableResults = [managedObjectContext executeFetchRequest:fetchQueryTable error:&error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error);
		}

		NSExpressionDescription *expLeftFieldHasQueryTable = [[NSExpressionDescription alloc] init];
		expLeftFieldHasQueryTable.name = @"LT";
		expLeftFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasLeftField.inQueryTable"];
		expLeftFieldHasQueryTable.expressionResultType = NSObjectIDAttributeType;

		NSExpressionDescription *expRightFieldHasQueryTable = [[NSExpressionDescription alloc] init];
		expRightFieldHasQueryTable.name = @"RT";
		expRightFieldHasQueryTable.expression = [NSExpression expressionForKeyPath:@"hasRightField.inQueryTable"];
		expRightFieldHasQueryTable.expressionResultType = NSObjectIDAttributeType;

		NSArray *propertiesToFetch = [[NSArray alloc] initWithObjects: expSelf, expLeftFieldHasQueryTable, expRightFieldHasQueryTable, nil];
		fetchQueryLinks.propertiesToFetch = propertiesToFetch;
		fetchQueryLinks.resultType = NSDictionaryResultType;
		fetchQueryLinks.predicate = predicateInQuery;
		
		NSError *error2 = nil;
		fetchQueryLinksResults = [managedObjectContext executeFetchRequest:fetchQueryLinks error:&error2];
		if (error2 != nil) {
			os_log_error(GetDesignerLog(), "%s Error fetching: %@", __PRETTY_FUNCTION__, error2);
		}

		NSAssert(error == nil, @"Got error %@", error);
		
		for (NSManagedObjectID *objectID in fetchQueryTableResults) {
			@autoreleasepool {
				[self addVertexWithObject: objectID.copy];
			}
		}

		for (NSDictionary <NSString *, NSManagedObjectID *> *queryLinkObjectIDS in fetchQueryLinksResults) {
			@autoreleasepool {
				// T1 is the queryLink objectID
				//queryLink.inQuery
				// LT is the left query table objectID
				//queryLink.hasLeftField.inQueryTable.objectID
				// RT is the right query table objectID
				//queryLink.hasRightField.inQueryTable.objectID
				
				MTVertex *vertexOrigin = [[self vertexForObject:(MTObject *)queryLinkObjectIDS[@"LT"]] copy];
				MTVertex *vertexDestination = [[self vertexForObject:(MTObject *)queryLinkObjectIDS[@"RT"]] copy];
				
				[self addEdgeWithOrigin: vertexOrigin
							destination: vertexDestination
								 object: [queryLinkObjectIDS[@"T1"] copy]
							  andWeight: @(1)];
			}
		}
	}
	
	return self;
}

- (instancetype)initWithQuery:(RptqQuery *)query {
	NSManagedObjectContext *managedObjectContext = query.managedObjectContext;
	NSManagedObjectID *queryID = query.objectID;
	return [self initWithQueryID:queryID managedObjectContext:managedObjectContext];
}

@end
