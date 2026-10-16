//
//  RptqQueryGroup+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentSectionRows.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqDataHelper.h"
#import <MADFoundation/madlog.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSComparisonPredicate.h>

@implementation RptqQueryGroup (Extras)

+ (instancetype)newQueryGroupQueryWithSortOrder:(MADSortOrder)sortOrder
						andManagedObjectContext:(RptqStoreContext *)managedObjectContext {

	RptqQueryGroup *queryGroup = (RptqQueryGroup *)[managedObjectContext insertObjectForEntity:NSStringFromClass([RptqQueryGroup class])
																 identifier:0];

	queryGroup.sort = sortOrder;
	queryGroup.weight = [queryGroup lastWeightWithManagedObjectContext:managedObjectContext] + 1;

	return queryGroup;
}

+ (NSString *)keyPathHasField {
	NSString *result = NSStringFromSelector(@selector(hasField));
	return result;
}

#pragma mark -
#pragma mark Overrides

#pragma mark -
#pragma mark Static

+ (NSUInteger)numberOfGroupsForQueryID:(int64_t)objectID
				  managedObjectContext:(RptqStoreContext *)managedObjectContext {
	NSArray *groups = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQueryGroup class])];
	NSUInteger result = 0;
	for (RptqQueryGroup *group in groups) {
		if (group.inQuery.identifier == objectID) result++;
	}
	return result;

}

+ (NSUInteger)numberOfGroupsForQuery:(RptqQuery *)query {
	NSArray *groups = [query.storeContext objectsForEntity:NSStringFromClass([RptqQueryGroup class])];
	NSUInteger result = 0;
	for (RptqQueryGroup *group in groups) {
		if (group.inQuery.identifier == query.identifier) result++;
	}
	return result;
}

#pragma mark -
#pragma mark Member functions

- (int16_t)lastWeightWithManagedObjectContext:(RptqStoreContext *)managedObjectContext {
	NSArray *groups = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQueryGroup class])];
	int16_t weight = 0;
	for (RptqQueryGroup *group in groups) {
		if (group.weight > weight) weight = group.weight;
	}
	return weight;
}

- (NSString *)fieldNameNice {
	return [self.hasField toStringHumanReadable];
}

- (NSString *)fieldNameQuery {
	return [self.hasField toString];
}

- (NSString *)sortDisplayNice {
	switch (self.sort) {

		case MADSortOrderAccending:
			return @"accending";
			break;
		
		case MADSortOrderDecending:
			return @"decending";
			break;
		
		default:
			return @"";
			break;
	}
}

- (NSInteger)location {
	NSArray *sortedQueryGroups = self.inQuery.sortedQueryGroups;
	RptqQueryGroup *queryGroup;
	NSInteger location = 0;
	for (queryGroup in sortedQueryGroups) {
		if (queryGroup.identifier == self.identifier) {
			break;
		}
		location++;
	}
	return location;
}

#pragma mark -
#pragma mark MTProtocolCompare

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:         %lld\n", self.identifier];
	[description appendFormat:@"Sort:               %d\n", self.sort];
	[description appendFormat:@"Weight              %hd\n", self.weight];
	[description appendFormat:@"Field:              %@\n", self.hasField];
	[description appendFormat:@"Section:            %@\n", self.hasSection];
	[description appendFormat:@"Query:              %@\n", self.inQuery];
	[description appendFormat:@"*********"];
	return description;
}

@end
