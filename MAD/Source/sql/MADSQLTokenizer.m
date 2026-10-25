//
//  MADSQLTokenizer.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSQLTokenizer.h"

@interface MADSQLTokenizer ()
@property (nonatomic, copy) NSString *sql;
@property (nonatomic, copy) NSString *quoteCharacters;
@property (nonatomic, copy) NSArray<MADSQLToken *> *tokens;
@end

@implementation MADSQLTokenizer

- (instancetype)initWithSQL:(NSString *)sql
 identifierQuoteCharacters:(NSString *)quoteCharacters {
	self = [super init];
	if (!self) return nil;
	_sql = [sql copy];
	_quoteCharacters = [quoteCharacters copy];
	return self;
}

@end

#pragma mark - Token

@implementation MADSQLToken
@end

#pragma mark - Scanning

// The reserved words the subset's grammar names.  A token matching one (any
// case) is flagged, so the parser can reject OR/IN/LIKE/... by identity and
// read SELECT/FROM/... by uppercase comparison.
static NSSet<NSString *> *MADSQLKeywords(void) {
	static NSSet<NSString *> *keywords = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keywords = [NSSet setWithArray:@[
			@"SELECT", @"FROM", @"JOIN", @"INNER", @"LEFT", @"RIGHT", @"FULL", @"OUTER",
			@"ON", @"WHERE", @"AND", @"OR", @"GROUP", @"BY", @"ORDER", @"ASC", @"DESC",
			@"AS", @"LIMIT", @"DISTINCT", @"UNION", @"IN", @"LIKE", @"BETWEEN", @"NOT",
			@"HAVING", @"NATURAL", @"CROSS",
		]];
	});
	return keywords;
}

static inline BOOL MADSQLIsWhitespace(unichar c) {
	return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

static inline BOOL MADSQLIsDigit(unichar c) {
	return c >= '0' && c <= '9';
}

static inline BOOL MADSQLIsIdentifierStart(unichar c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_';
}

static inline BOOL MADSQLIsIdentifierPart(unichar c) {
	return MADSQLIsIdentifierStart(c) || MADSQLIsDigit(c);
}

// The two-char operators, matched longest-first; a lone < or > closes the set.
static NSArray<NSString *> *MADSQLSymbols(void) {
	static NSArray<NSString *> *symbols = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// The arithmetic operators are tokens so the parser can reject them as
		// expressions with the right code and position, rather than as unknown
		// characters.
		symbols = @[ @"<>", @">=", @"<=", @"=", @">", @"<", @"(", @")", @",", @".", @"*", @"+", @"-", @"/", @";" ];
	});
	return symbols;
}

static MADSQLToken *MADSQLTokenMake(MADSQLTokenKind kind, NSString *text, NSString *value,
									BOOL keyword, NSInteger line, NSInteger column) {
	MADSQLToken *token = [MADSQLToken new];
	token.kind = kind;
	token.text = text;
	token.value = value;
	token.keyword = keyword;
	token.line = line;
	token.column = column;
	return token;
}

@implementation MADSQLTokenizer (Scanning)

