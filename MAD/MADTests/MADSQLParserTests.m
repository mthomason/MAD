//
//  MADSQLParserTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the pasted-SQL importer's front half (docs/project/MAD_SQL_ENTRY.md §5, §10.3):
//  the tokenizer's per-dialect quoting and line:column positions, and the parser's
//  accept matrix -- exactly the language the model can hold -- and its rejection
//  table, each rejection asserting the error code and the line:column, never just
//  the message.
//
//  The fixture schema is three tables with the fields the golden generator's
//  fixtures use, so what the parser accepts here is what MADQueryFull can emit.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabase.h>
#import <MADMySQL/MADDatabaseMySQL.h>
#import <MADTdsClient/MADDatabaseSQLServer.h>
#import <MADPostgres/MADDatabasePostgres.h>

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

@interface MADSQLParserTests : XCTestCase
@end

@implementation MADSQLParserTests

#pragma mark - Helpers

- (MADSQLStatement *)parseStatement:(NSString *)sql {
	MADSQLParser *parser = ParserForSQL(sql);
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];
	XCTAssertNotNil(statement, @"%@", error);
	XCTAssertNil(error);
	return statement;
}

- (MADSQLStatement *)parseStatement:(NSString *)sql quotes:(NSString *)quotes {
	MADSQLParser *parser = ParserForSQLWithQuotes(sql, quotes);
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];
	XCTAssertNotNil(statement, @"%@", error);
	XCTAssertNil(error);
	return statement;
}

- (void)assertParseOfSQL:(NSString *)sql
					code:(MADSQLCompileErrorCode)code
					line:(NSInteger)line
				  column:(NSInteger)column {
	MADSQLParser *parser = ParserForSQL(sql);
	NSError *error = nil;
	MADSQLStatement *statement = [parser parseStatement:&error];

	XCTAssertNil(statement, @"%@ should not parse", sql);
	XCTAssertNotNil(error, @"%@ should fail with an error", sql);
	if (!error) return;
	XCTAssertEqualObjects(error.domain, MADSQLCompileErrorDomain, @"%@", error);
	XCTAssertEqual(error.code, (NSInteger)code, @"%@", error);
	XCTAssertEqualObjects(error.userInfo[MADSQLCompileErrorLineKey], @(line), @"%@", error);
	XCTAssertEqualObjects(error.userInfo[MADSQLCompileErrorColumnKey], @(column), @"%@", error);
}

#pragma mark - The identifier-quote API

- (void)testIdentifierQuoteCharactersPerDriver {
	XCTAssertEqualObjects([MADDatabase identifierQuoteCharacters], @"\"\"");
	XCTAssertEqualObjects([MADDatabaseMySQL identifierQuoteCharacters], @"``");
	XCTAssertEqualObjects([MADDatabaseSQLServer identifierQuoteCharacters], @"[]");
	XCTAssertEqualObjects([MADDatabasePostgres identifierQuoteCharacters], @"\"\"");
}

#pragma mark - The tokenizer

- (void)testTokenizerTracksLineAndColumn {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"SELECT name\nFROM customers"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertTrue([tokenizer tokenizeWithError:&error], @"%@", error);
	NSArray<MADSQLToken *> *tokens = tokenizer.tokens;
	XCTAssertNotNil(tokens);

	XCTAssertEqual(tokens.count, (NSUInteger)5);	// SELECT, name, FROM, customers, End
	XCTAssertEqual(tokens[0].kind, MADSQLTokenKindIdentifier);
	XCTAssertTrue(tokens[0].isKeyword);
	XCTAssertEqualObjects(tokens[0].text, @"SELECT");
	XCTAssertEqual(tokens[0].line, (NSInteger)1);
	XCTAssertEqual(tokens[0].column, (NSInteger)1);

	XCTAssertEqualObjects(tokens[1].text, @"name");
	XCTAssertFalse(tokens[1].isKeyword);
	XCTAssertEqual(tokens[1].line, (NSInteger)1);
	XCTAssertEqual(tokens[1].column, (NSInteger)8);

	XCTAssertEqualObjects(tokens[2].text, @"FROM");
	XCTAssertEqual(tokens[2].line, (NSInteger)2);
	XCTAssertEqual(tokens[2].column, (NSInteger)1);

	XCTAssertEqualObjects(tokens[3].text, @"customers");
	XCTAssertEqual(tokens[3].line, (NSInteger)2);
	XCTAssertEqual(tokens[3].column, (NSInteger)6);

	XCTAssertEqual(tokens[4].kind, MADSQLTokenKindEnd);
}

