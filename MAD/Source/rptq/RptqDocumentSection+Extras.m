//
//  RptqDocumentSection+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqStoreContext.h"
#import "RptqDocumentSection+Extras.h"
#import "madlog.h"

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSIndexPath.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSIndexPath.h>
#import <Foundation/NSCompoundPredicate.h>
#import <Foundation/NSComparisonPredicate.h>

#import <MADFoundation/MADStringUtilities.h>

#import <UIKit/UICollectionView.h>

#import "RptqDocument+Extras.h"
#import "RptqDocumentSectionEnumerator.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqQuery+Extras.h"

#import "RptqQueryTable+Extras.h"
#import "RptqQueryField+Extras.h"

#import "RptqQueryGroup+Extras.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"

#import "RptqDataHelper.h"

#import "RptqDocumentSectionWrappingStyle.h"

#import "NSPredicate+Creators.h"

static inline BOOL MADDocumentSectionIndexIsBody(NSUInteger, NSUInteger);
static inline BOOL MADDocumentSectionIndexIsBody(NSUInteger row, NSUInteger total) {
	return row == (2 + total);
}

static inline BOOL MADDocumentSectionIndexIsPageFooter(NSUInteger, NSUInteger);
static inline BOOL MADDocumentSectionIndexIsPageFooter(NSUInteger row, NSUInteger total) {
	return row == 3 + (2 * total);
}

static inline BOOL MADDocumentSectionIndexIsReportFooter(NSUInteger, NSUInteger);
static inline BOOL MADDocumentSectionIndexIsReportFooter(NSUInteger row, NSUInteger total) {
	return row == (2 * total) + 4;
}

static inline NSUInteger MADDocumentSectionIndexLevel(NSUInteger, NSUInteger);
static inline NSUInteger MADDocumentSectionIndexLevel(NSUInteger row, NSUInteger body) {
	return (row <= body) ? row : body - (row - body);
}

static inline MADDocumentSectionType MADSectionTypeForRow(NSUInteger, NSUInteger);
static inline MADDocumentSectionType MADSectionTypeForRow(NSUInteger row, NSUInteger total) {
	switch (row) {
		case 0:
			return MADDocumentSectionTypeReportHeader;
			break;
		case 1:
			return MADDocumentSectionTypePageHeader;
			break;
		default:
			return MADDocumentSectionIndexIsBody(row, total) ?
						MADDocumentSectionTypeBody :
						MADDocumentSectionIndexIsPageFooter(row, total) ?
							MADDocumentSectionTypePageFooter :
							MADDocumentSectionIndexIsReportFooter(row, total) ?
								MADDocumentSectionTypeReportFooter :
									(row - 1) <= total ? MADDocumentSectionTypeGroupHeader :
														 MADDocumentSectionTypeGroupFooter;
			break;
	}
}

@implementation RptqDocumentSection (Extras)

#pragma mark -
#pragma mark Static

+ (NSString *)keyPathidentifier {
	NSString *result = NSStringFromSelector(@selector(identifier));
	return result;
}

+ (NSString *)keyPathNumberOfRows {
	NSString *result = NSStringFromSelector(@selector(numberOfRows));
	return result;
}

+ (NSString *)keyPathType {
	NSString *result = NSStringFromSelector(@selector(type));
	return result;
}

+ (NSString *)keyPathWrappingStyle {
	NSString *result = NSStringFromSelector(@selector(wrappingStyle));
	return result;
}

+ (NSString *)keyPathVisibility {
	NSString *result = NSStringFromSelector(@selector(visibility));
	return result;
}

+ (NSString *)keyPathHeight {
	NSString *result = NSStringFromSelector(@selector(height));
	return result;
}

+ (NSString *)keyPathLayoutHeight {
	NSString *result = NSStringFromSelector(@selector(layoutHeight));
	return result;
}

+ (NSString *)keyPathInGroup {
	NSString *result = NSStringFromSelector(@selector(inGroup));
	return result;
}

+ (NSString *)keyPathInReport {
	NSString *result = NSStringFromSelector(@selector(inReport));
	return result;
}

+ (NSString *)keyPathInPageHeader {
	NSString *result = NSStringFromSelector(@selector(inReportPageHeader));
	return result;
}

+ (NSString *)keyPathInPageFooter {
	NSString *result = NSStringFromSelector(@selector(inReportPageFooter));
	return result;
}

+ (NSString *)keyPathInReportHeader {
	NSString *result = NSStringFromSelector(@selector(inReportReportHeader));
	return result;
}

+ (NSString *)keyPathInReportFooter {
	NSString *result = NSStringFromSelector(@selector(inReportReportFooter));
	return result;
}

+ (NSString *)keyPathSort {
	NSString *result = NSStringFromSelector(@selector(sort));
	return result;
}

