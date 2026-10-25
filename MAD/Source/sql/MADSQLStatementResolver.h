//
//  MADSQLStatementResolver.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The parser's second half (docs/project/MAD_SQL_ENTRY.md §6.1, §6.2): binds the statement's
//  validated names to the document's RptqDatabaseSchemaTable / Field rows and
//  produces the write plan -- a value-object list of tables (with their copy
//  indexes), links, predicates and groups -- the compiler applies.  The plan is
//  validated whole before anything is written.
//

#ifndef MAD_MADSQLStatementResolver_h
#define MAD_MADSQLStatementResolver_h

#import <Foundation/Foundation.h>

#import <MAD/MADSortOrder.h>
#import <MAD/MADQueryLinkType.h>
#import <MAD/MADPredicateOperator.h>

@class RptqDatabase, RptqDatabaseSchemaTable, MADSQLStatement;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - The plan

/// One copy of a schema table in the plan, in the FROM set's order: the base
/// table first, then each join's right side.  -dropIndex is the copy index the
/// alias's digits name (0 for the table's own name).
@interface MADSQLPlanTable : NSObject

@property (nonatomic, strong) RptqDatabaseSchemaTable *schemaTable;
/// The alias as written (the table's name, or its drop-index form).
@property (nonatomic, copy) NSString *alias;
@property (nonatomic, assign) NSInteger dropIndex;

@end

/// One join: the link type and the schema fields the ON condition names.
@interface MADSQLPlanLink : NSObject

@property (nonatomic, assign) MADLinkType type;
@property (nonatomic, strong) MADSQLPlanTable *leftTable;
@property (nonatomic, copy) NSString *leftField;
@property (nonatomic, strong) MADSQLPlanTable *rightTable;
@property (nonatomic, copy) NSString *rightField;

@end

/// One predicate: an operator over a field or a literal on each side.
@interface MADSQLPlanPredicate : NSObject

@property (nonatomic, assign) MADPredicateOperator operator;
@property (nonatomic, strong, nullable) MADSQLPlanTable *leftTable;
@property (nonatomic, copy, nullable) NSString *leftField;
/// The literal's value string; nil when the side is a field.
@property (nonatomic, copy, nullable) NSString *leftLiteral;
@property (nonatomic, strong, nullable) MADSQLPlanTable *rightTable;
@property (nonatomic, copy, nullable) NSString *rightField;
@property (nonatomic, copy, nullable) NSString *rightLiteral;

@end

/// One GROUP BY column, with the sort the matching ORDER BY term asks for.
@interface MADSQLPlanGroup : NSObject

@property (nonatomic, strong) MADSQLPlanTable *table;
@property (nonatomic, copy) NSString *field;
@property (nonatomic, assign) MADSortOrder sortOrder;

@end

@interface MADSQLQueryPlan : NSObject

/// The entered statement, verbatim -- what a successful apply stores.
@property (nonatomic, copy) NSString *sourceText;
@property (nonatomic, copy) NSArray<MADSQLPlanTable *> *tables;
@property (nonatomic, copy) NSArray<MADSQLPlanLink *> *links;
@property (nonatomic, copy) NSArray<MADSQLPlanPredicate *> *predicates;
@property (nonatomic, copy) NSArray<MADSQLPlanGroup *> *groups;

@end

#pragma mark - The resolver

@interface MADSQLStatementResolver : NSObject

/// `database` is the document's schema (its tables and fields), which the
/// parser's validated names bind to, case-insensitively.
- (instancetype)initWithStatement:(MADSQLStatement *)statement
						 database:(RptqDatabase *)database NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, strong, readonly) MADSQLStatement *statement;
@property (nonatomic, strong, readonly) RptqDatabase *database;

/// The write plan; nil with a coded MADSQLCompileError when a name does not
/// resolve or the alias copy indexes are not the generator's own (0, 1, ... in
/// the FROM set's order).
- (nullable MADSQLQueryPlan *)resolveWithError:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
