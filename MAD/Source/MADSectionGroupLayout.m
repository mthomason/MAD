//
//  MADSectionGroupLayout.m
//  MAD
//
//  Created by Michael on 5/28/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSectionGroupLayout.h"
#import <MAD/RptqStoreContext.h>
#import <CoreFoundation/CFNumber.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/MADStringUtilities.h>
#import <MADFoundation/madlog.h>

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

@implementation MADSectionGroupLayout {
	int64_t _dropIndex;
	NSString *_tableAlias;
	NSString *_fieldName;
	BOOL _groupingFieldResolved;
}

- (instancetype)initWithObject:(NSDictionary *)object
		  managedObjectContext:(RptqStoreContext *)managedObjectContext
				safeIdentifier:(NSString * (^)(NSString *))safeIdentifier {
	if (self = [super initWithObject: object managedObjectContext: managedObjectContext]) {
		
		if (self.type == MADDocumentSectionTypeGroupHeader || self.type == MADDocumentSectionTypeGroupFooter) {
			NSString *keyPathInGroupWeight = [RptqDocumentSection keyPathInGroupWeight],
					 *keyPathInGroupSort = [RptqDocumentSection keyPathInGroupSort],
					 *keyPathInGroupHasFieldDatabaseSchemaFieldDataType = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldDataType],
					 *keyPathInGroupHasFieldInQueryTableAlias = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableAlias],
					 *keyPathInGroupHasFieldDatabaseSchemaFieldName = [RptqDocumentSection keyPathInGroupHasFieldDatabaseSchemaFieldName],
					 *keyPathInGroupHasFieldInQueryTableDropIndex = [RptqDocumentSection keyPathInGroupHasFieldInQueryTableDropIndex];
		
			// A query group is a GROUP BY: it must name a field of a table the
			// query selects.  The four numbers are optional here because this
			// layout is also built by the designer for a malformed group, where
			// a missing value used to reach CFNumberGetValue as a NULL
			// CFNumberRef and take the process down.  Rendering and query
			// execution refuse the group instead; see -sortDescriptor and
			// RptqQuery -sortDescriptorsForDatabase:.
			NSNumber *number = object[keyPathInGroupSort];
			if (number != nil) CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_sort);

			number = object[keyPathInGroupWeight];
			if (number != nil) CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)number, kCFNumberSInt16Type, &_weight);

			NSNumber *dataTypeNumber = object[keyPathInGroupHasFieldDatabaseSchemaFieldDataType];
			if (dataTypeNumber != nil) CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)dataTypeNumber, kCFNumberSInt16Type, &_dataType);

			NSString *tableAlias = object[keyPathInGroupHasFieldInQueryTableAlias];
			_tableAlias = [tableAlias copy];

			NSString *fieldName = object[keyPathInGroupHasFieldDatabaseSchemaFieldName];
			_fieldName = [fieldName copy];

			NSNumber *dropIndexNumber = object[keyPathInGroupHasFieldInQueryTableDropIndex];
			if (dropIndexNumber != nil) CFNumberGetValue((__bridge CFNumberRef)(NSNumber *)dropIndexNumber, kCFNumberSInt64Type, &_dropIndex);

			// The key cannot be built without both halves.  Defining that here,
			// rather than letting each consumer guess, is what keeps the
			// designer able to show a broken group while the query and render
			// paths refuse it.
			_groupingFieldResolved = (tableAlias != nil && fieldName != nil &&
									  dataTypeNumber != nil && dropIndexNumber != nil);
			if (!_groupingFieldResolved) {
				os_log_error(GetMadLog(), "MADSectionGroupLayout: group section %lld has no grouping field backed by a selected query table; the document is invalid. The designer shows a placeholder; query and report execution will refuse it.", self.identifier);
			}

			self.safeIdentifier = safeIdentifier;
		}
	
	}
	return self;
}

- (BOOL)sortAscending {
	return _sort == MADSortOrderAccending;
}

- (NSString *)safeSortKey {
	if (!_groupingFieldResolved) {
		// Display path only.  The designer has to build and label this layout so
		// the user can see and repair the invalid group; the key itself is never
		// used there.  -sortDescriptor refuses to sort it.
		return NSLocalizedString(@"missing grouping field", @"Designer label for a query group with no resolvable grouping field");
	}
	NSString *queryTableAlias = [RptqQueryTable queryAliasForSchemaTableName:_tableAlias dropIndex:_dropIndex];
	NSString *safeTableAlias = self.safeIdentifier(queryTableAlias);
	NSString *safeFieldName = self.safeIdentifier(_fieldName);
	if (safeTableAlias == nil || safeFieldName == nil) {
		return NSLocalizedString(@"missing grouping field", @"Designer label for a query group with no resolvable grouping field");
	}
	NSString *sortKey = [MADStringUtilities stringByAppendingPeriod:safeTableAlias];
	return [sortKey stringByAppendingString:safeFieldName];
}

- (NSSortDescriptor *)sortDescriptor {
	if (!_groupingFieldResolved) {
		os_log_error(GetMadLog(), "MADSectionGroupLayout: refusing to sort group section %lld; its query group has no grouping field backed by a selected query table. The document is invalid.", self.identifier);
		[NSException raise:NSInvalidArgumentException
					format:@"Report section %lld belongs to a query group with no grouping field backed by a table the query selects. A query group must group by a field of a selected query table; the document is invalid.", self.identifier];
	}
	SEL sel = MADDataTypeSelectorForSorting(self.dataType);
	id result = [[NSSortDescriptor alloc] initWithKey: [self safeSortKey]
											ascending: [self sortAscending]
											 selector: sel];
	return result;
}

- (NSString *)localizedDisplay {
	NSString *result, *format;
	switch (self.type) {
						
		case MADDocumentSectionTypeGroupHeader:
			format = NSLocalizedString(@"Group Header (%@)", @"\"Group Header\"");
			result = [self safeSortKey];
			result = [[NSString alloc] initWithFormat: format, result];
			break;
			
		case MADDocumentSectionTypeGroupFooter:
			format = NSLocalizedString(@"Group Footer (%@)", @"\"Group Footer\"");
			result = [self safeSortKey];
			result = [[NSString alloc] initWithFormat: format, result];
			break;
			
		default:
			break;
			
	}
	return result;
}

@end
