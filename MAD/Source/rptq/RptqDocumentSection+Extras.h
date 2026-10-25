//
//  RptqDocumentSection+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDocumentSection_Extras_h
#define Reports_RptqDocumentSection_Extras_h

#import <CoreGraphics/CGGeometry.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADocumentSectionType.h>

@class RptqQuery, RptqDocumentElement, NSIndexPath;

@interface RptqDocumentSection (Extras)

	+ (instancetype)newDocumentSectionWithIdentifier:(int64_t)identifier
								   fromObjectContext:(RptqStoreContext *)context;

	+ (instancetype)newDocumentSectionOfType:(MADDocumentSectionType)type
					 forManagedObjectContext:(RptqStoreContext *)managedObjectContext;

	+ (instancetype)documentSectionForObjectID:(int64_t)objid
						inManagedObjectContext:(RptqStoreContext *)moc;

	+ (NSString *)keyPathInReportHeader;
	+ (NSString *)keyPathInReportFooter;
	+ (NSString *)keyPathNumberOfRows;
	+ (NSString *)keyPathType;
	+ (NSString *)keyPathWrappingStyle;
	+ (NSString *)keyPathVisibility;
	+ (NSString *)keyPathHeight;
	+ (NSString *)keyPathLayoutHeight;
	+ (NSString *)keyPathInGroupHasFieldInQueryTableAlias;
	+ (NSString *)keyPathInGroupHasFieldDatabaseSchemaFieldName;
	+ (NSString *)keyPathInGroupWeight;
	+ (NSString *)keyPathInGroupSort;
	+ (NSString *)keyPathInPageHeader;
	+ (NSString *)keyPathInPageFooter;
	+ (NSString *)keyPathInReport;
	+ (NSString *)keyPathInGroup;
	+ (NSString *)keyPathInGroupHasFieldDatabaseSchemaFieldDataType;
	+ (NSString *)keyPathInGroupHasFieldInQueryTableDropIndex;

	+ (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
								withNumberOfGroups:(NSUInteger)numberOfGroups;

	+ (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
	+ (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
	+ (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
							  withNumberOfSections:(NSUInteger)numberOfSections;
	+ (RptqDocumentSection *)footerSectionInSections:(NSSet <RptqDocumentSection *> *)sections;
	+ (RptqDocumentSection *)headerSectionInSections:(NSSet <RptqDocumentSection *> *)sections;

	- (MADDocumentSectionType)getDocumentSectionType;

	- (NSString *)localizedDisplayName;

	- (BOOL)producesFormFeed;
	- (void)addHasRowsFixed:(RptqDocumentSectionRows *)value;
	- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value;
	- (void)addDocumentObject:(RptqDocumentElement *)documentObject withDropPoint:(CGPoint)origin
		 managedObjectContext:(RptqStoreContext *)managedObjectContext;

	- (void)setInterfaceHeight:(double)height;
	- (void)setProducesFormFeed:(BOOL)producesFormFeed;

@end

#endif
