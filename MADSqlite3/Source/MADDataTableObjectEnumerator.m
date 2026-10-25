//
//  MADDataTableObjectEnumerator.m
//  MAD
//
//  Created by Michael Thomason on 4/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataTableObjectEnumerator.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSKeyValueCoding.h>
#import <Foundation/NSValue.h>

#import <MADFoundation/MADDataColumn.h>

#import <MADAPI/MADQuery.h>

#import <MADSqlite3/sqlite3.h>
#import <MADSqlite3/MADDatabaseSqlite3.h>

#import <MADFoundation/madlog.h>

@interface MADDataTableObjectEnumerator ()

	@property (nonatomic, strong) NSDictionary <NSString *, MADDataColumn *> *columns;
	@property (nonatomic, strong) NSArray <NSString *> *columnKeys;

	@property (nonatomic, strong) MADDatabaseSqlite3 *databaseForQuery;
	@property (nonatomic, strong) NSMutableArray *fastEnumerationObjects;

@end

@implementation MADDataTableObjectEnumerator {
	sqlite3_stmt *_statement;
	BOOL _empty;
}

- (void)dealloc {
	sqlite3_finalize(_statement);
	[_fastEnumerationObjects removeAllObjects];
	_databaseForQuery = nil;
}

- (instancetype)initWithDatabaseConnection:(MADDatabaseConnection *)databaseConnection
								   columns:(NSDictionary <NSString *, MADDataColumn *> *)columns
								columnKeys:(NSArray <NSString *> *)columnKeys
									 query:(MADQuery *)query {
	if (self = [super init]) {

		NSMutableArray *fastEnumerationObjects = [[NSMutableArray alloc] init];
		self.fastEnumerationObjects = fastEnumerationObjects;

		MADDatabaseSqlite3 *database = [[MADDatabaseSqlite3 alloc] init];
		[database setDatabaseConnection:databaseConnection];
		[database openDatabase];
		self.databaseForQuery = database;

		_empty = columnKeys.count == 0;
		if (!_empty) {
			self->_statement = NULL;
			NSString *sql = [query getSql:nil];
			char *queryString = sqlite3_mprintf("%s", sql.UTF8String);
			sqlite3_prepare_v2(self.databaseForQuery->_database, queryString, -1, &_statement, NULL);
			sqlite3_free(queryString);
		}
		
		NSArray <NSString *> *retainedColumKeys = [[NSArray alloc] initWithArray:columnKeys];
		self.columnKeys = retainedColumKeys;
		
		NSDictionary *retainedColumns = [[NSDictionary alloc] initWithDictionary:columns];
		self.columns = retainedColumns;
	}
	return self;
}

- (NSArray *)allObjects {
	NSMutableArray *results = [[NSMutableArray alloc] init];
	if (!_empty) {
		while (sqlite3_step(_statement) == SQLITE_ROW) {
			[results addObject:self.currentObject];
		}
	}
	return results;
}

- (id)nextObject {
	BOOL success;
	if (!_empty) {
		success = sqlite3_step(_statement) == SQLITE_ROW;
	} else {
		success = NO;
	}
	return success ? [self currentObject] : nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained *)stackbuf
									count:(NSUInteger)len {
	
	NSUInteger i = 0;
	int stepResult;
	
	if(state->state == 0) {
		state->state = 1;
		state->mutationsPtr = &state->extra[0];
		sqlite3_reset(_statement);
	}
	
	if (state->state != 2) {
		state->itemsPtr = stackbuf;
		
		[self.fastEnumerationObjects removeAllObjects];
		
		for (i = 0; i<len; i++) {
			@autoreleasepool {
				stepResult = sqlite3_step(_statement);
				if (stepResult == SQLITE_ROW) {
					id co = [self currentObject];
					if (co) {
						stackbuf[i] = co;
						[self.fastEnumerationObjects addObject:co];
					} else {
						stackbuf[i] = nil;
					}
					co = nil;
				} else if (stepResult == SQLITE_DONE) {
					sqlite3_reset(_statement);
					stackbuf[i] = nil;
					state->state = 2;
					break;
				} else {
					sqlite3_reset(_statement);
					stackbuf[i] = nil;
					state->state = 2;
					break;
				}
			}
		}
	}
	return i;
}

- (__kindof NSObject <NSCopying, NSSecureCoding> *)currentObject {
	//os_log_debug(GetSqlite3Log(), "Getting current object");
	NSMutableDictionary *currentObject = [[NSMutableDictionary alloc] initWithCapacity:_columns.count];
	int columnCounter = 0;
	for (NSString *key in _columnKeys) {
		@autoreleasepool {
			__kindof NSObject <NSCopying, NSSecureCoding> *columnValue = [MADDatabaseSqlite3 databaseResultValue:_statement
																									columnNumber:columnCounter];
			MADDataColumn *dataColumn = [_columns objectForKey:key];
			[currentObject setValue:columnValue forKey:dataColumn.identifier];
			columnCounter++;
		}
	}
	if (sqlite3_column_count(_statement) >= columnCounter) {
		NSNumber *rowid = [[NSNumber alloc] initWithInt: sqlite3_column_int(_statement, columnCounter)];
		[currentObject setValue:rowid forKey:MADIdentifierROWID];
		rowid = nil;
	}
	//os_log_debug(GetSqlite3Log(), "Current object: %@", currentObject);
	return currentObject;
}

@end

