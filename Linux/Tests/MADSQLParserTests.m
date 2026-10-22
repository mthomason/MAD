//
//  MADSQLParserTests.m
//  Linux/Tests
//
//  Ported from MADTests/MADSQLParserTests.m: the pasted-SQL importer's front half
//  (MAD_SQL_ENTRY.md §5, §10.3) -- the tokenizer's per-dialect quoting and
//  line:column positions, the parser's accept matrix and its rejection table,
//  each rejection asserting the error code and the line:column, never just the
//  message.
//
//  The fixture schema is three tables with the fields the golden generator's
//  fixtures use, so what the parser accepts here is what MADQueryFull can emit.
//

#import "MADTestSupport.h"

#import <MADAPI/MADDatabase.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>

#import <MAD/MADSQLCompileError.h>
#import <MAD/MADSQLParser.h>
#import <MAD/MADSQLStatement.h>
#import <MAD/MADSQLTokenizer.h>

#pragma mark - Fixture

static NSDictionary *FixtureSchema(void) {
	return @{
		@"customers": @[ @"id", @"name" ],
		@"invoices": @[ @"id", @"customer_id", @"amount" ],
		@"lines": @[ @"id", @"invoice_id", @"sku" ],
	};
}

static MADSQLParser *ParserForSQL(NSString *sql) {
	return [[MADSQLParser alloc] initWithSQL:sql
					 identifierQuoteCharacters:[MADDatabase identifierQuoteCharacters]
									   schema:FixtureSchema()];
}

static MADSQLParser *ParserForSQLWithQuotes(NSString *sql, NSString *quotes) {
	return [[MADSQLParser alloc] initWithSQL:sql identifierQuoteCharacters:quotes schema:FixtureSchema()];
}

#pragma mark - Helpers

static MADSQLStatement *ParseStatement(NSString *sql) {
	MADSQLParser *parser = ParserForSQL(sql);
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];
	MAD_PASS(statement != nil, "%s: %s", [sql UTF8String],
			 error != nil ? [[error description] UTF8String] : "no error");
	return statement;
}

static MADSQLStatement *ParseStatementWithQuotes(NSString *sql, NSString *quotes) {
	MADSQLParser *parser = ParserForSQLWithQuotes(sql, quotes);
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];
	MAD_PASS(statement != nil, "%s: %s", [sql UTF8String],
			 error != nil ? [[error description] UTF8String] : "no error");
	return statement;
}

static void AssertParseFails(NSString *sql, MADSQLCompileErrorCode code, NSInteger line, NSInteger column) {
	MADSQLParser *parser = ParserForSQL(sql);
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];

	MAD_PASS(statement == nil, "%s should not parse", [sql UTF8String]);
	if (statement != nil) return;
	MAD_PASS(error != nil, "%s should fail with an error", [sql UTF8String]);
	if (error == nil) return;
	MAD_PASS_EQUAL(error.domain, MADSQLCompileErrorDomain, "%s: %s", [sql UTF8String], [[error description] UTF8String]);
	MAD_PASS(error.code == (NSInteger)code, "%s: %s", [sql UTF8String], [[error description] UTF8String]);
	MAD_PASS_EQUAL(error.userInfo[MADSQLCompileErrorLineKey], @(line), "%s: %s", [sql UTF8String], [[error description] UTF8String]);
	MAD_PASS_EQUAL(error.userInfo[MADSQLCompileErrorColumnKey], @(column), "%s: %s", [sql UTF8String], [[error description] UTF8String]);
}

#pragma mark - The identifier-quote API

static void testIdentifierQuoteCharactersPerDriver(void) {
	MAD_PASS_EQUAL([MADDatabase identifierQuoteCharacters], @"\"\"", "the base dialect quotes with double quotes");
	MAD_PASS_EQUAL([MADDatabaseMySQL identifierQuoteCharacters], @"``", "MySQL quotes with backticks");
	MAD_PASS_EQUAL([MADDatabaseSQLServer identifierQuoteCharacters], @"[]", "T-SQL quotes with brackets");
}

#pragma mark - The tokenizer

