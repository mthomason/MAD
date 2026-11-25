//
//  NSObject+RptqDocument_Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDocument_Extras_h
#define Reports_RptqDocument_Extras_h

#import <MAD/RptqDocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADReportSectionRepresentation.h>
#import <MAD/MTPaper.h>

@class MADDatabase, MADErrorContainer, RptqDocumentElement, RptqQuery,
	   RptqQueryPredicate, RptqQueryLinks, RptqQueryField, RptqQueryTable;

@interface RptqDocument (Extras)

	@property (readonly)RptqDatabase *defaultDatabase;

	@property (readonly)RptqQuery *mainQuery;

	+ (instancetype)newDocumentForManagedObjectContext:(RptqStoreContext *)objectContext;
	+ (instancetype)newDocumentReadFromManagedObjectContext:(RptqStoreContext *)objectContext;

	- (RptqDocumentSection *)documentSectionForType:(MADDocumentSectionType)type
										   andLevel:(NSUInteger)level;
	- (RptqDocumentSection *)documentSectionForSelectedIndex:(NSUInteger)selectedIndex
										  withNumberOfGroups:(NSUInteger)numberOfGroups;
										  
	- (void)storeDatabaseConnectionDefination:(MADDatabase *)database
					  forManagedObjectContext:(RptqStoreContext *)managedObjectContext;
	- (MADErrorContainer *)storeTablesAndFieldsForTables:(NSArray *)tables
										   fieldsByTable:(NSDictionary *)fieldsByTable
								 andManagedObjectContext:(RptqStoreContext *)managedObjectContext;
	
	- (void)setNewPageAfter:(BOOL)newPageAfter forSectionAtRow:(NSUInteger)sectionRow;
	- (void)setNumberOfRows:(int32_t)numberOfRows forSectionAtRow:(NSUInteger)sectionRow;
	- (void)setHeight:(double)height forSectionAtRow:(NSUInteger)sectionRow;
	- (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow;

	- (void)addQueryLink:(RptqQueryLinks *)queryLink;
	- (void)addPredicate:(RptqQueryPredicate *)predicate;
	- (RptqDocumentElement *)addDocumentObject:(NSDictionary *)defination
						  managedObjectContext:(RptqStoreContext *)managedObjectContext;
	- (BOOL)newPageAfterSectionAtRow:(NSUInteger)sectionRow;

	- (MTPaperType)paperType;

	/// Validates a composition graph: every upstream reference resolves, and the
	/// dependency graph has no cycle.  An error names the affected query.  A
	/// document with no root is not composed and trivially validates.
	- (BOOL)validateCompositionGraphWithError:(NSError * __autoreleasing *)error;

	/// The root's projected query fields, ordered by their output index.  Each
	/// field carries its root output key and its source query and schema field.
	/// Nil with `error` when a composed document records no output order (an
	/// earlier store or an unset projection) -- never an invented order.
	- (nullable NSArray<RptqQueryField *> *)orderedCompositionOutputsWithError:(NSError * __autoreleasing *)error;

	/// Converts an ordinary single-query report into a one-child composition: the
	/// report's query and connection become the child, a new root projects the
	/// child's fields with derived output keys, the child's groups and sort move to
	/// the root, and the layout's data-field, aggregate, and barcode field references
	/// rebind to the root's outputs so the existing bands and labels keep their
	/// values. Returns the new root, or nil with `error` (the report is left
	/// unchanged). The caller saves.
	- (nullable RptqQuery *)convertToCompositionWithChildName:(nullable NSString *)childName
														 error:(NSError * __autoreleasing *)error;

@end

#endif
