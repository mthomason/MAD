//
//  MADDatabaseSQLProtocol.h
//  MADAPI
//
//  Created by Michael on 9/3/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADDatabaseSQLProtocol_h
#define MADDatabaseSQLProtocol_h

#import <Foundation/NSObject.h>

@protocol MADDatabaseSQLProtocol <NSObject>

	+ (NSString *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName;
	- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName;
	- (NSString *)newSafeIdentifier:(NSString *)fieldOrTableName;
	- (NSString *)tableAliasForTable:(NSString *)tableName;

	// The two characters that quote an identifier in this dialect -- open then
	// close: "``" for MySQL, "[]" for T-SQL, "\"\"" by default.  The SQL
	// importer's lexer reads identifiers through it before any connection
	// exists (MAD_SQL_ENTRY.md §4).
	+ (NSString *)identifierQuoteCharacters;

	// Turns a value into a SQL literal, quoted and escaped for this dialect.  Its
	// counterpart for names is -newSafeIdentifier:; a name and a value are quoted the
	// same way but escaped differently, and only the dialect knows how.
	- (NSString *)newSafeLiteral:(NSString *)value;

	- (NSString *)selectPart;
	- (NSString *)selectPartWithLimitedResults:(NSUInteger)limit;
	- (NSString *)sqlLimitClause;
	- (NSString *)sqlLimitClause:(NSUInteger)limit;
	- (NSString *)sqlRangeClauseWithLimit:(NSUInteger)limit offset:(NSUInteger)offset;
	- (NSString *)sqlDefaultRequiredOrderByClause;
	- (NSString *)fieldAliasForField:(NSString *)field withSafeTableName:(NSString *)safeTableName;
	- (NSString *)fieldAliasForField:(NSString *)fieldName andTableName:(NSString *)tableName;
	- (NSString *)tableAliasConnector;

	- (NSString *)sqlAggregateFunctionLength;
	- (NSString *)sqlAggregateFunctionMax;

	- (NSString *)sqlSampleDataForField:(NSString *)fieldName
							   andTable:(NSString *)tableName;

@end

#endif /* MADDatabaseSQLProtocol_h */
