//
//  RptqQuery+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqQuery+Extras.h"

#import <Foundation/NSException.h>
#import <Foundation/NSExpression.h>
#import <Foundation/NSPredicate.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <MADFoundation/MADStringUtilities.h>
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabaseField.h>
#import <MADAPI/MADDatabase.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqQuery.h"

#import "RptqQueryGroup.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqDatabase.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "MADSortOrder.h"

#import "RptqDataHelper.h"

#import "NSPredicate+Creators.h"

static inline unsigned long MADSectionCountWithGroupCount(unsigned long);
static inline unsigned long MADSectionCountWithGroupCount(unsigned long groupCount) {
	return 5 + groupCount * 2;
}

@implementation RptqQuery (Extras)

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	return [key isEqualToString:NSStringFromSelector(@selector(hasQueryGroups))];
}

+ (NSUInteger)sectionCountFectch:(int64_t)queryObjectID
			managedObjectContext:(RptqStoreContext *)managedObjectContext {

	NSArray *groups = [managedObjectContext objectsForEntity:NSStringFromClass([RptqQueryGroup class])];
	NSUInteger count = 0;
	for (RptqQueryGroup *group in groups) {
		if (group.inQuery.identifier == queryObjectID) count++;
	}
	return MADSectionCountWithGroupCount(count);
}

#pragma mark -
#pragma mark Overrides

- (NSUInteger)sectionCount { return MADSectionCountWithGroupCount(self.hasQueryGroups.count); }

#pragma mark -
#pragma mark Actions

- (RptqQueryGroup *)firstQueryGroup {
	NSArray *queryGroups = [self sortedQueryGroups];
	return (queryGroups.count >= 1) ? queryGroups[0] : nil;
}

- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index {
	NSArray *queryGroups = [self sortedQueryGroups];
	return (index < queryGroups.count) ? queryGroups[index] : nil;
}

- (NSArray <RptqQueryGroup *> *)sortedQueryGroups {
	NSString *weight = NSStringFromSelector(@selector(weight));
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:weight ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	NSArray *sortedArray = [self.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
	return sortedArray;
}

- (NSArray *)sortDescriptorsForDatabase:(MADDatabase *)database {

	NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
	
	MADSafeQueryField *nameTablePart, *nameFieldPart;
	NSString *keyForSort, *valueInQueryTableAlias;
	NSSortDescriptor *sort;
	BOOL sortDirectionIsAscending;
	for (RptqQueryGroup *queryGroup in [self sortedQueryGroups]) {
		@autoreleasepool {
			sortDirectionIsAscending = (queryGroup.sort == MADSortOrderAccending);
			RptqQueryField *groupField = queryGroup.hasField;
			NSString *groupFieldName = groupField.databaseSchemaField.name;

			// A query group is a GROUP BY: without a field backed by a table the
			// query selects there is no key to sort or group by.  The UI cannot
			// create one (the add-group screen keeps Done disabled until a field
			// is chosen), so this is malformed data, not a design state.  Refuse
			// it here, at the point of use, rather than emitting a "(null)" key
			// and quietly rendering the report as one group.
			valueInQueryTableAlias = [groupField.inQueryTable queryAlias];
			if (groupField == nil || groupFieldName == nil || valueInQueryTableAlias == nil) {
				os_log_error(GetMadLog(), "RptqQuery %lld: query group %lld has no grouping field backed by a selected query table; the document is invalid.", self.identifier, queryGroup.identifier);
				[NSException raise:NSInvalidArgumentException
							format:@"Query group %lld has no grouping field backed by a table the query selects. A query group must group by a field of a selected query table; the document is invalid.", queryGroup.identifier];
			}

			nameTablePart = [database newSafeIdentifier: valueInQueryTableAlias];
			nameFieldPart = [database newSafeIdentifier: groupFieldName];
			
			keyForSort = [MADStringUtilities stringByAppendingPeriod:nameTablePart];
			keyForSort = [keyForSort stringByAppendingString: nameFieldPart];
			
			SEL sel = MADDataTypeSelectorForSorting(groupField.databaseSchemaField.dataType);
			sort = [[NSSortDescriptor alloc] initWithKey: keyForSort
											   ascending: sortDirectionIsAscending
												selector: sel];
			[sortedSortDescriptorsGroup addObject:sort];
		}
	}
	return sortedSortDescriptorsGroup;
}

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"*********\n"];
	[description appendFormat:@"Identifier:         %lld\n", self.identifier];
	[description appendFormat:@"Cached text:        %@\n", self.cachedText];
	[description appendFormat:@"Override:           %@\n", self.override ? @"YES" : @"NO"];
	[description appendFormat:@"Override text:      %@\n", self.overrideText];
	[description appendFormat:@"Fields:             %@\n", self.hasFields];
	[description appendFormat:@"Database:           %@\n", self.inDatabase];
	[description appendFormat:@"Query tables (%lu): %@\n", (unsigned long)self.hasQueryTables.count, self.hasQueryTables];
	[description appendFormat:@"Query groups (%lu): %@\n", (unsigned long)self.hasQueryGroups.count, self.hasQueryGroups];
	
	NSArray *sortedQueryGroups = [self sortedQueryGroups];
	for (RptqQueryGroup *group in sortedQueryGroups) {
		[description appendFormat:@"\t\t- %@", group];
	}
	
	[description appendFormat:@"Query links:        %@\n", self.hasQueryLinks];
	[description appendFormat:@"Query predicate:    %@\n", self.hasQueryPredicate];
	[description appendFormat:@"Query sort:         %@\n", self.hasQuerySort];
	[description appendFormat:@"*********"];
	return description;
}

@end