- (void)testTokenizerReadsQuotedIdentifiersPerDialect {
	NSDictionary<NSString *, NSArray<NSString *> *> *cases = @{
		@"``": @[ @"`name`", @"name" ],
		@"[]": @[ @"[name]", @"name" ],
		@"\"\"": @[ @"\"name\"", @"name" ],
	};
	for (NSString *quotes in cases) {
		NSArray<NSString *> *expected = cases[quotes];
		MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:expected.firstObject
											   identifierQuoteCharacters:quotes];
		NSError *error = nil;
		XCTAssertTrue([tokenizer tokenizeWithError:&error], @"%@", error);
		XCTAssertEqual(tokenizer.tokens.count, (NSUInteger)2);	// identifier, End
		XCTAssertEqual(tokenizer.tokens.firstObject.kind, MADSQLTokenKindQuotedIdentifier);
		XCTAssertEqualObjects(tokenizer.tokens.firstObject.text, expected.lastObject);
	}
}

- (void)testTokenizerReadsStringLiteralsWithEscapedQuotes {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"'O''Brien'"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertTrue([tokenizer tokenizeWithError:&error], @"%@", error);
	XCTAssertEqual(tokenizer.tokens.count, (NSUInteger)2);
	XCTAssertEqual(tokenizer.tokens.firstObject.kind, MADSQLTokenKindStringLiteral);
	XCTAssertEqualObjects(tokenizer.tokens.firstObject.value, @"O'Brien");
}

- (void)testTokenizerReadsNumbers {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"42 1.5"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertTrue([tokenizer tokenizeWithError:&error], @"%@", error);
	XCTAssertEqual(tokenizer.tokens.count, (NSUInteger)3);
	XCTAssertEqual(tokenizer.tokens[0].kind, MADSQLTokenKindNumber);
	XCTAssertEqualObjects(tokenizer.tokens[0].value, @"42");
	XCTAssertEqual(tokenizer.tokens[1].kind, MADSQLTokenKindNumber);
	XCTAssertEqualObjects(tokenizer.tokens[1].value, @"1.5");
}

- (void)testTokenizerSkipsComments {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"-- a comment\nSELECT /* another */ name"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertTrue([tokenizer tokenizeWithError:&error], @"%@", error);
	NSArray<MADSQLToken *> *tokens = tokenizer.tokens;
	XCTAssertEqual(tokens.count, (NSUInteger)3);	// SELECT, name, End
	XCTAssertEqualObjects(tokens[0].text, @"SELECT");
	XCTAssertEqual(tokens[0].line, (NSInteger)2);
	XCTAssertEqualObjects(tokens[1].text, @"name");
	XCTAssertEqual(tokens[1].line, (NSInteger)2);
}

- (void)testTokenizerReadsEveryOperator {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"= <> > >= < <= ( ) , . *"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertTrue([tokenizer tokenizeWithError:&error], @"%@", error);
	NSArray<MADSQLToken *> *tokens = tokenizer.tokens;
	XCTAssertEqual(tokens.count, (NSUInteger)12);	// eleven operators, End
	NSArray<NSString *> *expected = @[ @"=", @"<>", @">", @">=", @"<", @"<=", @"(", @")", @",", @".", @"*" ];
	for (NSUInteger index = 0; index < expected.count; index++) {
		XCTAssertEqual(tokens[index].kind, MADSQLTokenKindSymbol);
		XCTAssertEqualObjects(tokens[index].text, expected[index]);
	}
}

