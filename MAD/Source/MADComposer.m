//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADComposer.m
//  MAD
//
//  See MADComposer.h.  The two-input composition join, moved out of the test suite
//  into the engine: SQL assembly, physical-name resolution and result construction
//  all live here, so a caller names logical inputs and gets a normal MADDataResult.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADComposer.h"

#import <MAD/MADDocumentDataProtocol.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataType.h>

#import <MADSqlite3/MADDataTableFast.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>
#import <MADSqlite3/MADDatabaseConnectionSqlite3.h>
#import <sqlite3.h>

#import <Foundation/NSFileManager.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSUUID.h>

static NSString * const MADComposerErrorDomain = @"com.everydayapps.composer";

static NSString * const MADComposerJoinKeyword(MADLinkType type) {
	switch (type) {
		case MADLinkTypeInnerJoin:
		case MADLinkTypeEquiJoin: return @"INNER JOIN";
		case MADLinkTypeLeftOuterJoin: return @"LEFT OUTER JOIN";
		case MADLinkTypeRightOuterJoin: return @"RIGHT OUTER JOIN";
		case MADLinkTypeFullOuterJoin: return @"FULL OUTER JOIN";
		case MADLinkTypeCrossJoin: return @"CROSS JOIN";
		case MADLinkTypeNaturalJoin: return @"NATURAL JOIN";
		case MADLinkTypeUnknown: default: return @"LEFT OUTER JOIN";
	}
}

@implementation MADComposerField

+ (instancetype)fieldWithSourceKey:(NSString *)sourceKey outputKey:(NSString *)outputKey {
	MADComposerField *field = [[self alloc] init];
	field.sourceKey = sourceKey;
	field.outputKey = outputKey;
	return field;
}

@end

@implementation MADComposerProjection

+ (instancetype)projectionWithInput:(MADComposerInput *)input
						  sourceKey:(NSString *)sourceKey
						  outputKey:(NSString *)outputKey {
	MADComposerProjection *projection = [[self alloc] init];
	projection.input = input;
	projection.sourceKey = sourceKey;
	projection.outputKey = outputKey;
	return projection;
}

@end

@implementation MADComposerInput
@end

@implementation MADComposer

+ (nullable MADDataResult *)composeLeft:(MADComposerInput *)left
                                  right:(MADComposerInput *)right
                                joinType:(MADLinkType)joinType
                             orderByKeys:(nullable NSArray<NSString *> *)orderByKeys
                          rootIdentifier:(NSString *)rootIdentifier
                          cacheDirectory:(NSURL *)cacheDirectory
                                    error:(NSError * _Nullable __autoreleasing *)error {

	// The two-input convenience keeps its left-then-right convention by folding
	// each input's fields into one ordered projection.
	NSMutableArray<MADComposerProjection *> *projections =
		[NSMutableArray arrayWithCapacity: left.fields.count + right.fields.count];
	for (MADComposerField *field in left.fields) {
		[projections addObject: [MADComposerProjection projectionWithInput: left
																sourceKey: field.sourceKey
																outputKey: field.outputKey]];
	}
	for (MADComposerField *field in right.fields) {
		[projections addObject: [MADComposerProjection projectionWithInput: right
																sourceKey: field.sourceKey
																outputKey: field.outputKey]];
	}

	MADDataTableFast *table = [[MADDataTableFast alloc] initWithId: rootIdentifier.hash cacheDirectory: cacheDirectory];
	table.cacheFileIdentifier = rootIdentifier;

	if (![self composeLeft: left right: right joinType: joinType projections: projections
			   orderByKeys: orderByKeys whereClause: nil cacheDirectory: cacheDirectory intoTable: table error: error]) {
		return nil;
	}

	NSURL *columnMap = [cacheDirectory URLByAppendingPathComponent: [rootIdentifier stringByAppendingPathExtension: @"mdcache"]];
	[table cacheWithUrl: columnMap error: NULL];
	// A table built with a cache directory always resolves its row file; the
	// fallback keeps the result's non-null contract honest without masking a real
	// miss.
	NSURL *rowDatabaseURL = table.rowDatabaseURL ?: [cacheDirectory URLByAppendingPathComponent:
		[rootIdentifier stringByAppendingPathExtension: @"maddb"]];
	return [[MADDataResult alloc] initWithIdentifier: rootIdentifier
											dataTable: table
									   rowDatabaseURL: rowDatabaseURL
										 columnMapURL: columnMap];
}