static void testTokenizerTracksLineAndColumn(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"SELECT name\nFROM customers"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS([tokenizer tokenizeWithError:&error], "%s", [[error description] UTF8String]);
	NSArray *tokens = tokenizer.tokens;
	MAD_PASS(tokens != nil, "the tokenizer yields tokens");

	MAD_PASS(tokens.count == (NSUInteger)5, "SELECT, name, FROM, customers, End");
	MAD_PASS(tokens[0].kind == MADSQLTokenKindIdentifier, "SELECT is an identifier token");
	MAD_PASS(tokens[0].isKeyword, "SELECT is a keyword");
	MAD_PASS_EQUAL(tokens[0].text, @"SELECT", "the first token's text");
	MAD_PASS(tokens[0].line == 1, "SELECT is on line 1");
	MAD_PASS(tokens[0].column == 1, "SELECT is at column 1");

	MAD_PASS_EQUAL(tokens[1].text, @"name", "the second token's text");
	MAD_PASS(!tokens[1].isKeyword, "name is not a keyword");
	MAD_PASS(tokens[1].line == 1, "name is on line 1");
	MAD_PASS(tokens[1].column == 8, "name is at column 8");

	MAD_PASS_EQUAL(tokens[2].text, @"FROM", "the third token's text");
	MAD_PASS(tokens[2].line == 2, "FROM is on line 2");
	MAD_PASS(tokens[2].column == 1, "FROM is at column 1");

	MAD_PASS_EQUAL(tokens[3].text, @"customers", "the fourth token's text");
	MAD_PASS(tokens[3].line == 2, "customers is on line 2");
	MAD_PASS(tokens[3].column == 6, "customers is at column 6");

	MAD_PASS(tokens[4].kind == MADSQLTokenKindEnd, "the last token is End");
}

static void testTokenizerReadsQuotedIdentifiersPerDialect(void) {
	NSDictionary *cases = @{
		@"``": @[ @"`name`", @"name" ],
		@"[]": @[ @"[name]", @"name" ],
		@"\"\"": @[ @"\"name\"", @"name" ],
	};
	for (NSString *quotes in cases) {
		NSArray *expected = cases[quotes];
		MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:expected.firstObject
											   identifierQuoteCharacters:quotes];
		NSError *error = nil;
		MAD_PASS([tokenizer tokenizeWithError:&error], "%s", [[error description] UTF8String]);
		MAD_PASS(tokenizer.tokens.count == (NSUInteger)2, "an identifier and End");
		MAD_PASS(tokenizer.tokens.firstObject.kind == MADSQLTokenKindQuotedIdentifier, "the token is a quoted identifier");
		MAD_PASS_EQUAL(tokenizer.tokens.firstObject.text, expected.lastObject, "the quoted identifier's name");
	}
}

static void testTokenizerReadsStringLiteralsWithEscapedQuotes(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"'O''Brien'"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS([tokenizer tokenizeWithError:&error], "%s", [[error description] UTF8String]);
	MAD_PASS(tokenizer.tokens.count == (NSUInteger)2, "a literal and End");
	MAD_PASS(tokenizer.tokens.firstObject.kind == MADSQLTokenKindStringLiteral, "the token is a string literal");
	MAD_PASS_EQUAL(tokenizer.tokens.firstObject.value, @"O'Brien", "the unescaped literal value");
}

static void testTokenizerReadsNumbers(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"42 1.5"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS([tokenizer tokenizeWithError:&error], "%s", [[error description] UTF8String]);
	MAD_PASS(tokenizer.tokens.count == (NSUInteger)3, "two numbers and End");
	MAD_PASS(tokenizer.tokens[0].kind == MADSQLTokenKindNumber, "the first token is a number");
	MAD_PASS_EQUAL(tokenizer.tokens[0].value, @"42", "the first number's value");
	MAD_PASS(tokenizer.tokens[1].kind == MADSQLTokenKindNumber, "the second token is a number");
	MAD_PASS_EQUAL(tokenizer.tokens[1].value, @"1.5", "the second number's value");
}

static void testTokenizerSkipsComments(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"-- a comment\nSELECT /* another */ name"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS([tokenizer tokenizeWithError:&error], "%s", [[error description] UTF8String]);
	NSArray *tokens = tokenizer.tokens;
	MAD_PASS(tokens.count == (NSUInteger)3, "SELECT, name and End");
	MAD_PASS_EQUAL(tokens[0].text, @"SELECT", "the first token");
	MAD_PASS(tokens[0].line == 2, "SELECT is on line 2 after the line comment");
	MAD_PASS_EQUAL(tokens[1].text, @"name", "the second token");
	MAD_PASS(tokens[1].line == 2, "name is on line 2 after the block comment");
}