- (void)testTokenizerReportsUnterminatedStringAtItsQuote {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"SELECT name FROM customers WHERE name = 'abc"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertFalse([tokenizer tokenizeWithError:&error]);
	XCTAssertEqualObjects(error.domain, MADSQLCompileErrorDomain);
	XCTAssertEqual(error.code, (NSInteger)MADSQLCompileErrorSyntax);
	XCTAssertEqualObjects(error.userInfo[MADSQLCompileErrorLineKey], @1);
	XCTAssertEqualObjects(error.userInfo[MADSQLCompileErrorColumnKey], @41);
}

- (void)testTokenizerReportsUnterminatedCommentAtItsStart {
	MADSQLTokenizer *tokenizer = [[MADSQLTokenizer alloc] initWithSQL:@"SELECT name FROM customers /* never closed"
										   identifierQuoteCharacters:@"\"\""];
	NSError *error = nil;
	XCTAssertFalse([tokenizer tokenizeWithError:&error]);
	XCTAssertEqual(error.code, (NSInteger)MADSQLCompileErrorSyntax);
	XCTAssertEqualObjects(error.userInfo[MADSQLCompileErrorLineKey], @1);
	XCTAssertEqualObjects(error.userInfo[MADSQLCompileErrorColumnKey], @28);
}

#pragma mark - The accept matrix

- (void)testSingleTableSelect {
	MADSQLStatement *statement = [self parseStatement:@"SELECT name FROM customers"];

	XCTAssertEqual(statement.selectColumns.count, (NSUInteger)1);
	XCTAssertNil(statement.selectColumns.firstObject.table);
	XCTAssertEqualObjects(statement.selectColumns.firstObject.name, @"name");
	XCTAssertFalse(statement.selectColumns.firstObject.isWildcard);

	XCTAssertEqual(statement.fromItems.count, (NSUInteger)1);
	XCTAssertEqualObjects(statement.fromItems.firstObject.tableName, @"customers");
	XCTAssertNil(statement.fromItems.firstObject.alias);

	XCTAssertEqual(statement.joins.count, (NSUInteger)0);
	XCTAssertEqual(statement.predicates.count, (NSUInteger)0);
	XCTAssertEqual(statement.groupByColumns.count, (NSUInteger)0);
	XCTAssertEqual(statement.orderByTerms.count, (NSUInteger)0);
}

- (void)testQuotedIdentifiersParsePerDialect {
	NSDictionary<NSString *, NSString *> *cases = @{
		@"``": @"SELECT `name` FROM `customers`",
		@"[]": @"SELECT [name] FROM [customers]",
		@"\"\"": @"SELECT \"name\" FROM \"customers\"",
	};
	for (NSString *quotes in cases) {
		MADSQLStatement *statement = [self parseStatement:cases[quotes] quotes:quotes];
		XCTAssertEqualObjects(statement.selectColumns.firstObject.name, @"name");
		XCTAssertEqualObjects(statement.fromItems.firstObject.tableName, @"customers");
	}
}

- (void)testQualifiedAndBareColumnsMix {
	MADSQLStatement *statement = [self parseStatement:@"SELECT customers.name, id FROM customers"];

	XCTAssertEqual(statement.selectColumns.count, (NSUInteger)2);
	XCTAssertEqualObjects(statement.selectColumns[0].table, @"customers");
	XCTAssertEqualObjects(statement.selectColumns[0].name, @"name");
	XCTAssertNil(statement.selectColumns[1].table);
	XCTAssertEqualObjects(statement.selectColumns[1].name, @"id");
}

- (void)testQualifiedWildcardSelect {
	MADSQLStatement *statement = [self parseStatement:@"SELECT customers.* FROM customers"];

	XCTAssertEqual(statement.selectColumns.count, (NSUInteger)1);
	XCTAssertTrue(statement.selectColumns.firstObject.isWildcard);
	XCTAssertEqualObjects(statement.selectColumns.firstObject.table, @"customers");
}