+ (NSString *)keyPathWeight {
	NSString *result = NSStringFromSelector(@selector(weight));
	return result;
}

+ (NSString *)keyPathInGroupSort {
	NSString *result = [self keyPathInGroup];
	NSString *keyPathSort = [self keyPathSort];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathSort];
	return result;
}

+ (NSString *)keyPathInGroupWeight {
	NSString *result = [self keyPathInGroup];
	NSString *keyPathWeight = [self keyPathWeight];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathWeight];
	return result;
}

+ (NSString *)keyPathInGroupHasFieldDatabaseSchemaFieldName {
	NSString *keyPathHasField = [RptqQueryGroup keyPathHasField];
	NSString *keyPathSchemaFieldName = [RptqQueryField keySchemaFieldName];
	NSString *result = [self keyPathInGroup];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathHasField];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathSchemaFieldName];
	return result;
}

+ (NSString *)keyPathInGroupHasFieldInQueryTableAlias {
	NSString *keyPathHasField = [RptqQueryGroup keyPathHasField];
	NSString *keyPathInQueryTable = [RptqQueryField keyInQueryTable];
	NSString *keyPathAlias = [RptqQueryTable keyPathAlias];
	NSString *result = [self keyPathInGroup];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathHasField];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathInQueryTable];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathAlias];
	return result;
}

+ (NSString *)keyPathInGroupHasFieldInQueryTableDropIndex {
	NSString *keyPathHasField = [RptqQueryGroup keyPathHasField];
	NSString *keyPathInQueryTable = [RptqQueryField keyInQueryTable];
	NSString *keyPathDropIndex = [RptqQueryTable keyPathDropIndex];
	NSString *result = [self keyPathInGroup];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathHasField];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathInQueryTable];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathDropIndex];
	return result;
}

+ (NSString *)keyPathInGroupHasFieldDatabaseSchemaFieldDataType {
	NSString *keyPathHasField = [RptqQueryGroup keyPathHasField];
	NSString *keyPathSchemaFieldDataType = [RptqQueryField keySchemaFieldDataType];
	NSString *result = [self keyPathInGroup];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathHasField];
	result = [MADStringUtilities stringByAppendingPeriod:result];
	result = [result stringByAppendingString:keyPathSchemaFieldDataType];
	return result;
}







+ (instancetype)newDocumentSectionWithIdentifier:(int64_t)identifier
							   fromObjectContext:(RptqStoreContext *)context {
	return (RptqDocumentSection *)[context objectForEntity:NSStringFromClass([RptqDocumentSection class])
												identifier:identifier];
}

+ (instancetype)documentSectionForObjectID:(int64_t)objectID
					inManagedObjectContext:(RptqStoreContext *)managedObjectContext {
	return (RptqDocumentSection *)[managedObjectContext objectForEntity:NSStringFromClass([RptqDocumentSection class])
														   identifier:objectID];
}


