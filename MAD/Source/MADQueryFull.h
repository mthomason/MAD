//
//  MADQueryReport.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQueryFull_h
#define Reports_MTQueryFull_h

#import <MADAPI/MADQuery.h>
#import <MAD/RptqStoreContext.h>

@class RptqQuery, RptqQueryField, RptqQueryTable, MADDataResult, MADDatabase;

/// One child of a composing query, as the compiler resolves it: the child's attach
/// alias, its query (for leaf alias / output-key resolution), its dialect database,
/// and its published result (whose data table supplies the physical table and column
/// names).  `result` is set once the child has run in the topological walk.
@interface MADComposingChild : NSObject
@property (nonatomic) int64_t queryIdentifier;
@property (nonatomic, copy) NSString *attachAlias;
@property (nonatomic, strong, nullable) RptqQuery *query;
/// The child's dialect database.  Set only for a leaf child: a composing child has no
/// remote dialect, and its columns resolve through its output keys, not through
/// `database`.  `logicalKeyForField:inChild:` dereferences it only on the leaf branch.
@property (nonatomic, strong, nullable) MADDatabase *database;
@property (nonatomic, strong, nullable) MADDataResult *result;
@end

/// Resolves a composing query's table and field references to its attached children,
/// so the general compiler (`MADQueryFull`) emits a query over N children through the
/// one SQL path.  A leaf child's columns are named `<alias>.<field>`; a composing
/// child's columns are named by its output keys.
@interface MADComposingResolver : NSObject
- (instancetype)initWithChildren:(NSArray<MADComposingChild *> *)children;
- (nullable MADComposingChild *)childForQueryIdentifier:(int64_t)identifier;
/// The FROM reference for a composing query table: `<attachAlias>.<child-table>`.
- (nullable NSString *)tableReferenceForQueryTable:(RptqQueryTable *)table;
/// The column reference for a composing field: `<attachAlias>.<child-table>.<physical-column>`.
/// nil with `error` when the field's upstream query, output column, or child result
/// is missing, so a caller reports an actionable error rather than a silent drop.
- (nullable NSString *)columnReferenceForField:(RptqQueryField *)field error:(NSError * _Nullable __autoreleasing *)error;
@end

@interface MADQueryFull : MADQuery <MADQueryFieldKeysProtocol, MADQueryDataDelegateProtocol>

- (instancetype)initWithQuery:(RptqQuery *)query andQueryLimit:(NSUInteger)queryLimit;

/// The source database that supplies the dialect for the selected query.  The
/// document sets it to the database built for that query's `inDatabase`; when it
/// is nil the generator falls back to the data delegate's database, which is the
/// single-source behaviour this class had before query selection was explicit.
@property (nonatomic, strong) MADDatabase *database;

- (NSString *)copySQLWithManagedObjectContext:(RptqStoreContext *)managedObjectContext
										error:(NSError * __autoreleasing *)error;

- (NSString *)SQLOnlyActiveFields:(BOOL)onlyActiveFields
			 managedObjectContext:(RptqStoreContext *)managedObjectContext
							error:(NSError * __autoreleasing *)error;

@property (nonatomic, assign) NSUInteger limitResults;

/// Fields a downstream consumer requires, projected even when no report element,
/// link or group references them.  The composition coordinator sets this on an
/// upstream query before it compiles, so the join key enters the result without a
/// dummy report label.  nil is the ordinary-report behaviour.
@property (nonatomic, strong, nullable) NSArray <RptqQueryField *> *requiredQueryFields;

/// When set, this query is a composing node: its tables carry `upstreamQuery`
/// references and are resolved through the resolver to the attached children.  The
/// SELECT list becomes the node's ordered output fields; FROM/JOIN and WHERE resolve
/// through the resolver.  nil is the ordinary single-source (or leaf) behaviour.
@property (nonatomic, strong, nullable) MADComposingResolver *composingResolver;

@end

#endif