static void testTokenizerReadsEveryOperator(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"= <> > >= < <= ( ) , . *"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS([tokenizer tokenizeWithError:&error], "%s", [[error description] UTF8String]);
	NSArray *tokens = tokenizer.tokens;
	MAD_PASS(tokens.count == (NSUInteger)12, "eleven operators and End");
	NSArray *expected = @[ @"=", @"<>", @">", @">=", @"<", @"<=", @"(", @")", @",", @".", @"*" ];
	for (NSUInteger index = 0; index < expected.count; index++) {
		MAD_PASS(tokens[index].kind == MADSQLTokenKindSymbol, "token %lu is a symbol", (unsigned long)index);
		MAD_PASS_EQUAL(tokens[index].text, expected[index], "the symbol's text");
	}
}

static void testTokenizerReportsUnterminatedStringAtItsQuote(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"SELECT name FROM customers WHERE name = 'abc"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS(![tokenizer tokenizeWithError:&error], "an unterminated literal is an error");
	MAD_PASS_EQUAL(error.domain, MADSQLCompileErrorDomain, "the error domain");
	MAD_PASS(error.code == (NSInteger)MADSQLCompileErrorSyntax, "the error code");
	MAD_PASS_EQUAL(error.userInfo[MADSQLCompileErrorLineKey], @1, "the error line");
	MAD_PASS_EQUAL(error.userInfo[MADSQLCompileErrorColumnKey], @41, "the error column");
}

static void testTokenizerReportsUnterminatedCommentAtItsStart(void) {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"SELECT name FROM customers /* never closed"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	MAD_PASS(![tokenizer tokenizeWithError:&error], "an unterminated comment is an error");
	MAD_PASS(error.code == (NSInteger)MADSQLCompileErrorSyntax, "the error code");
	MAD_PASS_EQUAL(error.userInfo[MADSQLCompileErrorLineKey], @1, "the error line");
	MAD_PASS_EQUAL(error.userInfo[MADSQLCompileErrorColumnKey], @28, "the error column");
}

#pragma mark - The accept matrix

static void testSingleTableSelect(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT name FROM customers");

	MAD_PASS(statement.selectColumns.count == (NSUInteger)1, "one select column");
	MAD_PASS(statement.selectColumns.firstObject.table == nil, "the column is bare");
	MAD_PASS_EQUAL(statement.selectColumns.firstObject.name, @"name", "the column's name");
	MAD_PASS(!statement.selectColumns.firstObject.isWildcard, "the column is not a wildcard");

	MAD_PASS(statement.fromItems.count == (NSUInteger)1, "one from item");
	MAD_PASS_EQUAL(statement.fromItems.firstObject.tableName, @"customers", "the table's name");
	MAD_PASS(statement.fromItems.firstObject.alias == nil, "no alias was written");

	MAD_PASS(statement.joins.count == (NSUInteger)0, "no joins");
	MAD_PASS(statement.predicates.count == (NSUInteger)0, "no predicates");
	MAD_PASS(statement.groupByColumns.count == (NSUInteger)0, "no group by");
	MAD_PASS(statement.orderByTerms.count == (NSUInteger)0, "no order by");
}

static void testQuotedIdentifiersParsePerDialect(void) {
	NSDictionary *cases = @{
		@"``": @"SELECT `name` FROM `customers`",
		@"[]": @"SELECT [name] FROM [customers]",
		@"\"\"": @"SELECT \"name\" FROM \"customers\"",
	};
	for (NSString *quotes in cases) {
		MADSQLStatement *statement = ParseStatementWithQuotes(cases[quotes], quotes);
		MAD_PASS_EQUAL(statement.selectColumns.firstObject.name, @"name", "the quoted column's name");
		MAD_PASS_EQUAL(statement.fromItems.firstObject.tableName, @"customers", "the quoted table's name");
	}
}

static void testQualifiedAndBareColumnsMix(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT customers.name, id FROM customers");

	MAD_PASS(statement.selectColumns.count == (NSUInteger)2, "two select columns");
	MAD_PASS_EQUAL(statement.selectColumns[0].table, @"customers", "the first column's qualifier");
	MAD_PASS_EQUAL(statement.selectColumns[0].name, @"name", "the first column's name");
	MAD_PASS(statement.selectColumns[1].table == nil, "the second column is bare");
	MAD_PASS_EQUAL(statement.selectColumns[1].name, @"id", "the second column's name");
}

static void testQualifiedWildcardSelect(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT customers.* FROM customers");

	MAD_PASS(statement.selectColumns.count == (NSUInteger)1, "one select column");
	MAD_PASS(statement.selectColumns.firstObject.isWildcard, "the column is a wildcard");
	MAD_PASS_EQUAL(statement.selectColumns.firstObject.table, @"customers", "the wildcard's qualifier");
}