- (void)testEachJoinTypeParses {
	NSDictionary<NSString *, NSNumber *> *cases = @{
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
		MADSQLStatement *statement = [self parseStatement:sql];

		XCTAssertEqual(statement.joins.count, (NSUInteger)1, @"%@", keyword);
		XCTAssertEqual(statement.joins.firstObject.type, (MADLinkType)cases[keyword].integerValue, @"%@", keyword);
		XCTAssertEqualObjects(statement.joins.firstObject.leftTable, @"customers", @"%@", keyword);
		XCTAssertEqualObjects(statement.joins.firstObject.rightTable, @"invoices", @"%@", keyword);
		XCTAssertEqualObjects(statement.joins.firstObject.leftColumn.table, @"customers", @"%@", keyword);
		XCTAssertEqualObjects(statement.joins.firstObject.leftColumn.name, @"id", @"%@", keyword);
		XCTAssertEqualObjects(statement.joins.firstObject.rightColumn.table, @"invoices", @"%@", keyword);
		XCTAssertEqualObjects(statement.joins.firstObject.rightColumn.name, @"customer_id", @"%@", keyword);
	}
}

- (void)testJoinOnBareColumnsWhenUnambiguous {
	// `name` is only on customers and `customer_id` only on invoices, so the bare
	// ON columns resolve.
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT invoices.amount FROM customers INNER JOIN invoices ON name = customer_id"];

	XCTAssertNil(statement.joins.firstObject.leftColumn.table);
	XCTAssertEqualObjects(statement.joins.firstObject.leftColumn.name, @"name");
	XCTAssertNil(statement.joins.firstObject.rightColumn.table);
	XCTAssertEqualObjects(statement.joins.firstObject.rightColumn.name, @"customer_id");
}

- (void)testJoinChainsParse {
	MADSQLStatement *statement = [self parseStatement:
		@"SELECT lines.sku FROM customers INNER JOIN invoices ON customers.id = invoices.customer_id "
		@"INNER JOIN lines ON invoices.id = lines.invoice_id"];

	XCTAssertEqual(statement.joins.count, (NSUInteger)2);
	XCTAssertEqualObjects(statement.joins[1].leftTable, @"invoices");
	XCTAssertEqualObjects(statement.joins[1].rightTable, @"lines");
}

- (void)testDropIndexAliasesParse {
	// The generator's own alias forms: the table's name, and name+index for each
	// further copy of the same table.
	MADSQLStatement *statement = [self parseStatement:
		@"SELECT invoices0.id FROM invoices AS invoices0 "
		@"INNER JOIN invoices AS invoices1 ON invoices0.id = invoices1.customer_id"];

	XCTAssertEqual(statement.fromItems.count, (NSUInteger)2);
	XCTAssertEqualObjects(statement.fromItems.firstObject.tableName, @"invoices");
	XCTAssertEqualObjects(statement.fromItems.firstObject.alias, @"invoices0");
	XCTAssertEqualObjects(statement.fromItems.lastObject.tableName, @"invoices");
	XCTAssertEqualObjects(statement.fromItems.lastObject.alias, @"invoices1");
	XCTAssertEqualObjects(statement.joins.firstObject.rightTable, @"invoices1");
}

- (void)testTheTablesOwnNameIsAValidAlias {
	MADSQLStatement *statement = [self parseStatement:@"SELECT invoices.id FROM invoices AS invoices"];
	XCTAssertEqualObjects(statement.fromItems.firstObject.alias, @"invoices");
}

- (void)testImplicitAliasParses {
	MADSQLStatement *statement = [self parseStatement:@"SELECT invoices0.id FROM invoices invoices0"];
	XCTAssertEqualObjects(statement.fromItems.firstObject.alias, @"invoices0");
}

