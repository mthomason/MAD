//
//  MADSQLParser.m
//  MAD
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADSQLParser.h"
#import "MADSQLCompileError.h"
#import "MADSQLStatement.h"
#import "MADSQLTokenizer.h"

@interface MADSQLParser ()

@property (nonatomic, copy) NSString *sql;
@property (nonatomic, copy) NSString *quoteCharacters;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *schema;

// The schema in lowercase: table name -> field names, so every name match is
// case-insensitive without repeated uppercasing on the hot path.
@property (nonatomic, copy) NSDictionary<NSString *, NSSet<NSString *> *> *fieldsByTable;
// The schema's canonical spelling per lowercase table name.
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *canonicalTables;

// Parse state.
@property (nonatomic, copy) NSArray<MADSQLToken *> *tokens;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) NSMutableArray<MADSQLFromItem *> *fromItems;
@property (nonatomic, strong) NSMutableArray<MADSQLJoinClause *> *joins;
// Every name a FROM side can be referenced by -- the alias when one was
// written, else the table name -- to the canonical table, lowercase.
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *tableByAlias;
// The canonical tables of the FROM set, in order, for bare-column resolution.
@property (nonatomic, strong) NSMutableArray<NSString *> *fromTables;

@end

@implementation MADSQLParser

- (instancetype)initWithSQL:(NSString *)sql
 identifierQuoteCharacters:(NSString *)quoteCharacters
					 schema:(NSDictionary<NSString *, NSArray<NSString *> *> *)schema {
	self = [super init];
	if (!self) return nil;

	_sql = [sql copy];
	_quoteCharacters = [quoteCharacters copy];
	_schema = [schema copy];

	NSMutableDictionary<NSString *, NSSet<NSString *> *> *fieldsByTable = [NSMutableDictionary dictionaryWithCapacity:schema.count];
	NSMutableDictionary<NSString *, NSString *> *canonicalTables = [NSMutableDictionary dictionaryWithCapacity:schema.count];
	for (NSString *table in schema) {
		NSMutableSet<NSString *> *fields = [NSMutableSet setWithCapacity:[schema[table] count]];
		for (NSString *field in schema[table]) {
			[fields addObject:field.lowercaseString];
		}
		fieldsByTable[table.lowercaseString] = fields;
		canonicalTables[table.lowercaseString] = table;
	}
	_fieldsByTable = fieldsByTable;
	_canonicalTables = canonicalTables;

	return self;
}

#pragma mark - The statement