static void testEachJoinTypeParses(void) {
	NSDictionary *cases = @{
		@"INNER JOIN": @(MADLinkTypeInnerJoin),
		@"JOIN": @(MADLinkTypeEquiJoin),
		@"LEFT JOIN": @(MADLinkTypeLeftOuterJoin),
		@"LEFT OUTER JOIN": @(MADLinkTypeLeftOuterJoin),
		@"RIGHT JOIN": @(MADLinkTypeRightOuterJoin),
		@"RIGHT OUTER JOIN": @(MADLinkTypeRightOuterJoin),
		@"FULL JOIN": @(MADLinkTypeFullOuterJoin),
		@"FULL OUTER JOIN": @(MADLinkTypeFullOuterJoin),
	};
	for (NSString *keyword in cases) {
		NSString *sql = [[NSString alloc] initWithFormat:
			@"SELECT invoices.id FROM customers %@ invoices ON customers.id = invoices.customer_id", keyword];
		MADSQLStatement *statement = ParseStatement(sql);

		MAD_PASS(statement.joins.count == (NSUInteger)1, "%s: one join", [keyword UTF8String]);
		MAD_PASS(statement.joins.firstObject.type == (MADLinkType)[cases[keyword] integerValue], "%s: the join type", [keyword UTF8String]);
		MAD_PASS_EQUAL(statement.joins.firstObject.leftTable, @"customers", "%s: the left table", [keyword UTF8String]);
		MAD_PASS_EQUAL(statement.joins.firstObject.rightTable, @"invoices", "%s: the right table", [keyword UTF8String]);
		MAD_PASS_EQUAL(statement.joins.firstObject.leftColumn.table, @"customers", "%s: the left column's table", [keyword UTF8String]);
		MAD_PASS_EQUAL(statement.joins.firstObject.leftColumn.name, @"id", "%s: the left column's name", [keyword UTF8String]);
		MAD_PASS_EQUAL(statement.joins.firstObject.rightColumn.table, @"invoices", "%s: the right column's table", [keyword UTF8String]);
		MAD_PASS_EQUAL(statement.joins.firstObject.rightColumn.name, @"customer_id", "%s: the right column's name", [keyword UTF8String]);
	}
}

static void testJoinOnBareColumnsWhenUnambiguous(void) {
	// `name` is only on customers and `customer_id` only on invoices, so the bare
	// ON columns resolve.
	MADSQLStatement *statement =
		ParseStatement(@"SELECT invoices.amount FROM customers INNER JOIN invoices ON name = customer_id");

	MAD_PASS(statement.joins.firstObject.leftColumn.table == nil, "the left ON column is bare");
	MAD_PASS_EQUAL(statement.joins.firstObject.leftColumn.name, @"name", "the left ON column's name");
	MAD_PASS(statement.joins.firstObject.rightColumn.table == nil, "the right ON column is bare");
	MAD_PASS_EQUAL(statement.joins.firstObject.rightColumn.name, @"customer_id", "the right ON column's name");
}

static void testJoinChainsParse(void) {
	MADSQLStatement *statement = ParseStatement(
		@"SELECT lines.sku FROM customers INNER JOIN invoices ON customers.id = invoices.customer_id "
		@"INNER JOIN lines ON invoices.id = lines.invoice_id");

	MAD_PASS(statement.joins.count == (NSUInteger)2, "two joins");
	MAD_PASS_EQUAL(statement.joins[1].leftTable, @"invoices", "the second join's left table");
	MAD_PASS_EQUAL(statement.joins[1].rightTable, @"lines", "the second join's right table");
}

static void testDropIndexAliasesParse(void) {
	// The generator's own alias forms: the table's name, and name+index for each
	// further copy of the same table.
	MADSQLStatement *statement = ParseStatement(
		@"SELECT invoices0.id FROM invoices AS invoices0 "
		@"INNER JOIN invoices AS invoices1 ON invoices0.id = invoices1.customer_id");

	MAD_PASS(statement.fromItems.count == (NSUInteger)2, "the base table and the joined copy");
	MAD_PASS_EQUAL(statement.fromItems.firstObject.tableName, @"invoices", "the base table");
	MAD_PASS_EQUAL(statement.fromItems.firstObject.alias, @"invoices0", "the base table's alias");
	MAD_PASS_EQUAL(statement.fromItems.lastObject.tableName, @"invoices", "the joined copy's table");
	MAD_PASS_EQUAL(statement.fromItems.lastObject.alias, @"invoices1", "the joined copy's alias");
	MAD_PASS_EQUAL(statement.joins.firstObject.rightTable, @"invoices1", "the second copy's alias");
}