+ (BOOL)composeLeft:(MADComposerInput *)left
              right:(MADComposerInput *)right
            joinType:(MADLinkType)joinType
        projections:(NSArray<MADComposerProjection *> *)projections
         orderByKeys:(nullable NSArray<NSString *> *)orderByKeys
          whereClause:(nullable NSString *)whereClause
      cacheDirectory:(NSURL *)cacheDirectory
          intoTable:(MADDataTableFast *)table
              error:(NSError * _Nullable __autoreleasing *)error {

	if (left.result == nil || right.result == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: MADComposerErrorDomain
										  code: 1
									  userInfo: @{ NSLocalizedDescriptionKey:
							NSLocalizedString(@"A composition input has no published result.", @"Missing composition input result.") }];
		}
		return NO;
	}

	// Resolve every logical key before opening a connection, so a missing field or
	// join key fails before any attach and leaves the inputs untouched.
	NSString *leftKey = [MADComposer physicalColumnForKey: left.joinKey inInput: left error: error];
	NSString *rightKey = [MADComposer physicalColumnForKey: right.joinKey inInput: right error: error];
	if (leftKey == nil || rightKey == nil) return NO;

	NSMutableArray<NSString *> *fieldKeys = [NSMutableArray arrayWithCapacity: projections.count];
	NSMutableArray<NSString *> *selectTerms = [NSMutableArray arrayWithCapacity: projections.count];
	for (MADComposerProjection *projection in projections) {
		MADComposerInput *input = projection.input;
		NSString *sqlAlias = input == left ? @"src0" : @"src1";
		NSString *physical = [MADComposer physicalColumnForKey: projection.sourceKey inInput: input error: error];
		if (physical == nil) return NO;
		[selectTerms addObject: [NSString stringWithFormat: @"%@.%@", sqlAlias, physical]];
		[fieldKeys addObject: projection.outputKey];
	}

	NSString *joinSQL = MADComposerJoinKeyword(joinType);
	NSMutableString *sql = [NSMutableString stringWithFormat: @"SELECT %@ FROM att0.%@ AS src0 %@ att1.%@ AS src1 ON src0.%@ = src1.%@",
							[selectTerms componentsJoinedByString: @", "],
							left.result.dataTable.tableName,
							joinSQL,
							right.result.dataTable.tableName,
							leftKey, rightKey];

	// A root predicate filters the joined rows, after the join's ON; it must not alter
	// the join itself.
	if (whereClause.length > 0) {
		[sql appendString: whereClause];
	}

	// ORDER BY over full logical keys; a text key orders with the LSASC collation the
	// MAD connection registers, which a raw sqlite3 handle would reject.
	if (orderByKeys.count > 0) {
		NSMutableArray<NSString *> *orderTerms = [NSMutableArray arrayWithCapacity: orderByKeys.count];
		for (NSString *key in orderByKeys) {
			MADComposerInput *owner = [MADComposer inputContainingKey: key inLeft: left right: right];
			if (owner == nil) {
				if (error != NULL) {
					*error = [NSError errorWithDomain: MADComposerErrorDomain code: 2 userInfo: @{
						NSLocalizedDescriptionKey: [NSString stringWithFormat:
							NSLocalizedString(@"The order-by field %@ is not present in either input.", @"Missing composition order-by field."), key] }];
				}
				return NO;
			}
			NSString *physical = [MADComposer physicalColumnForKey: key inInput: owner error: error];
			if (physical == nil) return NO;
			NSString *sqlAlias = owner == left ? @"src0" : @"src1";
			MADDataType type = [MADComposer dataTypeForKey: key inInput: owner];
			NSString *collation = [MADDatabaseSqlite3 sortDescriptionForColumnType: type ascending: YES];
			[orderTerms addObject: [NSString stringWithFormat: @"%@.%@ %@", sqlAlias, physical, collation]];
		}
		[sql appendFormat: @" ORDER BY %@", [orderTerms componentsJoinedByString: @", "]];
	}

	// Open the composing connection over one scratch file, with SQLITE_OPEN_URI so
	// the read-only attach URI is honoured (P5).  openDatabaseWithFlags: also
	// registers LSASC.  The scratch name is fresh each call, so two composes never
	// collide on it.
	NSString *scratchIdentifier = NSUUID.UUID.UUIDString;
	NSURL *scratchURL = [cacheDirectory URLByAppendingPathComponent: [scratchIdentifier stringByAppendingString: @"-composer.maddb"]];
	MADDatabaseConnectionSqlite3 *connection = [[MADDatabaseConnectionSqlite3 alloc] initWithUrl: scratchURL];
	MADDatabaseSqlite3 *composer = [[MADDatabaseSqlite3 alloc] init];
	composer.databaseConnection = connection;
	[composer openDatabaseWithFlags: SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_URI];

	if (![composer attachReadOnlyDatabaseAtURL: left.result.rowDatabaseURL asName: @"att0" error: error] ||
		![composer attachReadOnlyDatabaseAtURL: right.result.rowDatabaseURL asName: @"att1" error: error]) {
		[composer closeDatabaseConnectionIfOpen];
		[[NSFileManager defaultManager] removeItemAtURL: scratchURL error: NULL];
		return NO;
	}

	NSError *executeError = nil;
	BOOL success = [composer executeSQL: sql
							  fieldKeys: fieldKeys
						   onConnection: nil
						intoResultTable: table
						 transactionSet: NO
						 returnsResults: YES
						 binaryBindings: nil
							  withError: &executeError];

	[composer closeDatabaseConnectionIfOpen];
	[[NSFileManager defaultManager] removeItemAtURL: scratchURL error: NULL];

	if (!success) {
		if (error != NULL) {
			*error = executeError ?: [NSError errorWithDomain: MADComposerErrorDomain code: 3 userInfo: @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"The composition join failed.", @"Composition join failure.") }];
		}
		return NO;
	}
	return YES;
}