- (MADSQLStatement *)parseStatement:(NSError * __autoreleasing *)error {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:self.sql
										   identifierQuoteCharacters:self.quoteCharacters];
	if (![tokenizer tokenizeWithError:error]) return nil;

	self.tokens = tokenizer.tokens;
	self.index = 0;
	self.fromItems = [NSMutableArray array];
	self.joins = [NSMutableArray array];
	self.tableByAlias = [NSMutableDictionary dictionary];
	self.fromTables = [NSMutableArray array];

	NSMutableArray<MADSQLColumnReference *> *selectColumns = [NSMutableArray array];
	NSMutableArray<MADSQLPredicateTerm *> *predicates = [NSMutableArray array];
	NSMutableArray<MADSQLColumnReference *> *groupByColumns = [NSMutableArray array];
	NSMutableArray<MADSQLOrderTerm *> *orderByTerms = [NSMutableArray array];

	// SELECT [the select list]
	if (![self matchKeyword:@"SELECT"]) {
		return [self fail:MADSQLCompileErrorSyntax at:self.current message:@"The statement does not start with SELECT." error:error];
	}
	if ([self keywordIs:@"DISTINCT"]) {
		return [self fail:MADSQLCompileErrorUnsupportedDISTINCT at:self.current
				   message:@"DISTINCT has no place in the model: the query designer's fields are the select list." error:error];
	}

	// The select list: column references and alias.* -- validated after FROM,
	// because a qualifier names something FROM defines.
	for (;;) {
		MADSQLColumnReference *column = [self parseSelectColumnReturningError:error];
		if (column == nil) return nil;
		[selectColumns addObject:column];
		if ([self matchSymbol:@","]) continue;
		if ([self symbolIs:@"+"] || [self symbolIs:@"-"] || [self symbolIs:@"/"]) {
			return [self fail:MADSQLCompileErrorUnsupportedExpression at:self.current
					   message:@"Arithmetic has no place in the select list: the model holds column references." error:error];
		}
		break;
	}

	// FROM
	if (![self matchKeyword:@"FROM"]) {
		return [self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected FROM after the select list." error:error];
	}
	if (![self parseFromClauseReturningError:error]) return nil;

	// The optional clauses, each once, in the written order.
	BOOL sawWhere = NO, sawGroup = NO, sawOrder = NO;
	for (;;) {
		if ([self keywordIs:@"WHERE"] && !sawWhere) {
			[self advance];
			sawWhere = YES;
			if (![self parsePredicateList:predicates error:error]) return nil;
			continue;
		}
		if ([self keywordIs:@"GROUP"] && !sawGroup) {
			[self advance];
			if (![self matchKeyword:@"BY"]) {
				return [self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected BY after GROUP." error:error];
			}
			sawGroup = YES;
			groupByColumns = [self parseColumnListReturningError:error];
			if (groupByColumns == nil) return nil;
			continue;
		}
		if ([self keywordIs:@"ORDER"] && !sawOrder) {
			[self advance];
			if (![self matchKeyword:@"BY"]) {
				return [self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected BY after ORDER." error:error];
			}
			sawOrder = YES;
			orderByTerms = [self parseOrderListReturningError:error];
			if (orderByTerms == nil) return nil;
			continue;
		}
		break;
	}

	if ([self keywordIs:@"UNION"]) {
		return [self fail:MADSQLCompileErrorUnsupportedUNION at:self.current
				   message:@"UNION has no place in the model: one document query holds one SELECT." error:error];
	}
	if ([self keywordIs:@"LIMIT"]) {
		return [self fail:MADSQLCompileErrorUnsupportedLIMIT at:self.current
				   message:@"LIMIT is the app's own: the designer and reporting modes apply it, never the query." error:error];
	}

	[self matchSymbol:@";"];
	if (self.current.kind != MADSQLTokenKindEnd) {
		return [self fail:MADSQLCompileErrorSyntax at:self.current
				   message:@"The statement does not end where the subset ends -- one SELECT, nothing after it." error:error];
	}

	// The name checks the FROM set makes possible: columns, and ORDER BY inside
	// GROUP BY.
	if (![self validateColumns:selectColumns error:error]) return nil;
	for (MADSQLJoinClause *join in self.joins) {
		if (![self validateReference:join.leftColumn error:error]) return nil;
		if (![self validateReference:join.rightColumn error:error]) return nil;
	}
	for (MADSQLPredicateTerm *predicate in predicates) {
		if (predicate.leftColumn != nil && ![self validateReference:predicate.leftColumn error:error]) return nil;
		if (predicate.rightColumn != nil && ![self validateReference:predicate.rightColumn error:error]) return nil;
	}
	if (![self validateColumns:groupByColumns error:error]) return nil;
	for (MADSQLOrderTerm *term in orderByTerms) {
		if (![self validateReference:term.column error:error]) return nil;
	}
	if (![self validateOrderBy:orderByTerms within:groupByColumns error:error]) return nil;

	MADSQLStatement *statement = [MADSQLStatement new];
	statement.sourceText = self.sql;
	statement.selectColumns = selectColumns;
	statement.fromItems = self.fromItems;
	statement.joins = self.joins;
	statement.predicates = predicates;
	statement.groupByColumns = groupByColumns;
	statement.orderByTerms = orderByTerms;
	return statement;
}

#pragma mark - Tokens

- (MADSQLToken *)current {
	return self.tokens[self.index];
}

- (void)advance {
	if (self.index + 1 < self.tokens.count) self.index++;
}

- (BOOL)matchKeyword:(NSString *)keyword {
	MADSQLToken *token = self.current;
	if (!token.isKeyword || ![token.text.uppercaseString isEqualToString:keyword]) return NO;
	[self advance];
	return YES;
}

- (BOOL)keywordIs:(NSString *)keyword {
	MADSQLToken *token = self.current;
	return token.isKeyword && [token.text.uppercaseString isEqualToString:keyword];
}

- (BOOL)matchSymbol:(NSString *)symbol {
	MADSQLToken *token = self.current;
	if (token.kind != MADSQLTokenKindSymbol || ![token.text isEqualToString:symbol]) return NO;
	[self advance];
	return YES;
}

- (BOOL)symbolIs:(NSString *)symbol {
	MADSQLToken *token = self.current;
	return token.kind == MADSQLTokenKindSymbol && [token.text isEqualToString:symbol];
}

- (id)fail:(MADSQLCompileErrorCode)code at:(MADSQLToken *)token message:(NSString *)message error:(NSError * __autoreleasing *)error {
	if (error) {
		*error = [MADSQLCompileError errorWithCode:code line:token.line column:token.column message:message];
	}
	return nil;
}

// The select list item, with its expression- and alias-shaped rejections.
- (MADSQLColumnReference *)parseSelectColumnReturningError:(NSError * __autoreleasing *)error {
	MADSQLToken *token = self.current;
	if (token.kind == MADSQLTokenKindSymbol && [token.text isEqualToString:@"*"]) {
		[self fail:MADSQLCompileErrorUnsupportedExpression at:token
			 message:@"`*` names every column; name them, or use `alias.*`." error:error];
		return nil;
	}
	if (token.kind != MADSQLTokenKindIdentifier && token.kind != MADSQLTokenKindQuotedIdentifier) {
		[self fail:MADSQLCompileErrorSyntax at:token message:@"Expected a column reference in the select list." error:error];
		return nil;
	}
	[self advance];

	MADSQLColumnReference *column = [MADSQLColumnReference new];
	column.line = token.line;
	column.column = token.column;

	if ([self matchSymbol:@"."]) {
		column.table = token.text;
		MADSQLToken *name = self.current;
		if (name.kind == MADSQLTokenKindIdentifier || name.kind == MADSQLTokenKindQuotedIdentifier) {
			column.name = name.text;
			column.line = name.line;
			column.column = name.column;
			[self advance];
		} else if ([self matchSymbol:@"*"]) {
			column.name = @"*";
			column.wildcard = YES;
			column.line = name.line;
			column.column = name.column;
		} else {
			[self fail:MADSQLCompileErrorSyntax at:name message:@"Expected a column name after the qualifier." error:error];
			return nil;
		}
	} else {
		column.name = token.text;
	}

	// A function call, an alias, or anything else the model cannot hold.
	if ([self symbolIs:@"("]) {
		[self fail:MADSQLCompileErrorUnsupportedExpression at:token
			 message:@"Functions and expressions have no place in the select list: the model holds column references." error:error];
		return nil;
	}
	if ([self keywordIs:@"AS"]) {
		[self fail:MADSQLCompileErrorUnsupportedSelectAlias at:self.current
			 message:@"Column aliases are the designer's own; name the column." error:error];
		return nil;
	}

	return column;
}

#pragma mark - FROM

- (BOOL)parseFromClauseReturningError:(NSError * __autoreleasing *)error {
	// FROM (SELECT ...) is a subquery, whatever follows the paren.
	if ([self symbolIs:@"("]) {
		MADSQLToken *paren = self.current;
		[self advance];
		if ([self keywordIs:@"SELECT"]) {
			[self fail:MADSQLCompileErrorUnsupportedSubquery at:self.current
				 message:@"Subqueries have no place in the model: FROM names schema tables." error:error];
		} else {
			[self fail:MADSQLCompileErrorSyntax at:paren message:@"Expected a table name after FROM." error:error];
		}
		return NO;
	}

	if (![self parseFromItemReturningError:error]) return NO;

	for (;;) {
		MADSQLToken *token = self.current;

		if ([self symbolIs:@","]) {
			[self fail:MADSQLCompileErrorUnsupportedCommaJoin at:token
				 message:@"Comma joins have no place in the model: every join carries its link." error:error];
			return NO;
		}

		if ([self keywordIs:@"NATURAL"]) {
			[self fail:MADSQLCompileErrorUnsupportedNaturalCrossJoin at:token
				 message:@"NATURAL joins have no place in the model: a link names one field pair." error:error];
			return NO;
		}
		if ([self keywordIs:@"CROSS"]) {
			[self fail:MADSQLCompileErrorUnsupportedNaturalCrossJoin at:token
				 message:@"CROSS joins have no place in the model: a link names one field pair." error:error];
			return NO;
		}

		MADLinkType type = MADLinkTypeUnknown;
		if ([self keywordIs:@"INNER"]) {
			[self advance];
			if (![self matchKeyword:@"JOIN"]) {
				[self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected JOIN after INNER." error:error];
				return NO;
			}
			type = MADLinkTypeInnerJoin;
		} else if ([self keywordIs:@"LEFT"]) {
			[self advance];
			[self matchKeyword:@"OUTER"];
			if (![self matchKeyword:@"JOIN"]) {
				[self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected JOIN after LEFT." error:error];
				return NO;
			}
			type = MADLinkTypeLeftOuterJoin;
		} else if ([self keywordIs:@"RIGHT"]) {
			[self advance];
			[self matchKeyword:@"OUTER"];
			if (![self matchKeyword:@"JOIN"]) {
				[self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected JOIN after RIGHT." error:error];
				return NO;
			}
			type = MADLinkTypeRightOuterJoin;
		} else if ([self keywordIs:@"FULL"]) {
			[self advance];
			[self matchKeyword:@"OUTER"];
			if (![self matchKeyword:@"JOIN"]) {
				[self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected JOIN after FULL." error:error];
				return NO;
			}
			type = MADLinkTypeFullOuterJoin;
		} else if ([self keywordIs:@"JOIN"]) {
			[self advance];
			type = MADLinkTypeEquiJoin;
		} else {
			break;
		}

		if (![self parseJoinAfterType:type error:error]) return NO;
	}

	return YES;
}

- (BOOL)parseFromItemReturningError:(NSError * __autoreleasing *)error {
	MADSQLToken *token = self.current;
	if (token.kind != MADSQLTokenKindIdentifier && token.kind != MADSQLTokenKindQuotedIdentifier) {
		[self fail:MADSQLCompileErrorSyntax at:token message:@"Expected a table name." error:error];
		return NO;
	}
	[self advance];

	NSString *canonical = [self canonicalTableForName:token.text];
	if (canonical == nil) {
		[self fail:MADSQLCompileErrorUnknownTable at:token
			 message:[[NSString alloc] initWithFormat:@"Unknown table '%@'.", token.text] error:error];
		return NO;
	}

	MADSQLFromItem *item = [MADSQLFromItem new];
	item.tableName = token.text;
	item.line = token.line;
	item.column = token.column;

	// `[AS] alias`: the table's own name, or its drop-index form.  An implicit
	// alias is a bare identifier -- never a keyword, or the clause keywords
	// (WHERE, GROUP, ORDER, INNER, ...) would read as aliases.
	BOOL wroteAS = [self matchKeyword:@"AS"];
	MADSQLToken *aliasToken = self.current;
	BOOL isImplicitAlias = aliasToken.kind == MADSQLTokenKindQuotedIdentifier ||
		(aliasToken.kind == MADSQLTokenKindIdentifier && !aliasToken.isKeyword);
	if (isImplicitAlias) {
		[self advance];
		NSString *alias = aliasToken.text;
		NSString *lowerName = canonical.lowercaseString;
		NSString *lowerAlias = alias.lowercaseString;
		BOOL isOwnName = [lowerAlias isEqualToString:lowerName];
		BOOL isDropIndex = lowerAlias.length > lowerName.length &&
			[lowerAlias hasPrefix:lowerName] &&
			[lowerAlias rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]
										options:0
										  range:NSMakeRange(lowerName.length, lowerAlias.length - lowerName.length)].location == NSNotFound;
		if (!isOwnName && !isDropIndex) {
			[self fail:MADSQLCompileErrorUnsupportedAlias at:aliasToken
				 message:[[NSString alloc] initWithFormat:@"'%@' renames '%@'; the designer names tables itself -- use the table's own name or its %@0 form.", alias, token.text, token.text] error:error];
			return NO;
		}
		item.alias = alias;
		item.aliasLine = aliasToken.line;
		item.aliasColumn = aliasToken.column;
	} else if (wroteAS) {
		[self fail:MADSQLCompileErrorSyntax at:aliasToken message:@"Expected an alias after AS." error:error];
		return NO;
	}

	NSString *referencedBy = (item.alias != nil ? item.alias : item.tableName).lowercaseString;
	self.tableByAlias[referencedBy] = canonical;
	if (![self.fromTables containsObject:canonical]) {
		[self.fromTables addObject:canonical];
	}
	[self.fromItems addObject:item];
	return YES;
}

// The join's right side: table [AS alias], then the one equi-ON condition.
- (BOOL)parseJoinAfterType:(MADLinkType)type error:(NSError * __autoreleasing *)error {
	if (![self parseFromItemReturningError:error]) return NO;

	MADSQLFromItem *rightItem = self.fromItems.lastObject;
	MADSQLJoinClause *join = [MADSQLJoinClause new];
	join.type = type;
	join.rightTable = rightItem.alias != nil ? rightItem.alias : rightItem.tableName;
	join.line = rightItem.line;
	join.column = rightItem.column;

	if (![self matchKeyword:@"ON"]) {
		[self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected ON after the joined table." error:error];
		return NO;
	}

	MADSQLColumnReference *left = [self parseColumnReferenceReturningError:error];
	if (left == nil) return NO;

	// The link model holds one equi-condition; anything else is the
	// multi-condition or non-equi shape, or a literal side.
	if (![self symbolIs:@"="]) {
		[self fail:MADSQLCompileErrorUnsupportedOnCondition at:self.current
			 message:@"The link model holds one `left = right` condition per join." error:error];
		return NO;
	}
	[self advance];

	MADSQLColumnReference *right = [self parseColumnReferenceReturningError:error];
	if (right == nil) return NO;

	if (left.table != nil) {
		join.leftTable = left.table;
	} else {
		NSString *leftCanonical = [self canonicalTableForReference:left];
		join.leftTable = leftCanonical != nil ? leftCanonical : left.table;
	}
	join.leftColumn = left;
	join.rightColumn = right;

	if ([self keywordIs:@"AND"] || [self keywordIs:@"OR"]) {
		[self fail:MADSQLCompileErrorUnsupportedOnCondition at:self.current
			 message:@"The link model holds one `left = right` condition per join -- split the extra conditions into the WHERE clause." error:error];
		return NO;
	}

	// At most one join between a given pair of tables: two links between the
	// same pair would double the alias the generator emits.  The pair is the
	// ON condition's own sides, resolved through the alias map -- a drop-index
	// alias is not a schema name, and the join's right table is not the pair.
	NSString *leftCanonical = [self canonicalTableForJoinColumn:left];
	NSString *rightCanonical = [self canonicalTableForJoinColumn:right];
	if (leftCanonical != nil && rightCanonical != nil && ![leftCanonical isEqualToString:rightCanonical]) {
		for (MADSQLJoinClause *earlier in self.joins) {
			NSString *earlierLeft = self.tableByAlias[earlier.leftTable.lowercaseString];
			NSString *earlierRight = self.tableByAlias[earlier.rightTable.lowercaseString];
			BOOL samePair = ([earlierLeft isEqualToString:leftCanonical] && [earlierRight isEqualToString:rightCanonical]) ||
				([earlierLeft isEqualToString:rightCanonical] && [earlierRight isEqualToString:leftCanonical]);
			if (samePair) {
				[self fail:MADSQLCompileErrorDuplicateJoin at:[self tokenAtLine:rightItem.line column:rightItem.column]
					 message:[[NSString alloc] initWithFormat:@"A join between '%@' and '%@' already exists.", earlier.leftTable, earlier.rightTable] error:error];
				return NO;
			}
		}
	}

	[self.joins addObject:join];
	return YES;
}

// The canonical table an ON column belongs to: its qualifier's table when
// qualified, its unique FROM table when bare; nil when the FROM set does not
// answer yet (the reference validation reports it afterwards).
- (NSString *)canonicalTableForJoinColumn:(MADSQLColumnReference *)column {
	if (column.table != nil) {
		return self.tableByAlias[column.table.lowercaseString];
	}
	return [self canonicalTableForReference:column];
}

#pragma mark - WHERE, GROUP BY, ORDER BY

- (BOOL)parsePredicateList:(NSMutableArray<MADSQLPredicateTerm *> *)predicates error:(NSError * __autoreleasing *)error {
	for (;;) {
		if ([self keywordIs:@"NOT"]) {
			[self fail:MADSQLCompileErrorUnsupportedNOT at:self.current
				 message:@"NOT has no place in the model: a predicate holds one comparison, not its negation." error:error];
			return NO;
		}

		BOOL parenthesized = [self matchSymbol:@"("];

		MADSQLPredicateTerm *predicate = [self parsePredicateReturningError:error];
		if (predicate == nil) return NO;
		[predicates addObject:predicate];

		if (parenthesized) {
			if (![self matchSymbol:@")"]) {
				[self fail:MADSQLCompileErrorSyntax at:self.current message:@"Expected ')' to close the predicate." error:error];
				return NO;
			}
		}

		if ([self keywordIs:@"OR"]) {
			[self fail:MADSQLCompileErrorUnsupportedOR at:self.current
				 message:@"OR has no place in the model: predicates AND together, flat." error:error];
			return NO;
		}
		if ([self keywordIs:@"AND"]) {
			[self advance];
			continue;
		}
		return YES;
	}
}

- (MADSQLPredicateTerm *)parsePredicateReturningError:(NSError * __autoreleasing *)error {
	MADSQLPredicateTerm *predicate = [MADSQLPredicateTerm new];

	id left = [self parsePredicateSideReturningError:error];
	if (left == nil) return nil;
	if ([left isKindOfClass:[MADSQLColumnReference class]]) {
		predicate.leftColumn = left;
	} else {
		predicate.leftLiteral = left;
	}

	MADSQLToken *operatorToken = self.current;
	MADPredicateOperator operator = MADPredicateOperatorEqual;
	if ([self symbolIs:@"="]) operator = MADPredicateOperatorEqual;
	else if ([self symbolIs:@"<>"]) operator = MADPredicateOperatorNotEqual;
	else if ([self symbolIs:@">"]) operator = MADPredicateOperatorGreaterThan;
	else if ([self symbolIs:@">="]) operator = MADPredicateOperatorGreaterThanOrEqualTo;
	else if ([self symbolIs:@"<"]) operator = MADPredicateOperatorLessThan;
	else if ([self symbolIs:@"<="]) operator = MADPredicateOperatorLessThanOrEqualTo;
	else if ([self keywordIs:@"IN"]) {
		[self fail:MADSQLCompileErrorUnsupportedIN at:operatorToken
			 message:@"IN has no place in the model: a predicate holds one comparison." error:error];
		return nil;
	} else if ([self keywordIs:@"LIKE"]) {
		[self fail:MADSQLCompileErrorUnsupportedLIKE at:operatorToken
			 message:@"LIKE has no place in the model: a predicate holds one of six comparisons." error:error];
		return nil;
	} else if ([self keywordIs:@"BETWEEN"]) {
		[self fail:MADSQLCompileErrorUnsupportedBETWEEN at:operatorToken
			 message:@"BETWEEN has no place in the model: a predicate holds one comparison." error:error];
		return nil;
	} else {
		[self fail:MADSQLCompileErrorSyntax at:operatorToken message:@"Expected a comparison operator." error:error];
		return nil;
	}
	[self advance];
	predicate.operator = operator;

	id right = [self parsePredicateSideReturningError:error];
	if (right == nil) return nil;
	if ([right isKindOfClass:[MADSQLColumnReference class]]) {
		predicate.rightColumn = right;
	} else {
		predicate.rightLiteral = right;
	}

	return predicate;
}

// A column reference or a literal; a '(' here begins a subquery or nothing the
// model holds.
- (id)parsePredicateSideReturningError:(NSError * __autoreleasing *)error {
	MADSQLToken *token = self.current;

	if ([self symbolIs:@"("]) {
		[self advance];
		if ([self keywordIs:@"SELECT"]) {
			[self fail:MADSQLCompileErrorUnsupportedSubquery at:self.current
				 message:@"Subqueries have no place in the model: a predicate side is a column or a literal." error:error];
		} else {
			[self fail:MADSQLCompileErrorSyntax at:token message:@"Expected a column or a literal." error:error];
		}
		return nil;
	}

	if (token.kind == MADSQLTokenKindNumber) {
		[self advance];
		MADSQLLiteral *literal = [MADSQLLiteral new];
		literal.text = token.value;
		literal.numeric = YES;
		literal.line = token.line;
		literal.column = token.column;
		return literal;
	}
	if (token.kind == MADSQLTokenKindStringLiteral) {
		[self advance];
		MADSQLLiteral *literal = [MADSQLLiteral new];
		literal.text = token.value;
		literal.numeric = NO;
		literal.line = token.line;
		literal.column = token.column;
		return literal;
	}
	return [self parseColumnReferenceReturningError:error];
}

// A column reference, with the function-call shape rejected at the name.
- (MADSQLColumnReference *)parseColumnReferenceReturningError:(NSError * __autoreleasing *)error {
	MADSQLToken *token = self.current;
	if (token.kind != MADSQLTokenKindIdentifier && token.kind != MADSQLTokenKindQuotedIdentifier) {
		[self fail:MADSQLCompileErrorSyntax at:token message:@"Expected a column reference." error:error];
		return nil;
	}
	[self advance];

	MADSQLColumnReference *column = [MADSQLColumnReference new];
	column.line = token.line;
	column.column = token.column;

	if ([self matchSymbol:@"."]) {
		column.table = token.text;
		MADSQLToken *name = self.current;
		if (name.kind != MADSQLTokenKindIdentifier && name.kind != MADSQLTokenKindQuotedIdentifier) {
			[self fail:MADSQLCompileErrorSyntax at:name message:@"Expected a column name after the qualifier." error:error];
			return nil;
		}
		column.name = name.text;
		column.line = name.line;
		column.column = name.column;
		[self advance];
	} else if ([self symbolIs:@"("]) {
		[self fail:MADSQLCompileErrorUnsupportedExpression at:token
			 message:@"Functions and expressions have no place in the model: a predicate side is a column or a literal." error:error];
		return nil;
	} else {
		column.name = token.text;
	}

	return column;
}

- (NSMutableArray<MADSQLColumnReference *> *)parseColumnListReturningError:(NSError * __autoreleasing *)error {
	NSMutableArray<MADSQLColumnReference *> *columns = [NSMutableArray array];
	for (;;) {
		MADSQLColumnReference *column = [self parseColumnReferenceReturningError:error];
		if (column == nil) return nil;
		[columns addObject:column];
		if ([self matchSymbol:@","]) continue;
		break;
	}
	return columns;
}

- (NSMutableArray<MADSQLOrderTerm *> *)parseOrderListReturningError:(NSError * __autoreleasing *)error {
	NSMutableArray<MADSQLOrderTerm *> *terms = [NSMutableArray array];
	for (;;) {
		MADSQLColumnReference *column = [self parseColumnReferenceReturningError:error];
		if (column == nil) return nil;
		MADSQLOrderTerm *term = [MADSQLOrderTerm new];
		term.column = column;
		term.ascending = YES;
		if ([self keywordIs:@"ASC"]) {
			[self advance];
		} else if ([self keywordIs:@"DESC"]) {
			[self advance];
			term.ascending = NO;
		}
		[terms addObject:term];
		if ([self matchSymbol:@","]) continue;
		break;
	}
	return terms;
}

#pragma mark - Name resolution

- (NSString *)canonicalTableForName:(NSString *)name {
	return self.canonicalTables[name.lowercaseString];
}

// The canonical table a reference resolves to, without the existence checks.
- (NSString *)canonicalTableForReference:(MADSQLColumnReference *)column {
	if (column.table != nil) {
		return self.tableByAlias[column.table.lowercaseString];
	}
	NSString *match = nil;
	for (NSString *table in self.fromTables) {
		NSSet<NSString *> *fields = self.fieldsByTable[table.lowercaseString];
		if ([fields containsObject:column.name.lowercaseString]) {
			if (match != nil) return nil;	// ambiguous
			match = table;
		}
	}
	return match;
}

// The unknown/ambiguous checks every column goes through once the FROM set is
// known.  Returns nil after recording the error.
- (BOOL)validateReference:(MADSQLColumnReference *)column error:(NSError * __autoreleasing *)error {
	if (column.isWildcard) {
		if (column.table == nil || self.tableByAlias[column.table.lowercaseString] == nil) {
			if (error) {
				*error = [MADSQLCompileError errorWithCode:MADSQLCompileErrorUnknownColumn
													  line:column.line
													column:column.column
												   message:[[NSString alloc] initWithFormat:@"Unknown table '%@' for the wildcard.", column.table]];
			}
			return NO;
		}
		return YES;
	}

	MADSQLToken *nameToken = [self tokenAtLine:column.line column:column.column];
	if (column.table != nil) {
		NSString *canonical = self.tableByAlias[column.table.lowercaseString];
		if (canonical == nil) {
			[self fail:MADSQLCompileErrorUnknownColumn at:nameToken
				 message:[[NSString alloc] initWithFormat:@"'%@' is not a table of the FROM set.", column.table] error:error];
			return NO;
		}
		if (![self.fieldsByTable[canonical.lowercaseString] containsObject:column.name.lowercaseString]) {
			[self fail:MADSQLCompileErrorUnknownColumn at:nameToken
				 message:[[NSString alloc] initWithFormat:@"Unknown column '%@'.%@'.", column.table, column.name] error:error];
			return NO;
		}
		return YES;
	}

	NSString *match = nil;
	NSUInteger matches = 0;
	for (NSString *table in self.fromTables) {
		if ([self.fieldsByTable[table.lowercaseString] containsObject:column.name.lowercaseString]) {
			match = table;
			matches++;
		}
	}
	if (matches == 0) {
		[self fail:MADSQLCompileErrorUnknownColumn at:nameToken
			 message:[[NSString alloc] initWithFormat:@"Unknown column '%@'.", column.name] error:error];
		return NO;
	}
	if (matches > 1) {
		[self fail:MADSQLCompileErrorAmbiguousColumn at:nameToken
			 message:[[NSString alloc] initWithFormat:@"'%@' is ambiguous across the FROM set; qualify it.", column.name] error:error];
		return NO;
	}
	return YES;
}

- (BOOL)validateColumns:(NSArray<MADSQLColumnReference *> *)columns error:(NSError * __autoreleasing *)error {
	for (MADSQLColumnReference *column in columns) {
		if (![self validateReference:column error:error]) return NO;
	}
	return YES;
}

// ORDER BY must sit inside the GROUP BY set, by resolved identity -- the model
// has no free sort.
- (BOOL)validateOrderBy:(NSArray<MADSQLOrderTerm *> *)terms within:(NSArray<MADSQLColumnReference *> *)groupColumns error:(NSError * __autoreleasing *)error {
	NSMutableSet<NSString *> *groupSet = [NSMutableSet setWithCapacity:groupColumns.count];
	for (MADSQLColumnReference *column in groupColumns) {
		NSString *canonical = [self canonicalTableForReference:column];
		if (canonical != nil) {
			[groupSet addObject:[[NSString alloc] initWithFormat:@"%@.%@", canonical.lowercaseString, column.name.lowercaseString]];
		}
	}
	for (MADSQLOrderTerm *term in terms) {
		NSString *canonical = [self canonicalTableForReference:term.column];
		NSString *identity = [[NSString alloc] initWithFormat:@"%@.%@", canonical.lowercaseString, term.column.name.lowercaseString];
		if (![groupSet containsObject:identity]) {
			MADSQLToken *nameToken = [self tokenAtLine:term.column.line column:term.column.column];
			[self fail:MADSQLCompileErrorOrderByOutsideGroupBy at:nameToken
				 message:@"The model has no free sort: every ORDER BY column must be a GROUP BY column." error:error];
			return NO;
		}
	}
	return YES;
}

// The token a recorded position points at; the End token when nothing does.
- (MADSQLToken *)tokenAtLine:(NSInteger)line column:(NSInteger)column {
	for (MADSQLToken *token in self.tokens) {
		if (token.line == line && token.column == column) return token;
	}
	return self.tokens.lastObject;
}

@end