static void testTheTablesOwnNameIsAValidAlias(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT invoices.id FROM invoices AS invoices");
	MAD_PASS_EQUAL(statement.fromItems.firstObject.alias, @"invoices", "the table's own name is its alias");
}

static void testImplicitAliasParses(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT invoices0.id FROM invoices invoices0");
	MAD_PASS_EQUAL(statement.fromItems.firstObject.alias, @"invoices0", "an implicit alias parses");
}

static void testWhereConjunctionParses(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT name FROM customers WHERE name = 'A' AND id > 5");

	MAD_PASS(statement.predicates.count == (NSUInteger)2, "two predicates");

	MADSQLPredicateTerm *first = statement.predicates[0];
	MAD_PASS(first.operator == MADPredicateOperatorEqual, "the first predicate's operator");
	MAD_PASS(first.leftColumn.table == nil, "the first predicate's bare left column");
	MAD_PASS_EQUAL(first.leftColumn.name, @"name", "the first predicate's left column");
	MAD_PASS(first.rightLiteral != nil, "the first predicate's literal right side");
	MAD_PASS_EQUAL(first.rightLiteral.text, @"A", "the first predicate's literal");
	MAD_PASS(!first.rightLiteral.isNumeric, "the first predicate's literal is text");

	MADSQLPredicateTerm *second = statement.predicates[1];
	MAD_PASS(second.operator == MADPredicateOperatorGreaterThan, "the second predicate's operator");
	MAD_PASS_EQUAL(second.leftColumn.name, @"id", "the second predicate's left column");
	MAD_PASS(second.rightLiteral != nil, "the second predicate's literal right side");
	MAD_PASS_EQUAL(second.rightLiteral.text, @"5", "the second predicate's literal");
	MAD_PASS(second.rightLiteral.isNumeric, "the second predicate's literal is numeric");
}

static void testPredicateWithColumnOnBothSidesParses(void) {
	MADSQLStatement *statement = ParseStatement(
		@"SELECT invoices.amount FROM customers INNER JOIN invoices ON customers.id = invoices.customer_id "
		@"WHERE customers.id = invoices.id");

	MAD_PASS(statement.predicates.count == (NSUInteger)1, "one predicate");
	MAD_PASS_EQUAL(statement.predicates.firstObject.leftColumn.table, @"customers", "the left column's table");
	MAD_PASS_EQUAL(statement.predicates.firstObject.rightColumn.table, @"invoices", "the right column's table");
	MAD_PASS(statement.predicates.firstObject.leftLiteral == nil, "no left literal");
	MAD_PASS(statement.predicates.firstObject.rightLiteral == nil, "no right literal");
}

static void testPredicateWithLiteralOnTheLeftParses(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT name FROM customers WHERE 5 < id");

	MAD_PASS(statement.predicates.count == (NSUInteger)1, "one predicate");
	MAD_PASS(statement.predicates.firstObject.operator == MADPredicateOperatorLessThan, "the operator");
	MAD_PASS(statement.predicates.firstObject.leftLiteral != nil, "the literal left side");
	MAD_PASS_EQUAL(statement.predicates.firstObject.leftLiteral.text, @"5", "the literal");
	MAD_PASS_EQUAL(statement.predicates.firstObject.rightColumn.name, @"id", "the right column");
}

static void testParensAroundAConjunctionParse(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT name FROM customers WHERE (name = 'A') AND (id >= 5)");

	MAD_PASS(statement.predicates.count == (NSUInteger)2, "two predicates");
	MAD_PASS(statement.predicates[1].operator == MADPredicateOperatorGreaterThanOrEqualTo, "the second operator");
}

static void testStringLiteralsKeepTheirEscapedQuotes(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT name FROM customers WHERE name = 'O''Brien'");

	MAD_PASS_EQUAL(statement.predicates.firstObject.rightLiteral.text, @"O'Brien", "the literal's value");
}

static void testGroupByParses(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT name, id FROM customers GROUP BY name, id");

	MAD_PASS(statement.groupByColumns.count == (NSUInteger)2, "two group columns");
	MAD_PASS_EQUAL(statement.groupByColumns[0].name, @"name", "the first group column");
	MAD_PASS_EQUAL(statement.groupByColumns[1].name, @"id", "the second group column");
}