+ (MADComposerInput *)inputContainingKey:(NSString *)key inLeft:(MADComposerInput *)left right:(MADComposerInput *)right {
	if ([left.result.dataTable columnKeyForColumnName: key] != nil) return left;
	if ([right.result.dataTable columnKeyForColumnName: key] != nil) return right;
	return nil;
}

+ (MADDataType)dataTypeForKey:(NSString *)key inInput:(MADComposerInput *)input {
	NSString *physical = [input.result.dataTable columnKeyForColumnName: key];
	MADDataColumn *column = physical != nil ? input.result.dataTable.columns[physical] : nil;
	return column != nil ? column.type : MADDataTypeUnknown;
}

+ (nullable NSString *)physicalColumnForKey:(NSString *)key
									inInput:(MADComposerInput *)input
									  error:(NSError * _Nullable __autoreleasing *)error {
	if (key.length == 0) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: MADComposerErrorDomain code: 4 userInfo: @{
				NSLocalizedDescriptionKey: NSLocalizedString(@"A composition field or join key is empty.", @"Empty composition key.") }];
		}
		return nil;
	}
	NSString *physical = [input.result.dataTable columnKeyForColumnName: key];
	if (physical == nil && error != NULL) {
		*error = [NSError errorWithDomain: MADComposerErrorDomain code: 5 userInfo: @{
			NSLocalizedDescriptionKey: [NSString stringWithFormat:
				NSLocalizedString(@"The field %@ is not present in input %@.", @"Missing composition field."), key, input.alias] }];
	}
	return physical;
}

@end