- (BOOL)tokenizeWithError:(NSError * __autoreleasing *)error {
	NSString *sql = self.sql;
	NSMutableArray<MADSQLToken *> *tokens = [NSMutableArray array];

	NSInteger line = 1;
	NSInteger column = 1;
	NSUInteger index = 0;
	const NSUInteger length = sql.length;

	unichar openQuote = [self.quoteCharacters characterAtIndex:0];
	unichar closeQuote = [self.quoteCharacters characterAtIndex:1];

	// A lexing failure leaves the position of the offending character for the
	// error; the inner loops close over these.
	__block NSInteger failureLine = 1;
	__block NSInteger failureColumn = 1;

	BOOL (^fail)(NSString *) = ^BOOL(NSString *message) {
		if (error) {
			*error = [MADSQLCompileError errorWithCode:MADSQLCompileErrorSyntax
												  line:failureLine
												column:failureColumn
											   message:message];
		}
		return NO;
	};

	while (index < length) {
		unichar c = [sql characterAtIndex:index];

		if (MADSQLIsWhitespace(c)) {
			if (c == '\n') {
				line++;
				column = 1;
			} else {
				column++;
			}
			index++;
			continue;
		}

		if (c == '-' && index + 1 < length && [sql characterAtIndex:index + 1] == '-') {
			index += 2;
			column += 2;
			while (index < length && [sql characterAtIndex:index] != '\n') {
				index++;
				column++;
			}
			continue;
		}

		if (c == '/' && index + 1 < length && [sql characterAtIndex:index + 1] == '*') {
			failureLine = line;
			failureColumn = column;
			index += 2;
			column += 2;
			BOOL closed = NO;
			while (index < length) {
				unichar inner = [sql characterAtIndex:index];
				if (inner == '*' && index + 1 < length && [sql characterAtIndex:index + 1] == '/') {
					index += 2;
					column += 2;
					closed = YES;
					break;
				}
				if (inner == '\n') {
					line++;
					column = 1;
				} else {
					column++;
				}
				index++;
			}
			if (!closed) return fail(@"The comment is never closed.");
			continue;
		}

		NSInteger tokenLine = line;
		NSInteger tokenColumn = column;
		failureLine = tokenLine;
		failureColumn = tokenColumn;

		if (c == '\'') {
			NSUInteger start = index + 1;
			index++;
			column++;
			BOOL closed = NO;
			NSMutableString *value = [NSMutableString string];
			while (index < length) {
				unichar inner = [sql characterAtIndex:index];
				if (inner == '\'') {
					if (index + 1 < length && [sql characterAtIndex:index + 1] == '\'') {
						[value appendString:[sql substringWithRange:NSMakeRange(start, index - start)]];
						[value appendString:@"'"];
						index += 2;
						column += 2;
						start = index;
						continue;
					}
					[value appendString:[sql substringWithRange:NSMakeRange(start, index - start)]];
					index++;
					column++;
					closed = YES;
					break;
				}
				if (inner == '\n') {
					line++;
					column = 1;
				} else {
					column++;
				}
				index++;
			}
			if (!closed) return fail(@"The string literal is never closed.");
			[tokens addObject:MADSQLTokenMake(MADSQLTokenKindStringLiteral, @"", value, NO, tokenLine, tokenColumn)];
			continue;
		}

		if (c == openQuote) {
			NSUInteger start = index + 1;
			index++;
			column++;
			BOOL closed = NO;
			while (index < length && [sql characterAtIndex:index] != closeQuote) {
				if ([sql characterAtIndex:index] == '\n') {
					line++;
					column = 1;
				} else {
					column++;
				}
				index++;
			}
			if (index < length) {
				NSString *name = [sql substringWithRange:NSMakeRange(start, index - start)];
				index++;
				column++;
				closed = YES;
				[tokens addObject:MADSQLTokenMake(MADSQLTokenKindQuotedIdentifier, name, nil, NO, tokenLine, tokenColumn)];
			}
			if (!closed) return fail(@"The quoted identifier is never closed.");
			continue;
		}

		if (MADSQLIsDigit(c)) {
			NSUInteger start = index;
			while (index < length && MADSQLIsDigit([sql characterAtIndex:index])) {
				index++;
				column++;
			}
			if (index < length && [sql characterAtIndex:index] == '.') {
				index++;
				column++;
				while (index < length && MADSQLIsDigit([sql characterAtIndex:index])) {
					index++;
					column++;
				}
			}
			NSString *digits = [sql substringWithRange:NSMakeRange(start, index - start)];
			[tokens addObject:MADSQLTokenMake(MADSQLTokenKindNumber, @"", digits, NO, tokenLine, tokenColumn)];
			continue;
		}

		if (MADSQLIsIdentifierStart(c)) {
			NSUInteger start = index;
			while (index < length && MADSQLIsIdentifierPart([sql characterAtIndex:index])) {
				index++;
				column++;
			}
			NSString *name = [sql substringWithRange:NSMakeRange(start, index - start)];
			BOOL keyword = [MADSQLKeywords() containsObject:name.uppercaseString];
			[tokens addObject:MADSQLTokenMake(MADSQLTokenKindIdentifier, name, nil, keyword, tokenLine, tokenColumn)];
			continue;
		}

		// The longest operator wins: the two-char symbols come first.
		BOOL symbolMatched = NO;
		for (NSString *symbol in MADSQLSymbols()) {
			if (length - index >= symbol.length &&
				([sql compare:symbol options:0 range:NSMakeRange(index, symbol.length)] == NSOrderedSame)) {
				[tokens addObject:MADSQLTokenMake(MADSQLTokenKindSymbol, symbol, nil, NO, tokenLine, tokenColumn)];
				index += symbol.length;
				column += (NSInteger)symbol.length;
				symbolMatched = YES;
				break;
			}
		}
		if (symbolMatched) continue;

		return fail([[NSString alloc] initWithFormat:@"The character '%C' is not part of the supported subset.", c]);
	}

	// The End token answers the parser's "what is next" without an index check.
	[tokens addObject:MADSQLTokenMake(MADSQLTokenKindEnd, @"", nil, NO, line, column)];
	self.tokens = tokens;
	return YES;
}

@end