static void testOrderByWithinTheGroupByParses(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT name FROM customers GROUP BY name ORDER BY name DESC");

	MAD_PASS(statement.orderByTerms.count == (NSUInteger)1, "one order term");
	MAD_PASS_EQUAL(statement.orderByTerms.firstObject.column.name, @"name", "the order column");
	MAD_PASS(!statement.orderByTerms.firstObject.isAscending, "DESC is descending");
}

static void testOrderByDefaultsToAscending(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT name FROM customers GROUP BY name ORDER BY name");

	MAD_PASS(statement.orderByTerms.firstObject.isAscending, "the default is ascending");
}

static void testOrderByMatchesTheGroupByByIdentityNotSpelling(void) {
	// The bare ORDER BY column resolves to the same field as the qualified GROUP BY
	// column, so it is inside the group set.
	MADSQLStatement *statement = ParseStatement(
		@"SELECT customers.name FROM customers GROUP BY customers.name ORDER BY name");
	MAD_PASS(statement.orderByTerms.count == (NSUInteger)1, "the order term parses");
}

static void testCommentsAreSkipped(void) {
	MAD_PASS(ParseStatement(@"-- the customers\nSELECT name FROM customers") != nil, "a line comment is skipped");
	MAD_PASS(ParseStatement(@"/* the customers */ SELECT name FROM customers") != nil, "a block comment is skipped");
	MAD_PASS(ParseStatement(@"SELECT name /* the name */ FROM customers") != nil, "a mid-statement comment is skipped");
}

static void testKeywordsAreCaseInsensitive(void) {
	MADSQLStatement *statement =
		ParseStatement(@"select name from customers where name = 'a' group by name order by name");
	MAD_PASS(statement.predicates.count == (NSUInteger)1, "the lowercase WHERE parses");
	MAD_PASS(statement.groupByColumns.count == (NSUInteger)1, "the lowercase GROUP BY parses");
}

static void testNumericLiteralsParse(void) {
	MADSQLStatement *statement =
		ParseStatement(@"SELECT invoices.amount FROM invoices WHERE id = 42 AND amount >= 1.5");
	MAD_PASS_EQUAL(statement.predicates[0].rightLiteral.text, @"42", "the integer literal");
	MAD_PASS_EQUAL(statement.predicates[1].rightLiteral.text, @"1.5", "the decimal literal");
}

static void testATrailingSemicolonParses(void) {
	MADSQLStatement *statement = ParseStatement(@"SELECT name FROM customers;");
	MAD_PASS(statement.selectColumns.count == (NSUInteger)1, "the statement parses");
}

#pragma mark - The rejection table

static void testORIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE id = 1 OR id = 2",
					 MADSQLCompileErrorUnsupportedOR, 1, 41);
}

static void testINIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE id IN (1, 2)",
					 MADSQLCompileErrorUnsupportedIN, 1, 37);
}

static void testLIKEIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE name LIKE 'A%'",
					 MADSQLCompileErrorUnsupportedLIKE, 1, 39);
}

static void testBETWEENIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE id BETWEEN 1 AND 2",
					 MADSQLCompileErrorUnsupportedBETWEEN, 1, 37);
}

static void testNOTIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE NOT id = 1",
					 MADSQLCompileErrorUnsupportedNOT, 1, 34);
}

static void testASubqueryInTheWhereClauseIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE id = (SELECT MAX(id) FROM invoices)",
					 MADSQLCompileErrorUnsupportedSubquery, 1, 40);
}

static void testASubqueryInTheFromClauseIsRejected(void) {
	AssertParseFails(@"SELECT name FROM (SELECT id FROM invoices)",
					 MADSQLCompileErrorUnsupportedSubquery, 1, 19);
}

static void testUNIONIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers UNION SELECT id FROM invoices",
					 MADSQLCompileErrorUnsupportedUNION, 1, 28);
}

static void testDISTINCTIsRejected(void) {
	AssertParseFails(@"SELECT DISTINCT name FROM customers",
					 MADSQLCompileErrorUnsupportedDISTINCT, 1, 8);
}

static void testAFunctionInTheSelectListIsRejected(void) {
	AssertParseFails(@"SELECT MAX(id) FROM customers",
					 MADSQLCompileErrorUnsupportedExpression, 1, 8);
}

static void testArithmeticInTheSelectListIsRejected(void) {
	AssertParseFails(@"SELECT id + 1 FROM customers",
					 MADSQLCompileErrorUnsupportedExpression, 1, 11);
}

