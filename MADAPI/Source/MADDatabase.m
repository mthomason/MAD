//
//  MNSDatabase.m
//  Reports
//
//  Created by Michael Thomason on 11/9/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabase.h"
#import <MADFoundation/madlog.h>

#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADCredential.h>
#import <MADFoundation/MADStringUtilities.h>

#import <MADAPI/MADDatabaseResultsProtocol.h>
#import <MADAPI/MADNotificationDidReadRows.h>
#import <MADAPI/MADDatabaseConnection.h>

#import <Foundation/NSError.h>
#import <Foundation/NSException.h>
#import <Foundation/NSSet.h>

NSString * const MADSqlTextFromPart = @"\nFROM\n";

@implementation MADDatabase

+ (NSString *)imageIconName { return @""; }

+ (NSString *)driverName { return @""; }

+ (instancetype)newDatabaseWithConnection:(MADDatabaseConnection *)connection {
	id database = [[self alloc] init];
	return database;
}

#pragma mark - Initialization

- (instancetype) init {
	if (self = [super init]) {
		_errors = [[NSMutableArray alloc] init];
	}
	return self;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding { return YES; }

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.databaseConnection forKey:@"databaseConnection"];
	[coder encodeObject:self.errors forKey:@"errors"];
	[coder encodeBool:self.isLicensedUser forKey:@"isLicensedUser"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
	if (self = [super init]) {
		_databaseConnection = [decoder decodeObjectOfClass:[MADDatabaseConnection class]
												  forKey:@"databaseConnection"];
		NSSet *errorClasses = [NSSet setWithObjects:[NSArray class], [NSError class], nil];
		_errors = [[decoder decodeObjectOfClasses:errorClasses forKey:@"errors"] mutableCopy];
		_isLicensedUser = [decoder decodeBoolForKey:@"isLicensedUser"];
	}
	return self;
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	MADDatabase *copy = [[[self class] allocWithZone:zone] init];
	if (copy) {
		copy.databaseConnection = [self.databaseConnection copy];
		copy.errors = [self.errors mutableCopy];
		copy->_isLicensedUser = self.isLicensedUser;
	}
	return copy;
}

- (MADCredential *)credentalsWithConnection:(MADDatabaseConnection *)connection {
	MADLogDebug("%s", __PRETTY_FUNCTION__);
	NSString *key = [connection connectionString];
	MADLogDebug("%s Key: %@", __PRETTY_FUNCTION__, key);
	id <MADDatabaseResultsProtocol> delegate = _delegate;
	BOOL responds = [delegate respondsToSelector:@selector(getCredentialsForKey:)];
	MADLogDebug("%s Responds to `getCredentialsForKey:`: %@", __PRETTY_FUNCTION__, responds ? @"YES" : @"NO");
	MADCredential *results = nil;
	if (responds) {
		MADCredential *c = [delegate getCredentialsForKey:key];
		if (c) {
			results = [c copy];
		}
		
	}
	if (!results) {
		MADLogError("%s: Failed to get credentals.", __PRETTY_FUNCTION__);
	}
	return results;
}