- (void)testWhereConjunctionParses {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT name FROM customers WHERE name = 'A' AND id > 5"];

	XCTAssertEqual(statement.predicates.count, (NSUInteger)2);

	MADSQLPredicateTerm *first = statement.predicates[0];
	XCTAssertEqual(first.operator, MADPredicateOperatorEqual);
	XCTAssertNil(first.leftColumn.table);
	XCTAssertEqualObjects(first.leftColumn.name, @"name");
	XCTAssertNotNil(first.rightLiteral);
	XCTAssertEqualObjects(first.rightLiteral.text, @"A");
	XCTAssertFalse(first.rightLiteral.isNumeric);

	MADSQLPredicateTerm *second = statement.predicates[1];
	XCTAssertEqual(second.operator, MADPredicateOperatorGreaterThan);
	XCTAssertEqualObjects(second.leftColumn.name, @"id");
	XCTAssertNotNil(second.rightLiteral);
	XCTAssertEqualObjects(second.rightLiteral.text, @"5");
	XCTAssertTrue(second.rightLiteral.isNumeric);
}

- (void)testPredicateWithColumnOnBothSidesParses {
	MADSQLStatement *statement = [self parseStatement:
		@"SELECT invoices.amount FROM customers INNER JOIN invoices ON customers.id = invoices.customer_id "
		@"WHERE customers.id = invoices.id"];

	XCTAssertEqual(statement.predicates.count, (NSUInteger)1);
	XCTAssertEqualObjects(statement.predicates.firstObject.leftColumn.table, @"customers");
	XCTAssertEqualObjects(statement.predicates.firstObject.rightColumn.table, @"invoices");
	XCTAssertNil(statement.predicates.firstObject.leftLiteral);
	XCTAssertNil(statement.predicates.firstObject.rightLiteral);
}

- (void)testPredicateWithLiteralOnTheLeftParses {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT name FROM customers WHERE 5 < id"];

	XCTAssertEqual(statement.predicates.count, (NSUInteger)1);
	XCTAssertEqual(statement.predicates.firstObject.operator, MADPredicateOperatorLessThan);
	XCTAssertNotNil(statement.predicates.firstObject.leftLiteral);
	XCTAssertEqualObjects(statement.predicates.firstObject.leftLiteral.text, @"5");
	XCTAssertEqualObjects(statement.predicates.firstObject.rightColumn.name, @"id");
}

- (void)testParensAroundAConjunctionParse {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT name FROM customers WHERE (name = 'A') AND (id >= 5)"];

	XCTAssertEqual(statement.predicates.count, (NSUInteger)2);
	XCTAssertEqual(statement.predicates[1].operator, MADPredicateOperatorGreaterThanOrEqualTo);
}

- (void)testStringLiteralsKeepTheirEscapedQuotes {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT name FROM customers WHERE name = 'O''Brien'"];

	XCTAssertEqualObjects(statement.predicates.firstObject.rightLiteral.text, @"O'Brien");
}

- (void)testGroupByParses {
	MADSQLStatement *statement = [self parseStatement:@"SELECT name, id FROM customers GROUP BY name, id"];

	XCTAssertEqual(statement.groupByColumns.count, (NSUInteger)2);
	XCTAssertEqualObjects(statement.groupByColumns[0].name, @"name");
	XCTAssertEqualObjects(statement.groupByColumns[1].name, @"id");
}

- (void)testOrderByWithinTheGroupByParses {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT name FROM customers GROUP BY name ORDER BY name DESC"];

	XCTAssertEqual(statement.orderByTerms.count, (NSUInteger)1);
	XCTAssertEqualObjects(statement.orderByTerms.firstObject.column.name, @"name");
	XCTAssertFalse(statement.orderByTerms.firstObject.isAscending);
}

- (void)testOrderByDefaultsToAscending {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT name FROM customers GROUP BY name ORDER BY name"];

	XCTAssertTrue(statement.orderByTerms.firstObject.isAscending);
}

- (void)testOrderByMatchesTheGroupByByIdentityNotSpelling {
	// The bare ORDER BY column resolves to the same field as the qualified GROUP BY
	// column, so it is inside the group set.
	MADSQLStatement *statement = [self parseStatement:
		@"SELECT customers.name FROM customers GROUP BY customers.name ORDER BY name"];
	XCTAssertEqual(statement.orderByTerms.count, (NSUInteger)1);
}

- (void)testCommentsAreSkipped {
	XCTAssertNotNil([self parseStatement:@"-- the customers\nSELECT name FROM customers"]);
	XCTAssertNotNil([self parseStatement:@"/* the customers */ SELECT name FROM customers"]);
	XCTAssertNotNil([self parseStatement:@"SELECT name /* the name */ FROM customers"]);
}