static void testASelectAliasIsRejected(void) {
	AssertParseFails(@"SELECT name AS n FROM customers",
					 MADSQLCompileErrorUnsupportedSelectAlias, 1, 13);
}

static void testABareStarIsRejected(void) {
	AssertParseFails(@"SELECT * FROM customers",
					 MADSQLCompileErrorUnsupportedExpression, 1, 8);
}

static void testAFunctionInTheWhereClauseIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers WHERE LOWER(name) = 'a'",
					 MADSQLCompileErrorUnsupportedExpression, 1, 34);
}

static void testAMultiConditionOnClauseIsRejected(void) {
	AssertParseFails(@"SELECT invoices.id FROM customers INNER JOIN invoices "
					 @"ON customers.id = invoices.customer_id AND invoices.id > 5",
					 MADSQLCompileErrorUnsupportedOnCondition, 1, 93);
}

static void testANonEquiOnClauseIsRejected(void) {
	AssertParseFails(@"SELECT invoices.id FROM customers INNER JOIN invoices "
					 @"ON customers.id > invoices.customer_id",
					 MADSQLCompileErrorUnsupportedOnCondition, 1, 71);
}

static void testARenamedAliasIsRejected(void) {
	AssertParseFails(@"SELECT c.id FROM customers AS c",
					 MADSQLCompileErrorUnsupportedAlias, 1, 31);
}

static void testACommaJoinIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers, invoices",
					 MADSQLCompileErrorUnsupportedCommaJoin, 1, 27);
}

static void testANaturalJoinIsRejected(void) {
	AssertParseFails(@"SELECT invoices.id FROM customers NATURAL JOIN invoices "
					 @"ON customers.id = invoices.customer_id",
					 MADSQLCompileErrorUnsupportedNaturalCrossJoin, 1, 35);
}

static void testACrossJoinIsRejected(void) {
	AssertParseFails(@"SELECT invoices.id FROM customers CROSS JOIN invoices "
					 @"ON customers.id = invoices.customer_id",
					 MADSQLCompileErrorUnsupportedNaturalCrossJoin, 1, 35);
}

static void testLIMITIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers LIMIT 10",
					 MADSQLCompileErrorUnsupportedLIMIT, 1, 28);
}

static void testAnUnknownTableIsRejected(void) {
	AssertParseFails(@"SELECT name FROM nope",
					 MADSQLCompileErrorUnknownTable, 1, 19);
}

static void testAnUnknownColumnIsRejected(void) {
	AssertParseFails(@"SELECT nope FROM customers",
					 MADSQLCompileErrorUnknownColumn, 1, 8);
}

static void testAnAmbiguousSelectColumnIsRejected(void) {
	AssertParseFails(@"SELECT id FROM customers INNER JOIN invoices "
					 @"ON customers.id = invoices.customer_id",
					 MADSQLCompileErrorAmbiguousColumn, 1, 8);
}

static void testAnAmbiguousWhereColumnIsRejected(void) {
	AssertParseFails(@"SELECT customers.id FROM customers INNER JOIN invoices "
					 @"ON customers.id = invoices.customer_id WHERE id = 5",
					 MADSQLCompileErrorAmbiguousColumn, 1, 96);
}

static void testAnOrderByOutsideTheGroupByIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers ORDER BY name",
					 MADSQLCompileErrorOrderByOutsideGroupBy, 1, 37);
}

static void testAnOrderByPartiallyOutsideTheGroupByIsRejected(void) {
	AssertParseFails(@"SELECT name, id FROM customers GROUP BY name ORDER BY id",
					 MADSQLCompileErrorOrderByOutsideGroupBy, 1, 55);
}

static void testARepeatedJoinBetweenTheSamePairIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers INNER JOIN invoices "
					 @"ON customers.id = invoices.customer_id INNER JOIN invoices "
					 @"ON invoices.customer_id = customers.id",
					 MADSQLCompileErrorDuplicateJoin, 1, 101);
}

static void testASecondStatementIsRejected(void) {
	AssertParseFails(@"SELECT name FROM customers; SELECT id FROM invoices",
					 MADSQLCompileErrorSyntax, 1, 29);
}

static void testSomethingThatIsNotASelectIsRejected(void) {
	AssertParseFails(@"SELEC name FROM customers",
					 MADSQLCompileErrorSyntax, 1, 1);
}

static void testAnEmptyStatementIsRejected(void) {
	AssertParseFails(@"",
					 MADSQLCompileErrorSyntax, 1, 1);
}