+ (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
						  withNumberOfSections:(NSUInteger)numberOfSections {
	return [self getSectionTypeforRow: row
				   withNumberOfGroups: (numberOfSections > 5 ? (numberOfSections - 2 - 2 - 1) / 2 : 0)];
}

+ (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
							withNumberOfGroups:(NSUInteger)numberOfGroups {
	NSUInteger documentHeader    = 0;
	NSUInteger pageHeader        = 1;
	NSUInteger body              = 2 + numberOfGroups;       //6
	NSUInteger pageFooter        = 3 + (2 * numberOfGroups); //11
	NSUInteger documentFooter    = 4 + (2 * numberOfGroups); //12
	MADDocumentSectionType result;

	if (row == body) {
		result = MADDocumentSectionTypeBody;
		
	} else  if (row == pageHeader) {
		result = MADDocumentSectionTypePageHeader;
		
	} else if (row == pageFooter) {
		result = MADDocumentSectionTypePageFooter;
		
	} else if (row == documentHeader) {
		result = MADDocumentSectionTypeReportHeader;
		
	} else if (row == documentFooter) {
		result = MADDocumentSectionTypeReportFooter;
		
	} else {
	
		result = ((row - pageHeader) <= numberOfGroups) ?
				MADDocumentSectionTypeGroupHeader :
				MADDocumentSectionTypeGroupFooter;
	}
	
	return result;
}

+ (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query {
	RptqQueryGroup *group = [query queryGroupForIndex:groupLevel];
	return [RptqDocumentSection headerSectionInSections:group.hasSection];
}

+ (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query {
	RptqQueryGroup *group =  [query queryGroupForIndex:groupLevel];
	return [RptqDocumentSection footerSectionInSections:group.hasSection];
}

+ (RptqDocumentSection *)footerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
	for (RptqDocumentSection *section in sections) {
		if (section.type == MADDocumentSectionTypeGroupFooter) {
			return section;
			break;
		}
	}
	return nil;
}

+ (RptqDocumentSection *)headerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
	for (RptqDocumentSection *section in sections) {
		if (section.type == MADDocumentSectionTypeGroupHeader) {
			return section;
			break;
		}
	}
	return nil;
}

+ (RptqDocument *)rptqDocumentForSection:(RptqDocumentSection *)section {
	RptqDocument *result = nil;
	if (section.inGroup) {
		result = section.inGroup.inQuery.inDatabase.ownedByQueryAsStaticResource;
	} else if (section.inReport) {
		result = section.inReport;
	} else if (section.inReportPageFooter) {
		result = section.inReportPageFooter;
	} else if (section.inReportPageHeader) {
		result = section.inReportPageHeader;
	} else if (section.inReportReportFooter) {
		result = section.inReportReportFooter;
	} else if (section.inReportReportHeader) {
		result = section.inReportReportHeader;
	}
	return result;
}

+ (NSString *)getDocumentSectionNameForRow: (NSUInteger)row
						withNumberOfGroups: (NSUInteger)numberOfGroups {
	
	switch (MADSectionTypeForRow(row, numberOfGroups)) {
		case MADDocumentSectionTypeReportHeader:
			return NSLocalizedString(@"Report Header", @"Report Header");
			break;
		case MADDocumentSectionTypePageHeader:
			return NSLocalizedString(@"Page Header", @"Page Header");
			break;
		case MADDocumentSectionTypeGroupHeader: {
			return [NSString stringWithFormat:NSLocalizedString(@"Group Header %lu",
																@"Group Header #"),
					(unsigned long)(MADDocumentSectionIndexLevel(row, 2 + numberOfGroups) - 1)];
			break;
		}
		case MADDocumentSectionTypeBody:
			return NSLocalizedString(@"Report Detail", @"Report Detail");
			break;
		case MADDocumentSectionTypeGroupFooter: {
			return [NSString stringWithFormat:NSLocalizedString(@"Group Footer %lu",
																@"Group Footer #"),
					(unsigned long)MADDocumentSectionIndexLevel(row, 2 + numberOfGroups) - 1];
			break;
		}
		case MADDocumentSectionTypePageFooter:
			return NSLocalizedString(@"Page Footer", @"Page Footer");
			break;
		case MADDocumentSectionTypeReportFooter:
			return NSLocalizedString(@"Report Footer", @"Report Footer");
			break;
		default:
			NSAssert(NO, @"Expect a value here.");
			return @"";
			break;
	}
}

+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row
							  withNumberOfGroups:(NSInteger)numberOfGroups {
	NSInteger body = 2 + numberOfGroups;
	return (row <= body) ? row : body - (row - body);
}

+ (NSInteger)getRowForSection:(RptqDocumentSection *)section {
	
	RptqDocument *document = [section inRptqDocument];

	RptqDocumentSectionEnumerator *enumerator;
	enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];
	RptqDocumentSection *sec;
	NSInteger result = 0;
	for (sec in enumerator) {
		if (section.identifier == sec.identifier) break;
		result++;
	}
	return result;
}

#pragma mark -
#pragma mark Overrides





- (BOOL)producesFormFeed {
	return (self.wrappingStyle) == RptqDocumentSectionWrappingStyleNewPageAfter;
}

- (void)setProducesFormFeed:(BOOL)producesFormFeed {
	self.wrappingStyle = producesFormFeed ?
								RptqDocumentSectionWrappingStyleNewPageAfter :
								RptqDocumentSectionWrappingStyleStandard;
}

+ (NSNumber *)defaultHeight {
	return @44.0000f;
}

- (void)addHasRowsFixed:(RptqDocumentSectionRows *)value {
	if ([self.hasRows isKindOfClass:[NSMutableOrderedSet class]]) {
		[(NSMutableOrderedSet *)self.hasRows addObject:value];
	} else {
		NSOrderedSet<RptqDocumentSectionRows *> *hasRows = self.hasRows;
		NSMutableOrderedSet *tempSet = hasRows != nil ? [NSMutableOrderedSet orderedSetWithOrderedSet: hasRows] :
														[[NSMutableOrderedSet alloc] init];
		[tempSet addObject:value];
		self.hasRows = tempSet;
	}
}

- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value {
	if ([self.hasRows isKindOfClass:[NSMutableOrderedSet class]]) {
		[(NSMutableOrderedSet *)self.hasRows removeObject:value];
	} else {
		NSOrderedSet<RptqDocumentSectionRows *> *hasRows = self.hasRows;
		NSMutableOrderedSet *tempSet = hasRows != nil ? [NSMutableOrderedSet orderedSetWithOrderedSet: hasRows] :
														[[NSMutableOrderedSet alloc] init];
		[tempSet removeObject:value];
		self.hasRows = tempSet;
	}
}

- (int64_t)nextDropIndexForSection:(RptqStoreContext *)managedObjectContext {
	int64_t dropIndex = 0;
	NSArray *elements = [managedObjectContext objectsForEntity:NSStringFromClass([RptqDocumentElement class])];
	for (RptqDocumentElement *element in elements) {
		if (element.dropIndex + 1 > dropIndex) dropIndex = element.dropIndex + 1;
	}
	return dropIndex;
}

- (void)addDocumentObject: (RptqDocumentElement *)documentObject
			withDropPoint: (CGPoint)origin
	 managedObjectContext: (RptqStoreContext *)managedObjectContext {
	
	[documentObject setOriginPoint: origin];
	
	NSUInteger sectionZero = 0;
	RptqDocumentSectionRows *sectionRow = self.hasRows.firstObject;
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForItem:(NSInteger)sectionRow.hasObjects.count
												 inSection:(NSInteger)sectionZero];
	
	documentObject.dropIndex = [self nextDropIndexForSection:managedObjectContext];
	
	NSMutableOrderedSet *hasObjects = sectionRow.hasObjects.mutableCopy;
	[hasObjects insertObject: documentObject atIndex: (NSUInteger)indexPath.item];
	sectionRow.hasObjects = hasObjects;
}

