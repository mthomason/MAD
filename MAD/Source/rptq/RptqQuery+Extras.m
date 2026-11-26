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

- (BOOL)isComposing {
	for (RptqQueryTable *table in self.hasQueryTables) {
		if (table.upstreamQuery != nil) return YES;
	}
	return NO;
}

- (NSArray<RptqDocumentSection *> *)orderedLayoutSectionsForDocument:(RptqDocument *)document {
	NSMutableArray<RptqDocumentSection *> *sections = [NSMutableArray array];

	RptqDocumentSection *reportHeader = nil, *reportFooter = nil, *pageHeader = nil, *pageFooter = nil, *detail = nil;
	if (self.rootOfDocument != nil) {
		reportHeader = document.hasReportHeaderSection;
		reportFooter = document.hasReportFooterSection;
		pageHeader = document.hasPageHeaderSection;
		pageFooter = document.hasPageFooterSection;
		detail = document.hasDetailSection;
	} else {
		for (RptqDocumentSection *section in self.hasLayoutSections) {
			switch (section.type) {
				case MADDocumentSectionTypeReportHeader: reportHeader = section; break;
				case MADDocumentSectionTypeReportFooter: reportFooter = section; break;
				case MADDocumentSectionTypePageHeader: pageHeader = section; break;
				case MADDocumentSectionTypePageFooter: pageFooter = section; break;
				case MADDocumentSectionTypeBody: detail = section; break;
				default: break;
			}
		}
	}

	if (reportHeader) [sections addObject:reportHeader];
	if (pageHeader) [sections addObject:pageHeader];

	NSArray<RptqQueryGroup *> *groups = [self sortedQueryGroups] ?: @[];
	for (RptqQueryGroup *group in groups) {
		RptqDocumentSection *header = [RptqDocumentSection headerSectionInSections:group.hasSection];
		if (header) [sections addObject:header];
	}
	if (detail) [sections addObject:detail];
	for (RptqQueryGroup *group in [groups reverseObjectEnumerator]) {
		RptqDocumentSection *footer = [RptqDocumentSection footerSectionInSections:group.hasSection];
		if (footer) [sections addObject:footer];
	}
	if (pageFooter) [sections addObject:pageFooter];
	if (reportFooter) [sections addObject:reportFooter];

	return sections;
}

- (void)ensureStructuralSectionsInContext:(RptqStoreContext *)context {
	for (RptqDocumentSection *section in self.hasLayoutSections) {
		switch (section.type) {
			case MADDocumentSectionTypeReportHeader:
			case MADDocumentSectionTypeReportFooter:
			case MADDocumentSectionTypePageHeader:
			case MADDocumentSectionTypePageFooter:
			case MADDocumentSectionTypeBody:
				return;
			default:
				break;
		}
	}
	[RptqDocumentSection createStructuralSectionsForQuery:self managedObjectContext:context];
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

			// A composed root's output field addresses the composed result table by
			// its persisted output key -- the field references an upstream query
			// table, so it has no "<alias>.<field>" spelling of its own.
			if (groupField.outputKey.length > 0) {
				keyForSort = groupField.outputKey;
			} else {
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
			}

			SEL sel = MADDataTypeSelectorForSorting(groupField.databaseSchemaField.dataType);
			sort = [[NSSortDescriptor alloc] initWithKey: keyForSort
											   ascending: sortDirectionIsAscending
												selector: sel];
			[sortedSortDescriptorsGroup addObject:sort];
		}
	}
	return sortedSortDescriptorsGroup;
}

- (NSArray<RptqQueryField *> *)orderedOutputFieldsWithError:(NSError * __autoreleasing *)error {
	NSMutableArray<RptqQueryField *> *outputs = [NSMutableArray array];
	for (RptqQueryTable *table in self.hasQueryTables) {
		for (RptqQueryField *field in table.hasQueryFields) {
			[outputs addObject: field];
		}
	}
	[outputs sortUsingComparator:^NSComparisonResult(RptqQueryField *a, RptqQueryField *b) {
		return [@(a.outputIndex) compare: @(b.outputIndex)];
	}];

	// A field with no output key is a join or filter field, projected for the query
	// but not for the node; only the fields that name an output are the projection.
	NSMutableArray<RptqQueryField *> *projected = [NSMutableArray arrayWithCapacity: outputs.count];
	for (RptqQueryField *field in outputs) {
		if (field.outputKey != nil) {
			[projected addObject: field];
		}
	}
	if (projected.count == 0 && outputs.count > 0) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: @"MADCompositionValidationErrorDomain" code: 3 userInfo: @{
				NSLocalizedDescriptionKey: NSLocalizedString(
					@"This composed document records no output order for its projection.", @"Missing projection order error.") }];
		}
		return nil;
	}
	return projected;
}

static NSString *MADCompositionSourceAliasForField(RptqQueryField *field) {
	NSString *alias = field.inQueryTable.upstreamQuery.name;
	if (alias.length == 0) alias = field.inQueryTable.alias;
	if (alias.length == 0) alias = field.inQueryTable.databaseSchemaTable.name;
	return alias ?: @"";
}

+ (NSArray<NSString *> *)composeOutputKeysForFields:(NSArray<RptqQueryField *> *)fields
									  existingKeys:(NSSet<NSString *> *)existingKeys {
	NSMutableSet<NSString *> *taken = [NSMutableSet set];
	for (NSString *key in existingKeys) {
		if (key.length > 0) [taken addObject:key];
	}
	for (RptqQueryField *field in fields) {
		if (field.outputKey.length > 0) [taken addObject:field.outputKey];
	}

	// A bare name is "unique" when it appears once among the fields that still need
	// a key; a collision qualifies every field that shares it.
	NSMutableDictionary<NSString *, NSNumber *> *bareCount = [NSMutableDictionary dictionary];
	for (RptqQueryField *field in fields) {
		if (field.outputKey.length > 0) continue;
		NSString *bare = field.databaseSchemaField.name;
		if (bare.length == 0) continue;
		NSInteger count = bareCount[bare].integerValue;
		bareCount[bare] = @(count + 1);
	}

	NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithCapacity:fields.count];
	for (RptqQueryField *field in fields) {
		if (field.outputKey.length > 0) {
			[keys addObject:field.outputKey];
			continue;
		}
		NSString *bare = field.databaseSchemaField.name ?: @"";
		NSString *alias = MADCompositionSourceAliasForField(field);
		NSString *candidate = nil;
		if (bare.length > 0 && bareCount[bare].integerValue <= 1 && ![taken containsObject:bare]) {
			candidate = bare;
		} else if (bare.length > 0 && alias.length > 0) {
			candidate = [[NSString alloc] initWithFormat:@"%@.%@", alias, bare];
		} else {
			candidate = bare.length > 0 ? bare : NSLocalizedString(@"field", @"Fallback output name.");
		}
		// A collision that survives qualification (two children sharing an alias)
		// is made unique with a numeric suffix rather than silently duplicated.
		NSString *unique = candidate;
		NSUInteger suffix = 2;
		while ([taken containsObject:unique]) {
			unique = [[NSString alloc] initWithFormat:@"%@_%lu", candidate, (unsigned long)suffix++];
		}
		[taken addObject:unique];
		[keys addObject:unique];
	}
	return keys;
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