- (BOOL)executeQuery:(MADQuery *)query withDataTable:(id <MADDataTableWriting>)dataTable
			andError:(NSError * __autoreleasing *)error {
	NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
	NSString *reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (BOOL)executeQuery:(MADQuery *)query withError:(NSError * __autoreleasing *)error {
	NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
	NSString *reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (id)connectWithConnection:(MADDatabaseConnection *)connection
				 credentals:(MADCredential *)credentals
			connectionError:(NSError * __autoreleasing *)error {
	return nil;
}

- (void *)databaseHandle {
	return NULL;
}

- (MADSafeQueryField *)fieldAliasForField:(NSString *)fieldName
							 andTableName:(NSString *)tableName {
	return [fieldName stringByAppendingString:tableName];
}

- (void)getTables: (void (^)(BOOL success, NSError *error, NSArray <MADDatabaseTable *> *tables))completion {
	NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
	NSString *reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (NSString *)tableAliasForTable:(NSString *)table { return [self newSafeIdentifier: table]; }
- (NSString *)tableAliasConnector { return @" AS "; }
- (NSString *)identifier { return @"NONE"; }
+ (NSString *)identifier { return @"NONE"; }

- (void)readRow:(NSUInteger)row { [[MADNotificationDidReadRows sharedObject] database:self readRow:row]; }

- (void)closeConnection:(id)process {}

- (BOOL)executeSQL:(NSString *)sql fieldKeys:(NSArray *)fieldKeys onConnection:(id)dbconn
   intoResultTable:(id <MADDataTableWriting>)dataTable withError:(NSError * __autoreleasing *)error {
	NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
	NSString *reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (NSArray <MADDatabaseTable *> *)getTablesFromConnection:(id)dbconn
												   error:(NSError *__autoreleasing *)error {
	NSString *format = @"Not implemented: %@.  Subclass MADDatabase; don't use it directly.";
	NSString *reason = [[NSString alloc] initWithFormat:format, NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (void)getTablesFromConnection:(id)process
					 completion:(void (^)(BOOL, NSError *, NSArray *))completion {
	NSString *reason = [[NSString alloc] initWithFormat:@"Not implemented: %@.  Subclass MADDatabase; don't use it directly.", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (void)enumerateTablesFromConnection:(id)dbconn
						   usingBlock:(void (^)(MADDatabaseTable *obj, NSUInteger index, BOOL *stop))block
						   completion:(void (^)(BOOL success, NSError *error, NSArray *results))completion {
	NSString *reason = [[NSString alloc] initWithFormat:@"Not implemented: %@.  Subclass MADDatabase; don't use it directly.", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

#pragma mark -
#pragma mark MADDatabaseSQLProtocol

+ (MADSafeQueryField *)newSafeQueryField:(NSString *)fieldName andTable:(NSString *)tableName {
	return [[MADStringUtilities stringByAppendingPeriod:tableName] stringByAppendingString:fieldName];
}

- (NSString *)queryKey:(NSString *)fieldName table:(NSString *)tableName {
	return [MADDatabase newSafeQueryField:fieldName andTable:tableName];
}

+ (MADSafeQueryField *)newSafeIdentifier:(NSString *)s {
	return [[MADSafeQueryField alloc] initWithString: s];
}

- (MADSafeQueryField *)newSafeIdentifier:(NSString *)s {
	id result = [s copy];
	return result;
}

// The ANSI form: single quotes, with an interior quote doubled.  Every dialect this
// framework ships accepts it, so it is the default rather than a fallback.
//
// The double quote is the point.  SQL reads a double-quoted token as a *name*, never as a
// value, so a text filter written as "London" asks for a column called London.  SQLite used
// to forgive that -- SQLITE_DQS defaults to on -- until Compressor/sqlite3.xcconfig pinned
// SQLITE_DQS=0, and MySQL was reading them as strings only by its own default.  See BUGS.md.
//
// A value containing a backslash is not handled here and cannot be: MySQL treats one
// inside a literal as an escape character, so only the connection's own
// mysql_real_escape_string knows what the session makes of it.  See MADDatabaseMySQL.
- (NSString *)newSafeLiteral:(NSString *)value {
	if (value == nil) return @"NULL";
	NSString *escaped = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
	return [[NSString alloc] initWithFormat:@"'%@'", escaped];
}

- (NSString *)selectPart { return @"SELECT\n"; }
- (NSString *)selectPartWithLimitedResults:(NSUInteger)limit { return @"SELECT\n"; }
- (NSString *)sqlLimitClause { return [self sqlLimitClause:  NSUIntegerMax]; }
- (NSString *)sqlRangeClauseWithLimit:(NSUInteger)limit offset:(NSUInteger)offset {
	return [NSString stringWithFormat:@"LIMIT %ld OFFSET %ld", limit, offset];
}
- (NSString *)sqlDefaultRequiredOrderByClause { return @""; }
- (NSString *)sqlLimitClause:(NSUInteger)limit {
	NSString *sqlLimitClause = (limit > 0 && limit != NSUIntegerMax) ?
		[[NSString alloc] initWithFormat: @"\nLIMIT %ld", (unsigned long)limit] :
		@"";
	return sqlLimitClause;
}

- (NSString *)fieldAliasForField:(NSString *)field
			   withSafeTableName:(NSString *)safeTableName {
	NSString *tableAlias = [MADStringUtilities stringByAppendingPeriod:safeTableName];
	MADSafeQueryField *fieldName = [self newSafeIdentifier: field];
	NSString *alias = [tableAlias stringByAppendingString:fieldName];
	return alias;
}

- (NSArray <MADDatabaseField *> *)fieldsForTable:(NSString *)tableName
									  connection:(id)dbconn
										   error:(NSError *__autoreleasing *)error {
	NSString *reason = [[NSString alloc] initWithFormat:@"Not implemented: %@.  Subclass MADDatabase; don't use it directly.", NSStringFromSelector(_cmd)];
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: reason
								 userInfo: nil];
}

- (NSString *)sqlSampleDataForField:(NSString *)fieldName andTable:(NSString *)tableName {
	MADSafeQueryField *safeField = [self queryKey: fieldName table: tableName];
	NSString *safeFieldAlias = [self fieldAliasForField: fieldName
										   andTableName: tableName];
	MADSafeQueryField *safeTable = [self newSafeIdentifier:tableName];

	NSString *selectPart = [self selectPart];
	NSString *tableAliasConnector = [self tableAliasConnector];
	return [NSString stringWithFormat:@"%@ DISTINCT "
			@"%@ %@ %@ "
			@"%@ %@ "
			@"LIMIT 511;", selectPart, safeField, tableAliasConnector, safeFieldAlias, MADSqlTextFromPart, safeTable];
}

- (NSString *)sqlAggregateFunctionLength { return @"LENGTH"; }

- (NSString *)sqlAggregateFunctionMax { return @"MAX"; }

@end