- (void)setInterfaceHeight:(double)height {
	self.layoutHeight = height;
	self.height = height + 44.0000f;
}

// This is the layout height for page rendering... the designer section height is stored in the db
/*- (CGFloat)layoutHeightCalculated {
	CGFloat resultHeight = CGSizeZero.height;
	CGPoint dropPoint; CGSize marginSize; CGRect elementCanvasRect; CGFloat totalHeight;
	if (self.visibility) {
		for (RptqDocumentSectionRows *row in self.hasRows) {
			for (RptqDocumentElement *element in row.hasObjects) {
				[(NSValue *)element.dropPoint getValue:&dropPoint];
				marginSize           = [element sizeCalculated];
				elementCanvasRect    = CGRectMake(dropPoint.x, dropPoint.y,
												  marginSize.width, marginSize.height);
				
				totalHeight = elementCanvasRect.size.height + elementCanvasRect.origin.y;
				if (totalHeight > resultHeight) {
					resultHeight = totalHeight;
				}
			}
		}
	}
	return resultHeight;
}*/

- (RptqDocument *)inRptqDocument {
	return [RptqDocumentSection rptqDocumentForSection:self];
}

- (MADDocumentSectionType)getDocumentSectionType {
	return self.type;
}

- (NSString *)localizedDisplayName {
	NSString *result = nil;
	switch (self.type) {
	
		case MADDocumentSectionTypeReportHeader:
			result = NSLocalizedString(@"Report Header",
									   @"Report Header");
			break;

		case MADDocumentSectionTypePageHeader:
			result = NSLocalizedString(@"Page Header", @"Page Header");
			break;

		case MADDocumentSectionTypeBody:
			result = NSLocalizedString(@"Report Detail", @" Report Detail");
			break;

		case MADDocumentSectionTypePageFooter:
			result = NSLocalizedString(@"Page Footer", @"Page Footer");
			break;

		case MADDocumentSectionTypeReportFooter:
			result = NSLocalizedString(@"Report Footer", @"Report Footer");
			break;

		case MADDocumentSectionTypeGroupHeader:
			result = [NSString stringWithFormat:NSLocalizedString(@"Group Header (%@)",
																  @"\"Group Header 1\""),
					  [self.inGroup fieldNameQuery]];
			break;

		case MADDocumentSectionTypeGroupFooter:
			result = [NSString stringWithFormat:NSLocalizedString(@"Group Footer - (%@)",
																  @"\"Group Footer 1\""),
					  [self.inGroup fieldNameQuery]];
			break;

		default:
			break;

	}
	return result;
}

+ (instancetype)newDocumentSectionOfType:(MADDocumentSectionType)type
				 forManagedObjectContext:(RptqStoreContext *)managedObjectContext {

	RptqDocumentSection *section = [managedObjectContext insertObjectForEntity:NSStringFromClass([RptqDocumentSection class])
																  identifier:0];
	section.visibility = YES;
	section.type = type;
	
	return section;
}

#pragma mark - Handling Rows

- (id)debugQuickLookObject {
	NSMutableString *description = [[NSMutableString alloc] init];
	[description appendFormat:@"********** RptqDocumentSection **********\n"];
	[description appendFormat:@"Identifier:             %lld\n", self.identifier];
	[description appendFormat:@"Type:                   %hd\n", self.type];
	[description appendFormat:@"********** RptqDocumentSection **********"];
	return description;
}

@end