- (void)testKeywordsAreCaseInsensitive {
	MADSQLStatement *statement =
		[self parseStatement:@"select name from customers where name = 'a' group by name order by name"];
	XCTAssertEqual(statement.predicates.count, (NSUInteger)1);
	XCTAssertEqual(statement.groupByColumns.count, (NSUInteger)1);
}

- (void)testNumericLiteralsParse {
	MADSQLStatement *statement =
		[self parseStatement:@"SELECT invoices.amount FROM invoices WHERE id = 42 AND amount >= 1.5"];
	XCTAssertEqualObjects(statement.predicates[0].rightLiteral.text, @"42");
	XCTAssertEqualObjects(statement.predicates[1].rightLiteral.text, @"1.5");
}

- (void)testATrailingSemicolonParses {
	MADSQLStatement *statement = [self parseStatement:@"SELECT name FROM customers;"];
	XCTAssertEqual(statement.selectColumns.count, (NSUInteger)1);
}

#pragma mark - The rejection table

- (void)testORIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE id = 1 OR id = 2"
					  code:MADSQLCompileErrorUnsupportedOR line:1 column:41];
}

- (void)testINIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE id IN (1, 2)"
					  code:MADSQLCompileErrorUnsupportedIN line:1 column:37];
}

- (void)testLIKEIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE name LIKE 'A%'"
					  code:MADSQLCompileErrorUnsupportedLIKE line:1 column:39];
}

- (void)testBETWEENIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE id BETWEEN 1 AND 2"
					  code:MADSQLCompileErrorUnsupportedBETWEEN line:1 column:37];
}

- (void)testNOTIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE NOT id = 1"
					  code:MADSQLCompileErrorUnsupportedNOT line:1 column:34];
}

- (void)testASubqueryInTheWhereClauseIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE id = (SELECT MAX(id) FROM invoices)"
					  code:MADSQLCompileErrorUnsupportedSubquery line:1 column:40];
}

- (void)testASubqueryInTheFromClauseIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM (SELECT id FROM invoices)"
					  code:MADSQLCompileErrorUnsupportedSubquery line:1 column:19];
}

- (void)testUNIONIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers UNION SELECT id FROM invoices"
					  code:MADSQLCompileErrorUnsupportedUNION line:1 column:28];
}

- (void)testDISTINCTIsRejected {
	[self assertParseOfSQL:@"SELECT DISTINCT name FROM customers"
					  code:MADSQLCompileErrorUnsupportedDISTINCT line:1 column:8];
}

- (void)testAFunctionInTheSelectListIsRejected {
	[self assertParseOfSQL:@"SELECT MAX(id) FROM customers"
					  code:MADSQLCompileErrorUnsupportedExpression line:1 column:8];
}

- (void)testArithmeticInTheSelectListIsRejected {
	[self assertParseOfSQL:@"SELECT id + 1 FROM customers"
					  code:MADSQLCompileErrorUnsupportedExpression line:1 column:11];
}

- (void)testASelectAliasIsRejected {
	[self assertParseOfSQL:@"SELECT name AS n FROM customers"
					  code:MADSQLCompileErrorUnsupportedSelectAlias line:1 column:13];
}

- (void)testABareStarIsRejected {
	[self assertParseOfSQL:@"SELECT * FROM customers"
					  code:MADSQLCompileErrorUnsupportedExpression line:1 column:8];
}

- (void)testAFunctionInTheWhereClauseIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers WHERE LOWER(name) = 'a'"
					  code:MADSQLCompileErrorUnsupportedExpression line:1 column:34];
}

- (void)testAMultiConditionOnClauseIsRejected {
	[self assertParseOfSQL:@"SELECT invoices.id FROM customers INNER JOIN invoices "
						   @"ON customers.id = invoices.customer_id AND invoices.id > 5"
					  code:MADSQLCompileErrorUnsupportedOnCondition line:1 column:94];
}

