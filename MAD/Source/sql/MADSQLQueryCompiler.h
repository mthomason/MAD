//
//  MADSQLQueryCompiler.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The pasted-SQL importer's write half (MAD_SQL_ENTRY.md §6.3, §6.4): an atomic
//  apply of a resolver's plan over the document's query -- the conflict check
//  against designer-element references first, then delete and create through the
//  same factories the query UI calls, one save, and `sqlSourceText` written only
//  when the apply succeeds.
//
//  The document-level mutations go through MADSQLQueryDocument, which MADocument
//  implements with the designer's layout managers and MADHeadlessDocument with
//  the definition rows alone; the compiler itself is pure Foundation.
//

#ifndef MAD_MADSQLQueryCompiler_h
#define MAD_MADSQLQueryCompiler_h

#import <Foundation/Foundation.h>

#import <MAD/MADSortOrder.h>
#import <MAD/MADSQLStatementResolver.h>

@class RptqQuery, RptqStoreContext;

NS_ASSUME_NONNULL_BEGIN

/// The document-level query mutations the compiler needs -- the same calls the
/// query UI makes (MAD_SQL_ENTRY.md §2.4), plus the two symmetrical clear
/// helpers the replace path completes the family with.
@protocol MADSQLQueryDocument <NSObject>

/// Creates the group row, its report header/footer sections (and, on MADocument,
/// their layout managers) for one GROUP BY column.
- (void)addQueryGroupWithQueryField:(int64_t)queryFieldObjectID
					   andSortOrder:(MADSortOrder)sortOrder;

/// Removes the group and detaches its sections (and layout managers).
- (void)removeGroupWitObjectID:(int64_t)groupID
	 fromManagedObjectContext:(RptqStoreContext *)managedObjectContext;

/// Deletes the designer's label-data elements that reference the table's fields.
- (void)deleteDatafieldsRelatedToTable:(int64_t)deleatedTableObjectId
							 inContent:(RptqStoreContext *)context;

/// Deletes the designer's aggregate elements that reference the table's fields.
- (void)deleteAggregateFieldRelatedToTable:(int64_t)deleatedTableObjectId
								 inContent:(RptqStoreContext *)context;

/// The replace path's symmetrical helpers: every link of the document's query
/// goes, whatever table it touches.
- (void)deleteAllQueryLinksInContent:(RptqStoreContext *)context;

/// The same, for the query's predicates.
- (void)deleteAllQueryPredicatesInContent:(RptqStoreContext *)context;

@end

@interface MADSQLQueryCompiler : NSObject

/// `query` is the document's main query; `document` supplies the group and
/// deletion helpers; `context` is the store the rows live in.
- (instancetype)initWithPlan:(MADSQLQueryPlan *)plan
					document:(id<MADSQLQueryDocument>)document
					   query:(RptqQuery *)query
					 context:(RptqStoreContext *)context NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) MADSQLQueryPlan *plan;
@property (nonatomic, strong, readonly) id<MADSQLQueryDocument> document;
@property (nonatomic, strong, readonly) RptqQuery *query;
@property (nonatomic, strong, readonly) RptqStoreContext *context;

/// The atomic apply.  NO, with a coded error, when the conflict check finds a
/// designer element (label-data, aggregate or barcode) or a group section that
/// references a field of a table the plan drops -- nothing is then deleted,
/// written or saved, and the previous `sqlSourceText` stands.  YES writes the
/// plan, sets `sqlSourceText` to the statement verbatim, and saves once.
- (BOOL)applyWithError:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
