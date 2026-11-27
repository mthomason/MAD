//
//  RptqQuery+Extras.h
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqQuery_Extras_h
#define Reports_RptqQuery_Extras_h

#import <MAD/RptqQuery.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADocumentSectionType.h>

@class RptqDocument, MADDatabase, RptqDocumentSection, RptqDatabaseSchemaTable, RptqQueryField;

@interface RptqQuery (Extras)

	- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index;
	- (NSArray <RptqQueryGroup *> *)sortedQueryGroups;
	- (NSArray *)sortDescriptorsForDatabase:(MADDatabase *)database;
	- (NSUInteger)sectionCount;
	+ (NSUInteger)sectionCountFectch:(int64_t)queryObjectID
				managedObjectContext:(RptqStoreContext *)managedObjectContext;

	/// The composing node's projected output fields, ordered by their output index.
	/// A field with no output key is a join or filter field, not a projection.  Nil
	/// with `error` when the query records fields but none names an output (an
	/// earlier store or an unset projection) -- never an invented order.
	- (nullable NSArray<RptqQueryField *> *)orderedOutputFieldsWithError:(NSError * _Nullable __autoreleasing *)error;

	/// Derives one output key per field, in field order, preserving any field's
	/// existing `outputKey` and naming the rest by their bare schema-field name when
	/// that name is unique, otherwise qualifying a collision with the field's source
	/// alias (`<alias>.<name>`, e.g. `payments.amount`).  `existingKeys` are output
	/// keys already taken elsewhere (other children already added), which a new key
	/// must not reuse.  Keys are deterministic and collision-free.
	+ (NSArray<NSString *> *)composeOutputKeysForFields:(NSArray<RptqQueryField *> *)fields
										  existingKeys:(NSSet<NSString *> *)existingKeys;

	/// YES when the query joins other nodes (it has a query table whose `upstreamQuery`
	/// is set) -- the root of a composition and any non-root composer.  A leaf is NO.
	- (BOOL)isComposing;

	/// YES when this query is the document's report root for **layout and result**
	/// purposes: the explicit composed root, or -- when the document has no composed
	/// root -- the document's single/default query (an ordinary report).  This is not
	/// the composition `isRoot` the serve protocol reports; an ordinary report keeps
	/// `isRoot == NO`.
	- (BOOL)isLayoutRootInDocument:(RptqDocument *)document;

	/// The query's report sections in render order: report header, page header, group
	/// headers, detail, group footers, page footer, report footer.  The root's structural
	/// sections are the document's five; any other node's are its `hasLayoutSections`.
	- (NSArray<RptqDocumentSection *> *)orderedLayoutSectionsForDocument:(RptqDocument *)document;

	/// One band for a render walk scoped to this query: a structural band from this query's
	/// `hasLayoutSections` (report/page header and footer, detail), or the group header or
	/// footer at `level` from this query's own groups.  Answers nil when this query has no
	/// such band.  The caller uses this only for a non-root node; the report root keeps the
	/// document's own five sections.
	- (nullable RptqDocumentSection *)layoutSectionForType:(MADDocumentSectionType)type
													level:(NSUInteger)level;

	/// Lazily creates the five structural sections (owned via `ownerQuery`) when the query
	/// has none -- the first scoped layout write to a migrated revision-3 leaf.  A query
	/// that already has any structural section is left unchanged.
	- (void)ensureStructuralSectionsInContext:(RptqStoreContext *)context;

@end

#endif