- (void)testANonEquiOnClauseIsRejected {
	[self assertParseOfSQL:@"SELECT invoices.id FROM customers INNER JOIN invoices "
						   @"ON customers.id > invoices.customer_id"
					  code:MADSQLCompileErrorUnsupportedOnCondition line:1 column:71];
}

- (void)testARenamedAliasIsRejected {
	[self assertParseOfSQL:@"SELECT c.id FROM customers AS c"
					  code:MADSQLCompileErrorUnsupportedAlias line:1 column:31];
}

- (void)testACommaJoinIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers, invoices"
					  code:MADSQLCompileErrorUnsupportedCommaJoin line:1 column:27];
}

- (void)testANaturalJoinIsRejected {
	[self assertParseOfSQL:@"SELECT invoices.id FROM customers NATURAL JOIN invoices "
						   @"ON customers.id = invoices.customer_id"
					  code:MADSQLCompileErrorUnsupportedNaturalCrossJoin line:1 column:35];
}

- (void)testACrossJoinIsRejected {
	[self assertParseOfSQL:@"SELECT invoices.id FROM customers CROSS JOIN invoices "
						   @"ON customers.id = invoices.customer_id"
					  code:MADSQLCompileErrorUnsupportedNaturalCrossJoin line:1 column:35];
}

- (void)testLIMITIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers LIMIT 10"
					  code:MADSQLCompileErrorUnsupportedLIMIT line:1 column:28];
}

- (void)testAnUnknownTableIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM nope"
					  code:MADSQLCompileErrorUnknownTable line:1 column:18];
}

- (void)testAnUnknownColumnIsRejected {
	[self assertParseOfSQL:@"SELECT nope FROM customers"
					  code:MADSQLCompileErrorUnknownColumn line:1 column:8];
}

- (void)testAnAmbiguousSelectColumnIsRejected {
	[self assertParseOfSQL:@"SELECT id FROM customers INNER JOIN invoices "
						   @"ON customers.id = invoices.customer_id"
					  code:MADSQLCompileErrorAmbiguousColumn line:1 column:8];
}

- (void)testAnAmbiguousWhereColumnIsRejected {
	[self assertParseOfSQL:@"SELECT customers.id FROM customers INNER JOIN invoices "
						   @"ON customers.id = invoices.customer_id WHERE id = 5"
					  code:MADSQLCompileErrorAmbiguousColumn line:1 column:101];
}

- (void)testAnOrderByOutsideTheGroupByIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers ORDER BY name"
					  code:MADSQLCompileErrorOrderByOutsideGroupBy line:1 column:37];
}

- (void)testAnOrderByPartiallyOutsideTheGroupByIsRejected {
	[self assertParseOfSQL:@"SELECT name, id FROM customers GROUP BY name ORDER BY id"
					  code:MADSQLCompileErrorOrderByOutsideGroupBy line:1 column:55];
}

- (void)testARepeatedJoinBetweenTheSamePairIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers INNER JOIN invoices "
						   @"ON customers.id = invoices.customer_id INNER JOIN invoices "
						   @"ON invoices.customer_id = customers.id"
					  code:MADSQLCompileErrorDuplicateJoin line:1 column:98];
}

- (void)testASecondStatementIsRejected {
	[self assertParseOfSQL:@"SELECT name FROM customers; SELECT id FROM invoices"
					  code:MADSQLCompileErrorSyntax line:1 column:29];
}

- (void)testSomethingThatIsNotASelectIsRejected {
	[self assertParseOfSQL:@"SELEC name FROM customers"
					  code:MADSQLCompileErrorSyntax line:1 column:1];
}

- (void)testAnEmptyStatementIsRejected {
	[self assertParseOfSQL:@""
					  code:MADSQLCompileErrorSyntax line:1 column:1];
}

- (void)testAMultiLineRejectionCarriesItsLine {
	[self assertParseOfSQL:@"SELECT name\nFROM customers\nWHERE name = 'A' OR id = 2"
					  code:MADSQLCompileErrorUnsupportedOR line:3 column:18];
}

@end
