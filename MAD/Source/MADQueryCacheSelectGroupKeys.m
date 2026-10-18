//
//  MADQueryCacheSelectGroupKeys.m
//  MAD
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADQueryCacheSelectGroupKeys.h"
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSValue.h>
#import <MADFoundation/MADDataColumn.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADQuerySelectParameters.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>

@interface MADQueryCacheSelectGroupKeys ()

@property (nonatomic, copy) NSString *tableName;
@property (nonatomic, copy) NSString *columnName;
@property (nonatomic, copy) NSString *sqlSpeedSorting;

// The predicates exactly as they were handed in, quoted when the SQL is built rather
// than now: which dialect quotes them is not known until a database arrives, and the
// only entry points that supply one are the ones that are about to run the query.
@property (nonatomic, copy) NSArray <NSDictionary *> *predicates;

@property (nonatomic, assign) BOOL accending;

@end

@implementation MADQueryCacheSelectGroupKeys

@synthesize database = _database;

- (instancetype)initWithObject:(id)object {

	if (self = [super initWithObject:object]) {

		NSAssert([object isKindOfClass:[NSDictionary class]], @"%@ expects NSDictionary.", NSStringFromClass([self class]));
		NSDictionary *obj = object;

		NSNumber *keySelectTableName = @(MADQuerySelectTableName);
		NSString *selectTableName = [obj objectForKey:keySelectTableName];
		NSString *tableName = [[NSString alloc] initWithString:selectTableName];
		self.tableName = tableName;

		NSNumber *keySelectPredicates = @(MADQuerySelectPredicates);
		self.predicates = [[obj objectForKey: keySelectPredicates] copy];

		NSNumber *keySelectFieldNames = @(MADQuerySelectFieldKeys);
		NSArray <NSString *> *fieldNames = [obj objectForKey:keySelectFieldNames];
		NSString *columnName = [fieldNames.firstObject copy];
		self.columnName = columnName;

		NSNumber *keySelectSortAccending = @(MADQuerySelectSortAccending);
		NSNumber *sortValue = [[obj objectForKey: keySelectSortAccending] copy];
		self.accending = sortValue.boolValue;

		NSNumber *keyColumns = @(MADQuerySelectColumns);
		NSDictionary *columns = [obj objectForKey: keyColumns];
		MADDataColumn *dataColumn = [columns objectForKey: columnName];

		NSAssert(dataColumn != nil, @"Need to know column types at %s", __PRETTY_FUNCTION__);
		self.sqlSpeedSorting = [MADDatabaseSqlite3 sortDescriptionForColumnType:dataColumn.type
																	  ascending:self.accending];

	}
	return self;
}

#pragma mark - Quoting

// The dialect to quote for.  This query only ever runs against a document's Sqlite3
// cache -- the sort description above is Sqlite3's -- so when the plain -getSql: entry
// point is used and nothing has injected a database, the cache's own dialect is the
// answer.
- (MADDatabase *)quotingDatabase {
	return self.database ?: [[MADDatabaseSqlite3 alloc] init];
}

// A predicate value is whatever the model held.  NSNull is not an accident: a NULL read
// back from a source database is stored in the cache as NSNull on purpose, so that
// unwrapping a column value into an NSObject never has to face a nil.  It is a SQL
// keyword here, though, and is never quoted -- @"%@", NSNull writes "<null>", which is
// a literal string and matches nothing.
- (NSString *)literalForValue:(id)value database:(MADDatabase *)database {
	if (value == nil || [value isKindOfClass:[NSNull class]]) return @"NULL";
	NSString *text = [value isKindOfClass:[NSString class]] ? value : [value description];
	return [database newSafeLiteral: text];
}

// The value used to be written between double quotes -- @"%@ = \"%@\"" -- and a SQL reader
// takes a double-quoted token for a *name*, not for text: the filter asked for a column
// called London, which does not exist.  Sqlite3 forgave that only while SQLITE_DQS was on,
// and Compressor/sqlite3.xcconfig turned it off.  The column and the value both go through
// the dialect now.  See BUGS.md.
- (NSString *)whereClauseQuotedByDatabase:(MADDatabase *)database {
	NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
	NSUInteger counter = 0;
	for (NSDictionary *predicate in self.predicates) {
		// With no predicates the clause stays empty; it used to say " WHERE " on its own,
		// which made the whole statement a syntax error.
		[sql appendString: (counter == 0) ? @" WHERE " : @" AND "];
		NSString *column = [database newSafeIdentifier: predicate[MADQueryKeyPredicateColumn]];
		NSString *value = [self literalForValue: predicate[MADQueryKeyPredicateValue] database: database];
		[sql appendFormat: @"%@ = %@", column, value];
		counter++;
	}
	return sql;
}

- (NSString *)getSql:(NSError * __autoreleasing *)error {
	MADDatabase *database = [self quotingDatabase];
	NSString *column = [database newSafeIdentifier: self.columnName];
	NSString *table = [database newSafeIdentifier: self.tableName];
	NSString *where = [self whereClauseQuotedByDatabase: database];
	return [[NSString alloc] initWithFormat:@"SELECT DISTINCT %@ FROM %@%@ ORDER BY %@ %@",
						column, table, where, column, self.sqlSpeedSorting];
}

- (MADQueryType)type {
	return MADQueryTypeCacheSelectGroupKeys;
}

@end
