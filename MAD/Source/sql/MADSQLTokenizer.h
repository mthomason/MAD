//
//  MADSQLTokenizer.h
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  The pasted-SQL lexer (MAD_SQL_ENTRY.md §4): splits the input into tokens with
//  1-based line:column positions, reading identifiers through the dialect's own
//  quote pair (backticks for MySQL, brackets for T-SQL, double quotes by
//  default), `'...'` string literals with doubled interior quotes, numbers,
//  comments and the subset's operators.  Keywords are flagged, not normalized.
//

#ifndef MAD_MADSQLTokenizer_h
#define MAD_MADSQLTokenizer_h

#import <Foundation/Foundation.h>

#import <MAD/MADSQLCompileError.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MADSQLTokenKind) {
	MADSQLTokenKindEnd = 0,
	MADSQLTokenKindIdentifier,
	MADSQLTokenKindQuotedIdentifier,
	MADSQLTokenKindStringLiteral,
	MADSQLTokenKindNumber,
	MADSQLTokenKindSymbol,
};

@interface MADSQLToken : NSObject

@property (nonatomic, assign) MADSQLTokenKind kind;
/// The source text.  Identifiers and keywords keep their case; a quoted
/// identifier carries the unquoted name here.
@property (nonatomic, copy) NSString *text;
/// String literals: the unescaped value.  Numbers: the digits as typed.
@property (nonatomic, copy, nullable) NSString *value;
@property (nonatomic, assign) NSInteger line;
@property (nonatomic, assign) NSInteger column;
/// YES when -text is a reserved word of the subset (any case).
@property (nonatomic, assign, getter=isKeyword) BOOL keyword;

@end

@interface MADSQLTokenizer : NSObject

/// `quoteCharacters` is the dialect's identifier quote pair -- the open and
/// close characters, e.g. `"``"` for MySQL, `"[]"` for T-SQL, `"\"\""` by
/// default (MADDatabase identifierQuoteCharacters).
- (instancetype)initWithSQL:(NSString *)sql
 identifierQuoteCharacters:(NSString *)quoteCharacters NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, copy, readonly) NSString *sql;
/// The dialect's identifier quote pair, open then close.
@property (nonatomic, copy, readonly) NSString *quoteCharacters;
/// Every token, the End token last; nil until -tokenizeWithError: succeeds.
@property (nonatomic, copy, readonly, nullable) NSArray<MADSQLToken *> *tokens;

/// The one pass.  A failure is a MADSQLCompileError with the offending position.
- (BOOL)tokenizeWithError:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

#endif
