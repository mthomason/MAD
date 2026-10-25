//
//  MADSQLStatement.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The parse tree the pasted-SQL front half produces (MAD_SQL_ENTRY.md §4): the
//  one SELECT the model can hold, as value objects.  Nothing here touches the
//  store -- the resolver (Phase C) binds the names to Rptq rows; the compiler
//  writes them.  Every value that can be the subject of a coded error carries
//  the 1-based position of its name token, so validation failures point at the
//  right place.
//

#ifndef MAD_MADSQLStatement_h
#define MAD_MADSQLStatement_h

#import <Foundation/Foundation.h>

#import <MAD/MADQueryLinkType.h>
#import <MAD/MADPredicateOperator.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Values

/// A column reference: `col`, `tbl.col` or `alias.col`, bare or qualified.
@interface MADSQLColumnReference : NSObject

/// The qualifier as written; nil when bare.
@property (nonatomic, copy, nullable) NSString *table;
/// The column name; `*` with -wildcard for `alias.*`.
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign, getter=isWildcard) BOOL wildcard;
/// The name token's position, for coded validation errors.
@property (nonatomic, assign) NSInteger line;
@property (nonatomic, assign) NSInteger column;

@end

/// A literal: the value as typed, numeric or quoted text.
@interface MADSQLLiteral : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign, getter=isNumeric) BOOL numeric;
/// The literal token's position.
@property (nonatomic, assign) NSInteger line;
@property (nonatomic, assign) NSInteger column;

@end

/// One AND of the WHERE clause: `left op right`, each side a column or literal.
@interface MADSQLPredicateTerm : NSObject

@property (nonatomic, assign) MADPredicateOperator operator;
@property (nonatomic, strong, nullable) MADSQLColumnReference *leftColumn;
@property (nonatomic, strong, nullable) MADSQLLiteral *leftLiteral;
@property (nonatomic, strong, nullable) MADSQLColumnReference *rightColumn;
@property (nonatomic, strong, nullable) MADSQLLiteral *rightLiteral;

@end

#pragma mark - FROM

/// One table of the FROM clause: `name [AS alias]`.
@interface MADSQLFromItem : NSObject

@property (nonatomic, copy) NSString *tableName;
/// The alias as written; nil when the table is referenced by its own name.
@property (nonatomic, copy, nullable) NSString *alias;
/// The table-name token's position.
@property (nonatomic, assign) NSInteger line;
@property (nonatomic, assign) NSInteger column;
/// The alias token's position.
@property (nonatomic, assign) NSInteger aliasLine;
@property (nonatomic, assign) NSInteger aliasColumn;

@end

/// One join: `type rightTable ON leftColumn = rightColumn`.
@interface MADSQLJoinClause : NSObject

@property (nonatomic, assign) MADLinkType type;
/// The left and right sides, as written (table names or aliases).
@property (nonatomic, copy) NSString *leftTable;
@property (nonatomic, copy) NSString *rightTable;
@property (nonatomic, strong) MADSQLColumnReference *leftColumn;
@property (nonatomic, strong) MADSQLColumnReference *rightColumn;
/// The right table-name token's position, for the duplicate-pair error.
@property (nonatomic, assign) NSInteger line;
@property (nonatomic, assign) NSInteger column;

@end

#pragma mark - ORDER BY

/// One ORDER BY term: a column and its direction.
@interface MADSQLOrderTerm : NSObject

@property (nonatomic, strong) MADSQLColumnReference *column;
@property (nonatomic, assign, getter=isAscending) BOOL ascending;

@end

#pragma mark - The statement

@interface MADSQLStatement : NSObject

/// The entered text, verbatim.
@property (nonatomic, copy) NSString *sourceText;
@property (nonatomic, copy) NSArray<MADSQLColumnReference *> *selectColumns;
/// The FROM set, the base table first.
@property (nonatomic, copy) NSArray<MADSQLFromItem *> *fromItems;
@property (nonatomic, copy) NSArray<MADSQLJoinClause *> *joins;
@property (nonatomic, copy) NSArray<MADSQLPredicateTerm *> *predicates;
@property (nonatomic, copy) NSArray<MADSQLColumnReference *> *groupByColumns;
@property (nonatomic, copy) NSArray<MADSQLOrderTerm *> *orderByTerms;

@end

NS_ASSUME_NONNULL_END

#endif
