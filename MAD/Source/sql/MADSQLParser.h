//
//  MADSQLParser.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The pasted-SQL front end (docs/project/MAD_SQL_ENTRY.md §4, §5): a dialect-aware
//  recursive-descent parser that accepts exactly the language the model can
//  hold -- one SELECT, the four join spellings with single equi-ON conditions,
//  a flat AND where-clause, GROUP BY and an ORDER BY inside it -- and rejects
//  everything else with a coded MADSQLCompileError at the offending token's
//  line:column.
//
//  `schema` maps each schema table's name to its field names (any case; the
//  parser matches case-insensitively), which is what the alias rules of §5 and
//  the unknown/ambiguous-column checks need.  The resolver (Phase C) turns the
//  resulting statement's names into Rptq rows.
//

#ifndef MAD_MADSQLParser_h
#define MAD_MADSQLParser_h

#import <Foundation/Foundation.h>

@class MADSQLStatement;

NS_ASSUME_NONNULL_BEGIN

@interface MADSQLParser : NSObject

/// `quoteCharacters` is the dialect's identifier quote pair (see
/// MADDatabase identifierQuoteCharacters).
- (instancetype)initWithSQL:(NSString *)sql
 identifierQuoteCharacters:(NSString *)quoteCharacters
					 schema:(NSDictionary<NSString *, NSArray<NSString *> *> *)schema NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy, readonly) NSString *sql;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray<NSString *> *> *schema;

/// Parses the one SELECT; nil with a coded error on any rejection.
- (nullable MADSQLStatement *)parseStatement:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