static void testAMultiLineRejectionCarriesItsLine(void) {
	AssertParseFails(@"SELECT name\nFROM customers\nWHERE name = 'A' OR id = 2",
					 MADSQLCompileErrorUnsupportedOR, 3, 18);
}

MAD_TEST_MAIN("MADSQLParserTests",
	MAD_TEST(testIdentifierQuoteCharactersPerDriver),
	MAD_TEST(testTokenizerTracksLineAndColumn),
	MAD_TEST(testTokenizerReadsQuotedIdentifiersPerDialect),
	MAD_TEST(testTokenizerReadsStringLiteralsWithEscapedQuotes),
	MAD_TEST(testTokenizerReadsNumbers),
	MAD_TEST(testTokenizerSkipsComments),
	MAD_TEST(testTokenizerReadsEveryOperator),
	MAD_TEST(testTokenizerReportsUnterminatedStringAtItsQuote),
	MAD_TEST(testTokenizerReportsUnterminatedCommentAtItsStart),
	MAD_TEST(testSingleTableSelect),
	MAD_TEST(testQuotedIdentifiersParsePerDialect),
	MAD_TEST(testQualifiedAndBareColumnsMix),
	MAD_TEST(testQualifiedWildcardSelect),
	MAD_TEST(testEachJoinTypeParses),
	MAD_TEST(testJoinOnBareColumnsWhenUnambiguous),
	MAD_TEST(testJoinChainsParse),
	MAD_TEST(testDropIndexAliasesParse),
	MAD_TEST(testTheTablesOwnNameIsAValidAlias),
	MAD_TEST(testImplicitAliasParses),
	MAD_TEST(testWhereConjunctionParses),
	MAD_TEST(testPredicateWithColumnOnBothSidesParses),
	MAD_TEST(testPredicateWithLiteralOnTheLeftParses),
	MAD_TEST(testParensAroundAConjunctionParse),
	MAD_TEST(testStringLiteralsKeepTheirEscapedQuotes),
	MAD_TEST(testGroupByParses),
	MAD_TEST(testOrderByWithinTheGroupByParses),
	MAD_TEST(testOrderByDefaultsToAscending),
	MAD_TEST(testOrderByMatchesTheGroupByByIdentityNotSpelling),
	MAD_TEST(testCommentsAreSkipped),
	MAD_TEST(testKeywordsAreCaseInsensitive),
	MAD_TEST(testNumericLiteralsParse),
	MAD_TEST(testATrailingSemicolonParses),
	MAD_TEST(testORIsRejected),
	MAD_TEST(testINIsRejected),
	MAD_TEST(testLIKEIsRejected),
	MAD_TEST(testBETWEENIsRejected),
	MAD_TEST(testNOTIsRejected),
	MAD_TEST(testASubqueryInTheWhereClauseIsRejected),
	MAD_TEST(testASubqueryInTheFromClauseIsRejected),
	MAD_TEST(testUNIONIsRejected),
	MAD_TEST(testDISTINCTIsRejected),
	MAD_TEST(testAFunctionInTheSelectListIsRejected),
	MAD_TEST(testArithmeticInTheSelectListIsRejected),
	MAD_TEST(testASelectAliasIsRejected),
	MAD_TEST(testABareStarIsRejected),
	MAD_TEST(testAFunctionInTheWhereClauseIsRejected),
	MAD_TEST(testAMultiConditionOnClauseIsRejected),
	MAD_TEST(testANonEquiOnClauseIsRejected),
	MAD_TEST(testARenamedAliasIsRejected),
	MAD_TEST(testACommaJoinIsRejected),
	MAD_TEST(testANaturalJoinIsRejected),
	MAD_TEST(testACrossJoinIsRejected),
	MAD_TEST(testLIMITIsRejected),
	MAD_TEST(testAnUnknownTableIsRejected),
	MAD_TEST(testAnUnknownColumnIsRejected),
	MAD_TEST(testAnAmbiguousSelectColumnIsRejected),
	MAD_TEST(testAnAmbiguousWhereColumnIsRejected),
	MAD_TEST(testAnOrderByOutsideTheGroupByIsRejected),
	MAD_TEST(testAnOrderByPartiallyOutsideTheGroupByIsRejected),
	MAD_TEST(testARepeatedJoinBetweenTheSamePairIsRejected),
	MAD_TEST(testASecondStatementIsRejected),
	MAD_TEST(testSomethingThatIsNotASelectIsRejected),
	MAD_TEST(testAnEmptyStatementIsRejected),
	MAD_TEST(testAMultiLineRejectionCarriesItsLine));
